import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DenunciaService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _denuncias = [];
  List<Map<String, dynamic>> get denuncias => _denuncias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- CORREÇÃO: LÓGICA OFFLINE-FIRST ---
  Future<void> fetchDenuncias({String? uid}) async {
    _setLoading(true);

    // 1. Carrega dados locais (cache e pendentes) PRIMEIRO para a UI responder rápido.
    final cacheBox = Hive.box('denuncias_cache');
    final pendingBox = Hive.box('pending_denuncias');

    List<Map<String, dynamic>> cachedItems = cacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
    List<Map<String, dynamic>> pendingItems = pendingBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();

    // Filtra por UID se necessário (para a tela do agente)
    if (uid != null) {
      cachedItems = cachedItems.where((d) => d['uid'] == uid).toList();
      pendingItems = pendingItems.where((d) => d['uid'] == uid).toList();
    }

    _updateDenunciasFromLocal(cachedItems, pendingItems);
    _setLoading(false); // A UI já tem dados para mostrar, então paramos o loading principal.

    // 2. Tenta buscar dados frescos do servidor em segundo plano.
    try {
      var query = _supabase.from('denuncias').select();
      if (uid != null) {
        query = query.eq('uid', uid);
      }
      
      final res = await query.order('created_at', ascending: false);
      final onlineData = List<Map<String, dynamic>>.from(res);

      // 3. Atualiza o cache com os novos dados.
      await cacheBox.clear();
      for (var item in onlineData) {
        await cacheBox.put(item['id'], item);
      }

      // 4. Atualiza a UI com os dados mais recentes.
      _updateDenunciasFromLocal(onlineData, pendingItems);

    } catch (e) {
      if (kDebugMode) {
        print('Falha ao buscar denúncias do Supabase. Usando dados do cache. Erro: $e');
      }
      // Se a busca online falhar, não faz nada, pois os dados do cache já foram carregados.
    }
  }

  // Função auxiliar para unificar e ordenar os dados locais e da rede.
  void _updateDenunciasFromLocal(List<Map<String, dynamic>> online, List<Map<String, dynamic>> pending) {
    final Map<dynamic, Map<String, dynamic>> map = {};

    // Adiciona os itens da rede (ou do cache) primeiro.
    for (var o in online) {
      map[o['id']] = {...o, 'is_pending': false};
    }

    // Adiciona/sobrescreve com os itens pendentes, que são a "fonte da verdade" local.
    for (var p in pending) {
      final key = p['local_id'] ?? p['id'];
      map[key] = {...(map[key] ?? {}), ...p, 'is_pending': true};
    }

    final list = map.values.toList();
    _sortDenuncias(list); // Ordena a lista final
    _denuncias = list;
    notifyListeners();
  }

  // Função auxiliar para ordenar a lista de denúncias.
  void _sortDenuncias(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final dateA = a['created_at'];
      final dateB = b['created_at'];
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      try {
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        return 0;
      }
    });
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void forceRefresh({String? uid}) {
    fetchDenuncias(uid: uid);
  }
}
