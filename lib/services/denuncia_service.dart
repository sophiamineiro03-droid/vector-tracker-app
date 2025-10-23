import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vector_tracker_app/services/hive_sync_service.dart';

class DenunciaService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  late final HiveSyncService _syncService;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setSyncService(HiveSyncService syncService) {
    _syncService = syncService;
  }

  void updateItemInList(Map<String, dynamic> updatedItem) {
    final updatedItemKey = updatedItem['local_id'] ?? updatedItem['id'];
    final originalDenunciaId = updatedItem['denuncia_id_origem'];

    if (originalDenunciaId != null) {
      _items.removeWhere((item) => (item['local_id'] ?? item['id']) == originalDenunciaId);
    }

    final index = _items.indexWhere((item) => (item['local_id'] ?? item['id']) == updatedItemKey);

    if (index != -1) {
      _items[index] = updatedItem;
    } else {
      _items.insert(0, updatedItem); 
    }
    
    _sortItems(_items);
    notifyListeners();
  }

  List<Map<String, dynamic>> _safeCastToList(List<dynamic> data) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // MODIFICADO: Removido o filtro por UID
  Future<void> fetchItems({bool showLoading = true}) async {
    if (showLoading) _setLoading(true);

    final denunciasCacheBox = Hive.box('denuncias_cache');
    final ocorrenciasCacheBox = Hive.box('ocorrencias_cache');
    
    List<Map<String, dynamic>> onlineDenuncias = [];
    List<Map<String, dynamic>> onlineOcorrencias = [];

    try {
      final results = await Future.wait([
        _supabase.from('denuncias').select(),
        _supabase.from('ocorrencias').select()
      ]);

      onlineDenuncias = _safeCastToList(results[0] as List);
      onlineOcorrencias = _safeCastToList(results[1] as List);

      await denunciasCacheBox.clear();
      for (var item in onlineDenuncias) { await denunciasCacheBox.put(item['id'], item); }
      
      await ocorrenciasCacheBox.clear();
      for (var item in onlineOcorrencias) { await ocorrenciasCacheBox.put(item['id'], item); }

    } catch (e) {
      if (kDebugMode) {
        print('Falha ao buscar dados do Supabase. Usando dados do cache. Erro: $e');
      }
      onlineDenuncias = denunciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
      onlineOcorrencias = ocorrenciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
    }

    final pendingDenunciasBox = Hive.box('pending_denuncias');
    final pendingOcorrenciasBox = Hive.box('pending_ocorrencias');
    
    List<Map<String, dynamic>> pendingDenuncias = pendingDenunciasBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
    List<Map<String, dynamic>> pendingOcorrencias = pendingOcorrenciasBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();

    _updateAndNotify(onlineDenuncias, pendingDenuncias, onlineOcorrencias, pendingOcorrencias);
    if (showLoading) _setLoading(false);
  }

  void _updateAndNotify(
    List<Map<String, dynamic>> denuncias, List<Map<String, dynamic>> pendingDenuncias,
    List<Map<String, dynamic>> ocorrencias, List<Map<String, dynamic>> pendingOcorrencias
  ) {
    final Map<dynamic, Map<String, dynamic>> finalItems = {};
    
    final Map<dynamic, Map<String, dynamic>> allDenuncias = {};
    for (var den in denuncias) {
      allDenuncias[den['id']] = {...den, 'is_ocorrencia': false, 'is_pending': false };
    }
    for (var pDen in pendingDenuncias) {
      final key = pDen['id'] ?? pDen['local_id'];
      allDenuncias[key] = {...(allDenuncias[key] ?? {}), ...pDen, 'is_ocorrencia': false, 'is_pending': true };
    }

    final Map<dynamic, Map<String, dynamic>> allOcorrencias = {};
    for (var oco in ocorrencias) {
      allOcorrencias[oco['id']] = {...oco, 'is_ocorrencia': true, 'is_pending': false, 'status': 'realizada' };
    }
    for (var pOco in pendingOcorrencias) {
      final key = pOco['id'] ?? pOco['local_id'];
      allOcorrencias[key] = {...(allOcorrencias[key] ?? {}), ...pOco, 'is_ocorrencia': true, 'is_pending': true, 'status': 'pending' };
    }

    final Set<dynamic> convertedDenunciaIds = {};
    allOcorrencias.forEach((key, oco) {
      final denunciaIdOrigem = oco['denuncia_id_origem'];
      if (denunciaIdOrigem != null) {
        convertedDenunciaIds.add(denunciaIdOrigem);
        if (oco['original_denuncia_context'] == null) {
          final originalDenuncia = allDenuncias[denunciaIdOrigem];
          if (originalDenuncia != null) {
            oco['original_denuncia_context'] = {
              'image_url': originalDenuncia['image_url'],
              'descricao': originalDenuncia['descricao'],
              'rua': originalDenuncia['rua'],
              'numero': originalDenuncia['numero'],
              'bairro': originalDenuncia['bairro'],
            };
          }
        }
      }
      finalItems[key] = oco;
    });

    allDenuncias.forEach((key, den) {
      if (!convertedDenunciaIds.contains(key)) {
        finalItems[key] = den;
      }
    });

    final list = finalItems.values.toList();
    _sortItems(list);
    _items = list;
    notifyListeners();
  }

  void _sortItems(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final dateAStr = a['is_ocorrencia'] == true ? a['data_atividade'] : a['created_at'];
      final dateBStr = b['is_ocorrencia'] == true ? b['data_atividade'] : b['created_at'];

      if (dateAStr == null) return 1;
      if (dateBStr == null) return -1;
      
      try {
        final dateA = DateTime.tryParse(dateAStr) ?? DateFormat('dd/MM/yyyy').parse(dateAStr);
        final dateB = DateTime.tryParse(dateBStr) ?? DateFormat('dd/MM/yyyy').parse(dateBStr);
        return dateB.compareTo(dateA);
      } catch (e) {
        if (kDebugMode) print("Erro ao ordenar datas: $e. Strings de data: '$dateAStr', '$dateBStr'");
        return 0;
      }
    });
  }

  // MODIFICADO: Removido o UID da criação de nova denúncia
  Future<Map<String, dynamic>> saveDenuncia({ required Map<String, dynamic> dataFromForm, Map<String, dynamic>? originalItem }) async {
    final pendingDenunciasBox = Hive.box('pending_denuncias');
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);
    final isEditing = originalItem != null;

    Map<String, dynamic> denunciaPayload;
    dynamic denunciaKey;

    if (isEditing) {
      denunciaKey = originalItem['local_id'] ?? originalItem['id'];
      denunciaPayload = {
        ...originalItem,
        ...dataFromForm,
        'local_id': denunciaKey,
        'is_pending': !isOnline, 
      };
    } else {
      denunciaKey = _uuid.v4();
      denunciaPayload = {
        ...dataFromForm,
        'local_id': denunciaKey,
        'is_ocorrencia': false,
        'is_pending': !isOnline,
        'status': 'pendente',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    await pendingDenunciasBox.put(denunciaKey, denunciaPayload);
    
    if (isOnline) {
      _syncService.syncAll();
    }

    updateItemInList(denunciaPayload);
    return denunciaPayload;
  }

  Future<Map<String, dynamic>> saveOcorrencia({
    required Map<String, dynamic> dataFromForm,
    required Map<String, dynamic> originalItem, 
  }) async {
    final pendingOcorrenciasBox = Hive.box('pending_ocorrencias');
    final pendingDenunciasBox = Hive.box('pending_denuncias');
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);

    final isNewRecord = originalItem.isEmpty;
    final isConvertingDenuncia = originalItem.isNotEmpty && originalItem['is_ocorrencia'] == false;

    Map<String, dynamic> ocorrenciaPayload;
    dynamic ocorrenciaKey;

    if (isNewRecord || isConvertingDenuncia) {
      ocorrenciaKey = _uuid.v4();
      ocorrenciaPayload = {
        ...dataFromForm,
        'local_id': ocorrenciaKey,
        'created_at': DateTime.now().toIso8601String(),
        'uid': _supabase.auth.currentUser?.id,
        'is_ocorrencia': true,
        'is_pending': !isOnline,
      };
      if (isConvertingDenuncia) {
        final denunciaOrigemId = originalItem['id'] ?? originalItem['local_id'];
        ocorrenciaPayload['denuncia_id_origem'] = denunciaOrigemId;
        ocorrenciaPayload['original_denuncia_context'] = {
          'image_url': originalItem['image_url'],
          'descricao': originalItem['descricao'],
          'rua': originalItem['rua'],
          'numero': originalItem['numero'],
          'bairro': originalItem['bairro'],
          'created_at': originalItem['created_at'],
        };
      }
    } else { // isEditingOcorrencia
      ocorrenciaKey = originalItem['local_id'] ?? originalItem['id'];
      ocorrenciaPayload = {
        ...originalItem,
        ...dataFromForm,
        'local_id': ocorrenciaKey,
        'is_pending': !isOnline, 
      };
    }
    
    await pendingOcorrenciasBox.put(ocorrenciaKey, ocorrenciaPayload);

    if (isConvertingDenuncia) {
      final denunciaKey = originalItem['id'] ?? originalItem['local_id'];
      if (denunciaKey != null) {
        final denunciaUpdatePayload = {
          ...originalItem,
          'status': 'realizada',
          'is_pending': !isOnline,
        };
        await pendingDenunciasBox.put(denunciaKey, denunciaUpdatePayload);
      }
    }

    if (isOnline) {
        _syncService.syncAll();
    }

    updateItemInList(ocorrenciaPayload); // Atualiza a ocorrência na UI
    return ocorrenciaPayload;
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void forceRefresh() {
    fetchItems(showLoading: true);
  }
}
