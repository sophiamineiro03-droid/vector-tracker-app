import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// MODO DE SIMULAÇÃO: Este serviço agora funciona inteiramente localmente.

class DenunciaService with ChangeNotifier {
  final _supabase = Supabase.instance.client; // Necessário para o ID de usuário no login
  final _uuid = const Uuid();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  bool _isLoading = true; // Inicia como verdadeiro para a carga inicial
  bool get isLoading => _isLoading;

  DenunciaService() {
    // Carrega os itens do Hive assim que o serviço é instanciado.
    fetchItems();
  }

  void updateItemInList(Map<String, dynamic> updatedItem) {
    final key = updatedItem['id'];
    
    final originalDenunciaId = updatedItem['denuncia_id_origem'];
    if (originalDenunciaId != null) {
      _items.removeWhere((item) => item['id'] == originalDenunciaId);
    }

    final index = _items.indexWhere((item) => item['id'] == key);

    if (index != -1) {
      _items[index] = updatedItem;
    } else {
      _items.insert(0, updatedItem);
    }

    _sortItems(_items);
    notifyListeners();
  }

  Future<void> fetchItems({bool showLoading = false}) async {
    if (showLoading) _setLoading(true);

    final denunciasCacheBox = Hive.box('denuncias_cache');
    final ocorrenciasCacheBox = Hive.box('ocorrencias_cache');

    List<Map<String, dynamic>> denuncias = denunciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
    List<Map<String, dynamic>> ocorrencias = ocorrenciasCacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();

    _updateAndNotify(denuncias, ocorrencias);
    
    if (showLoading) _setLoading(false);
  }

  void _updateAndNotify(List<Map<String, dynamic>> denuncias, List<Map<String, dynamic>> ocorrencias) {
    final Map<dynamic, Map<String, dynamic>> finalItems = {};
    final Map<dynamic, Map<String, dynamic>> allDenuncias = {};

    for (var den in denuncias) {
      allDenuncias[den['id']] = {...den, 'is_ocorrencia': false, 'is_pending': false};
    }

    for (var oco in ocorrencias) {
      finalItems[oco['id']] = {...oco, 'is_ocorrencia': true, 'is_pending': false, 'status': 'realizada'};
      final denunciaIdOrigem = oco['denuncia_id_origem'];
      if (denunciaIdOrigem != null) {
        allDenuncias.remove(denunciaIdOrigem);
      }
    }

    finalItems.addAll(allDenuncias);

    final list = finalItems.values.toList();
    _sortItems(list);
    _items = list;
    
    if (_isLoading) _setLoading(false);

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
        return 0;
      }
    });
  }

  Future<Map<String, dynamic>> saveDenuncia({required Map<String, dynamic> dataFromForm, Map<String, dynamic>? originalItem}) async {
    final denunciasCacheBox = Hive.box('denuncias_cache');
    final isEditing = originalItem != null && originalItem.isNotEmpty;

    Map<String, dynamic> denunciaPayload;
    dynamic denunciaKey;

    if (isEditing) {
      denunciaKey = originalItem!['id'];
      denunciaPayload = {...originalItem, ...dataFromForm, 'is_pending': false};
    } else {
      denunciaKey = _uuid.v4();
      denunciaPayload = {
        ...dataFromForm,
        'id': denunciaKey,
        'is_ocorrencia': false,
        'is_pending': false,
        'status': 'pendente',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    await denunciasCacheBox.put(denunciaKey, denunciaPayload);
    updateItemInList(denunciaPayload);
    return denunciaPayload;
  }

  Future<Map<String, dynamic>> saveOcorrencia({required Map<String, dynamic> dataFromForm, required Map<String, dynamic> originalItem}) async {
    final ocorrenciasCacheBox = Hive.box('ocorrencias_cache');
    final denunciasCacheBox = Hive.box('denuncias_cache');
    final isNewOcorrencia = originalItem.isEmpty;
    final isFromDenuncia = originalItem.isNotEmpty && originalItem['is_ocorrencia'] == false;

    Map<String, dynamic> ocorrenciaPayload;
    dynamic ocorrenciaKey;

    if (isNewOcorrencia || isFromDenuncia) {
      ocorrenciaKey = _uuid.v4(); // CORRIGIDO
      ocorrenciaPayload = {
        ...dataFromForm,
        'id': ocorrenciaKey,
        'is_ocorrencia': true,
        'is_pending': false,
        'created_at': DateTime.now().toIso8601String(),
        'uid': _supabase.auth.currentUser?.id,
      };

      if (isFromDenuncia) {
        final denunciaId = originalItem['id'];
        ocorrenciaPayload['denuncia_id_origem'] = denunciaId;
        ocorrenciaPayload['original_denuncia_context'] = {
          'image_url': originalItem['image_url'],
          'image_path': originalItem['image_path'],
          'descricao': originalItem['descricao'],
          'rua': originalItem['rua'],
          'numero': originalItem['numero'],
          'bairro': originalItem['bairro'],
          'created_at': originalItem['created_at'],
        };
        final denunciaUpdate = {...originalItem, 'status': 'realizada'};
        await denunciasCacheBox.put(denunciaId, denunciaUpdate);
      }
    } else { // Editando uma ocorrência existente
      ocorrenciaKey = originalItem['id'];
      ocorrenciaPayload = {...originalItem, ...dataFromForm, 'is_pending': false};
    }

    await ocorrenciasCacheBox.put(ocorrenciaKey, ocorrenciaPayload);
    updateItemInList(ocorrenciaPayload);
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
