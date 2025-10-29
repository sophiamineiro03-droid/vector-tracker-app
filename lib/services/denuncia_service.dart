import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vector_tracker_app/services/hive_sync_service.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/core/exceptions.dart';

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
    AppLogger.info('Sync service configurado no DenunciaService');
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

  Future<void> fetchItems({bool showLoading = true}) async {
    try {
      if (showLoading) _setLoading(true);
      AppLogger.info('Buscando denúncias e ocorrências');

      final denunciasCacheBox = Hive.box('denuncias_cache');
      final ocorrenciasCacheBox = Hive.box('ocorrencias_cache');
      
      List<Map<String, dynamic>> onlineDenuncias = [];
      List<Map<String, dynamic>> onlineOcorrencias = [];

      try {
        AppLogger.database('Executando queries no Supabase');
        final results = await Future.wait([
          _supabase.from('denuncias').select(),
          _supabase.from('ocorrencias').select()
        ]);

        onlineDenuncias = _safeCastToList(results[0] as List);
        onlineOcorrencias = _safeCastToList(results[1] as List);

        AppLogger.database('✓ ${onlineDenuncias.length} denúncias e ${onlineOcorrencias.length} ocorrências obtidas');

        await denunciasCacheBox.clear();
        for (var item in onlineDenuncias) { 
          await denunciasCacheBox.put(item['id'], item); 
        }
        
        await ocorrenciasCacheBox.clear();
        for (var item in onlineOcorrencias) { 
          await ocorrenciasCacheBox.put(item['id'], item); 
        }

        AppLogger.database('Cache local atualizado');

      } on PostgrestException catch (e, stackTrace) {
        AppLogger.error('Erro ao buscar dados do Supabase', e, stackTrace);
        AppLogger.warning('Usando dados do cache local devido a erro de rede');
        onlineDenuncias = denunciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
        onlineOcorrencias = ocorrenciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
      } catch (e, stackTrace) {
        AppLogger.error('Erro inesperado ao buscar dados', e, stackTrace);
        onlineDenuncias = denunciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
        onlineOcorrencias = ocorrenciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
      }

      final pendingDenunciasBox = Hive.box('pending_denuncias');
      final pendingOcorrenciasBox = Hive.box('pending_ocorrencias');
      
      List<Map<String, dynamic>> pendingDenuncias = pendingDenunciasBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
      List<Map<String, dynamic>> pendingOcorrencias = pendingOcorrenciasBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();

      AppLogger.info('Processando ${pendingDenuncias.length} denúncias e ${pendingOcorrencias.length} ocorrências pendentes');

      _updateAndNotify(onlineDenuncias, pendingDenuncias, onlineOcorrencias, pendingOcorrencias);
      
      AppLogger.info('✓ Items atualizados com sucesso');
      
    } catch (e, stackTrace) {
      AppLogger.error('Erro crítico ao buscar items', e, stackTrace);
    } finally {
      if (showLoading) _setLoading(false);
    }
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
              'created_at': originalDenuncia['created_at'],
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
        AppLogger.warning("Erro ao ordenar datas: $e. Strings: '$dateAStr', '$dateBStr'");
        return 0;
      }
    });
  }

  Future<Map<String, dynamic>> saveDenuncia({ 
    required Map<String, dynamic> dataFromForm, 
    Map<String, dynamic>? originalItem 
  }) async {
    try {
      AppLogger.info('Salvando denúncia ${originalItem != null ? "(editando)" : "(nova)"}');
      
      final pendingDenunciasBox = Hive.box('pending_denuncias');
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || 
                      connectivityResult.contains(ConnectivityResult.wifi);
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
        AppLogger.info('Editando denúncia existente: $denunciaKey');
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
        AppLogger.info('Criando nova denúncia: $denunciaKey');
      }

      await pendingDenunciasBox.put(denunciaKey, denunciaPayload);
      
      if (isOnline) {
        AppLogger.sync('Conectado online, disparando sincronização');
        _syncService.syncAll();
      } else {
        AppLogger.warning('Offline, denúncia será sincronizada depois');
      }

      updateItemInList(denunciaPayload);
      AppLogger.info('✓ Denúncia salva com sucesso');
      
      return denunciaPayload;
      
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar denúncia', e, stackTrace);
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void forceRefresh() {
    AppLogger.info('Force refresh solicitado');
    fetchItems(showLoading: true);
  }
}
