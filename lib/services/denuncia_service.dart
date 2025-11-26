import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/localidade.dart';
import 'package:vector_tracker_app/models/municipio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DenunciaService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Box _denunciasCache = Hive.box('denuncias_cache');
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  List<Municipio> _municipios = [];
  List<Municipio> get municipios => _municipios;

  List<Localidade> _localidades = [];
  List<Localidade> get localidades => _localidades;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isMunicipiosLoading = false;
  bool get isMunicipiosLoading => _isMunicipiosLoading;

  bool _isLocalidadesLoading = false;
  bool get isLocalidadesLoading => _isLocalidadesLoading;

  bool _isSyncing = false;

  // GUARDA O FILTRO ATUAL PARA REUTILIZAR NAS ATUALIZAÇÕES AUTOMÁTICAS
  List<String>? _currentLocalidadeIdsFilter;

  DenunciaService() {
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
          final isOnline = connectivityResult == ConnectivityResult.mobile ||
              connectivityResult == ConnectivityResult.wifi;
          if (isOnline) {
            AppLogger.info('Conexão detectada no DenunciaService, sincronizando...');
            syncPendingDenuncias();
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> syncPendingDenuncias() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final pending = _pendingDenunciasBox.values.toList();
    if (pending.isEmpty) {
      _isSyncing = false;
      return;
    }

    AppLogger.sync('Sincronizando ${pending.length} denúncias pendentes.');

    for (var denunciaData in pending) {
      try {
        final denunciaMap = Map<String, dynamic>.from(denunciaData as Map);
        final id = denunciaMap['id'];

        final localPhotoPath = denunciaMap['foto_url'];

        if (localPhotoPath != null && !localPhotoPath.startsWith('http')) {
          final file = File(localPhotoPath);
          if (await file.exists()) {
            final fileName = localPhotoPath.split('/').last;
            final filePath = '$id/$fileName';

            await _supabase.storage.from('imagens_denuncias').upload(
              filePath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

            final publicUrl = _supabase.storage.from('imagens_denuncias').getPublicUrl(filePath);
            denunciaMap['foto_url'] = publicUrl;
            AppLogger.sync('Upload da foto $filePath realizado com sucesso.');
          }
        }

        await _supabase.from('denuncias').upsert(denunciaMap);
        await _pendingDenunciasBox.delete(id);
        AppLogger.sync('Denúncia $id sincronizada com sucesso.');

      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar denúncia', e, s);
      }
    }

    _isSyncing = false;
    await fetchItems();
  }

  Future<void> fetchItems({List<String>? localidadeIds}) async {
    _isLoading = true;
    notifyListeners();

    if (localidadeIds != null) {
      _currentLocalidadeIdsFilter = localidadeIds;
    }
    final filterToUse = _currentLocalidadeIdsFilter;

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
      notifyListeners();

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      if (isOnline) {
        var query = _supabase
            .from('denuncias')
            .select('*, localidades!inner(nome, municipios!inner(nome))');

        if (filterToUse != null && filterToUse.isNotEmpty) {
          query = query.inFilter('localidade_id', filterToUse);
        }

        final response = await query;
        final remoteItems = List<Map<String, dynamic>>.from(response);

        await _denunciasCache.clear();
        for (var item in remoteItems) {
          _denunciasCache.put(item['id'], item);
        }

        // CORREÇÃO: Await para garantir o download antes de liberar a UI ou ficar offline
        await _downloadImages(remoteItems);

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

  Future<void> _downloadImages(List<Map<String, dynamic>> items) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/images_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      for (var item in items) {
        final url = item['foto_url'] as String?;
        if (url != null && url.startsWith('http')) {
           try {
             final uri = Uri.parse(url);
             final filename = uri.pathSegments.last;
             final file = File('${cacheDir.path}/$filename');
             
             if (!await file.exists()) {
                final response = await http.get(uri);
                if (response.statusCode == 200) {
                  await file.writeAsBytes(response.bodyBytes);
                  AppLogger.info('Imagem baixada para cache: $filename');
                }
             }
           } catch (e) {
             // Ignore individual download errors
           }
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao baixar imagens para cache', e);
    }
  }

  Future<void> saveDenuncia(Denuncia denuncia) async {
    final data = denuncia.toMap();
    data['status'] = 'pendente_envio';

    await _pendingDenunciasBox.put(denuncia.id, data);
    await fetchItems();
    syncPendingDenuncias();
  }
  
  Future<void> updateDenunciaStatus(String denunciaId, String novoStatus) async {
    try {
      await _supabase
          .from('denuncias')
          .update({'status': novoStatus})
          .eq('id', denunciaId);

      final cachedDenuncia = _denunciasCache.get(denunciaId);
      if (cachedDenuncia != null) {
        final denunciaMap = Map<String, dynamic>.from(cachedDenuncia as Map);
        denunciaMap['status'] = novoStatus;
        await _denunciasCache.put(denunciaId, denunciaMap);
      }

      await fetchItems();

      AppLogger.info('Status da denúncia $denunciaId atualizado para $novoStatus');
    } catch (e, s) {
      AppLogger.error('Erro ao atualizar status da denúncia $denunciaId', e, s);
    }
  }

  Future<void> fetchMunicipios() async {
    _isMunicipiosLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('municipios').select('id, nome');
      _municipios =
          (response as List).map((map) => Municipio.fromMap(map)).toList();
    } catch (e, s) {
      AppLogger.error('Erro ao buscar municípios', e, s);
    } finally {
      _isMunicipiosLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLocalidades(String municipioId) async {
    _isLocalidadesLoading = true;
    _localidades = [];
    notifyListeners();

    try {
      final response = await _supabase
          .from('localidades')
          .select('id, nome')
          .eq('municipio_id', municipioId);
      _localidades =
          (response as List).map((map) => Localidade.fromMap(map)).toList();
    } catch (e, s) {
      AppLogger.error(
          'Erro ao buscar localidades para o município $municipioId', e, s);
    } finally {
      _isLocalidadesLoading = false;
      notifyListeners();
    }
  }

  void clearLocalidades() {
    _localidades = [];
    notifyListeners();
  }

  void updateItemInList(Map<String, dynamic> updatedItem) {
    final index = _items.indexWhere((item) => item['id'] == updatedItem['id']);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }
}
