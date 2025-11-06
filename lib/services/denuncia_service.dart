import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/hive_sync_service.dart';

class DenunciaService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Box _denunciasCache = Hive.box('denuncias_cache');
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');
  final Box _localidadesCache = Hive.box('localidades_cache');

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  List<String> _localidades = [];
  List<String> get localidades => _localidades;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLocalidadesLoading = false;
  bool get isLocalidadesLoading => _isLocalidadesLoading;

  late HiveSyncService _syncService;

  DenunciaService() {
    _listenToConnectivity();
  }

  void setSyncService(HiveSyncService service) {
    _syncService = service;
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult connectivityResult) {
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi;
      if (isOnline) {
        AppLogger.info('Conexão detectada no DenunciaService, sincronizando...');
        _syncService.syncAll();
      }
    });
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> allItems = [];
      final cached = _denunciasCache.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      allItems.addAll(cached);
      final pending = _pendingDenunciasBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      allItems.addAll(pending);

      final uniqueItems = <String, Map<String, dynamic>>{};
      for (var item in allItems) {
        uniqueItems[item['id']] = item;
      }
      _items = uniqueItems.values.toList();

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile || 
                      connectivityResult == ConnectivityResult.wifi;

      if (isOnline) {
        final response = await _supabase.from('denuncias').select();
        final remoteItems = List<Map<String, dynamic>>.from(response);
        
        for (var item in remoteItems) {
          _denunciasCache.put(item['id'], item);
        }

        final combined = _denunciasCache.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final pendingAgain = _pendingDenunciasBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final finalUniqueItems = <String, Map<String, dynamic>>{};
        for (var item in [...combined, ...pendingAgain]) {
           finalUniqueItems[item['id']] = item;
        }
        _items = finalUniqueItems.values.toList();
      }
    } catch (e, s) {
      AppLogger.error('Erro ao buscar denúncias', e, s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveDenuncia(Denuncia denuncia) async {
    final data = denuncia.toMap();
    data['is_pending'] = true;
    data['status'] = 'pendente_envio';

    await _pendingDenunciasBox.put(denuncia.id, data);
    fetchItems();
    _syncService.syncAll();
  }

  Future<void> fetchLocalidades() async {
    if (_isLocalidadesLoading) return;

    AppLogger.info('Buscando localidades...');
    _isLocalidadesLoading = true;
    notifyListeners();

    try {
      if (_localidadesCache.isNotEmpty) {
        _localidades = _localidadesCache.values.map((e) => (e as Map)['nome'] as String).toList();
      }

      final connectivityResult = await (Connectivity().checkConnectivity());
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi;

      if (isOnline) {
        final response = await _supabase.from('localidades').select('nome');
        final localidadesMap = List<Map<String, dynamic>>.from(response);
        
        await _localidadesCache.clear();
        final newLocalidades = <String>{};

        for (var loc in localidadesMap) {
          await _localidadesCache.put(loc['nome'], loc);
          newLocalidades.add(loc['nome'] as String);
        }
        _localidades = newLocalidades.toList();
      }
    } catch (e, s) {
      AppLogger.error('Erro ao buscar localidades', e, s);
    } finally {
      _isLocalidadesLoading = false;
      notifyListeners();
    }
  }
  
  void updateItemInList(Map<String, dynamic> updatedItem) {
     final index = _items.indexWhere((item) => item['id'] == updatedItem['id']);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }
}
