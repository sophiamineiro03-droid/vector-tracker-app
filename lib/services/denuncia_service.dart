import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Import necessário
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/localidade.dart';
import 'package:vector_tracker_app/models/municipio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DenunciaService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Boxes do Hive
  final Box _denunciasCache = Hive.box('denuncias_cache');
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');
  final Box _anonymousHistoryBox = Hive.box('anonymous_history');
  final Box _municipiosCacheBox = Hive.box('municipios_cache');
  final Box _pendingStatusUpdatesBox = Hive.box('pending_status_updates'); // Novo box

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Lista PRINCIPAL (Geral/Agente)
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  // NOVA LISTA (Minhas Denúncias - Cidadão)
  List<Map<String, dynamic>> _myItems = [];
  List<Map<String, dynamic>> get myItems => _myItems;

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

  List<String>? _currentLocalidadeIdsFilter;
  String? _currentMunicipioIdFilter;

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
            syncPendingStatusUpdates(); // Sincroniza descartes pendentes
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // --- MÉTODOS PARA CIDADÃO (MINHAS DENÚNCIAS) ---

  Future<void> fetchMyDenuncias() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // 1. Busca PENDENTES DE ENVIO (Locais) do usuário
        final pending = _pendingDenunciasBox.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((item) => item['user_id'] == user.id)
            .toList();

        // 2. Busca CONFIRMADAS (Servidor)
        List<Map<String, dynamic>> serverData = [];
        try {
            final response = await _supabase
                .from('denuncias')
                .select('*, localidades(nome), municipios(nome)')
                .eq('user_id', user.id)
                .order('created_at', ascending: false);
            
            serverData = List<Map<String, dynamic>>.from(response);
            
            // ATUALIZAÇÃO: Atualiza cache local com dados do servidor para uso offline futuro
            for (var item in serverData) {
               _denunciasCache.put(item['id'], item);
            }
            
        } catch (e) {
            // Se erro online, tenta pegar do cache geral filtrando pelo user (melhor que nada)
             final cached = _denunciasCache.values
                .map((e) => Map<String, dynamic>.from(e as Map))
                .where((item) => item['user_id'] == user.id)
                .toList();
             serverData = cached;
        }

        // Mescla: Pendentes primeiro, depois servidor
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        
        for (var item in serverData) uniqueMap[item['id']] = item;
        // Pendentes sobrescrevem servidor (são mais novas/estado local) ou adicionam
        for (var item in pending) uniqueMap[item['id']] = item;

        final merged = uniqueMap.values.toList();
        merged.sort((a, b) {
             final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
             final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
             return db.compareTo(da); // Decrescente
        });
        
        _myItems = merged;
      
      } else {
        // VISITANTE: Histórico Local
        final history = _anonymousHistoryBox.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        
        // Mescla com pendentes que podem não estar no history (embora saveDenuncia ponha nos dois)
        // Só pra garantir consistência
        final pendingAnon = _pendingDenunciasBox.values
             .map((e) => Map<String, dynamic>.from(e as Map))
             .where((item) => item['user_id'] == null)
             .toList();

        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var item in history) uniqueMap[item['id']] = item;
        for (var item in pendingAnon) uniqueMap[item['id']] = item; // Pendente (status pendente_envio) prevalece

        final merged = uniqueMap.values.toList();
        merged.sort((a, b) {
            final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
            final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
            return db.compareTo(da);
        });

        _myItems = merged;
      }
    } catch (e, s) {
      AppLogger.error('Erro ao buscar Minhas Denúncias', e, s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FIM MÉTODOS CIDADÃO ---

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

        // Upload da Imagem
        if (localPhotoPath != null && !localPhotoPath.startsWith('http')) {
          final file = File(localPhotoPath);
          if (await file.exists()) {
            try {
              final ext = localPhotoPath.split('.').last;
              final uniqueName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}.$ext';
              final filePath = '$id/$uniqueName';

              await _supabase.storage.from('imagens_denuncias').upload(
                filePath,
                file,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
              );

              final publicUrl = _supabase.storage.from('imagens_denuncias').getPublicUrl(filePath);
              denunciaMap['foto_url'] = publicUrl;
              AppLogger.sync('Upload da foto $filePath realizado com sucesso.');
              
              if (denunciaMap['user_id'] == null) {
                 await _updateAnonymousHistoryImage(id, publicUrl);
              }
            } catch (uploadError) {
              AppLogger.error('Falha no upload da imagem da denúncia $id', uploadError);
            }
          } else {
            AppLogger.warning('Imagem local não encontrada para denúncia $id: $localPhotoPath');
          }
        }
        
        denunciaMap['status'] = 'Pendente'; 

        await _supabase.from('denuncias').upsert(denunciaMap);
        
        if (denunciaMap['user_id'] != null) {
             await _denunciasCache.put(id, denunciaMap);
        } else {
             await _updateAnonymousHistoryStatus(id, 'Pendente');
        }

        await _pendingDenunciasBox.delete(id);
        AppLogger.sync('Denúncia $id sincronizada com sucesso.');

      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar denúncia (item pulado)', e, s);
      }
    }

    _isSyncing = false;
    
    await fetchItems(); 
    await fetchMyDenuncias();
  }

  // === NOVA FUNÇÃO: Sincroniza atualizações de status (Descartes) ===
  Future<void> syncPendingStatusUpdates() async {
    final updates = _pendingStatusUpdatesBox.values.toList();
    if (updates.isEmpty) return;

    AppLogger.sync('Sincronizando ${updates.length} atualizações de status pendentes.');

    for (var updateData in updates) {
      try {
        final map = Map<String, dynamic>.from(updateData as Map);
        final id = map['id'];
        final status = map['status'];

        await _supabase
          .from('denuncias')
          .update({'status': status})
          .eq('id', id);
        
        // Se sucesso, remove da fila
        await _pendingStatusUpdatesBox.delete(id);
        AppLogger.sync('Status da denúncia $id sincronizado para $status.');

      } catch (e) {
        AppLogger.error('Erro ao sincronizar status pendente', e);
      }
    }
  }

  Future<void> _updateAnonymousHistoryImage(String id, String newUrl) async {
    try {
      final data = _anonymousHistoryBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data as Map);
        map['foto_url'] = newUrl;
        await _anonymousHistoryBox.put(id, map);
      }
    } catch (e) {
      AppLogger.warning('Erro ao atualizar imagem no histórico anônimo', e);
    }
  }
  
  Future<void> _updateAnonymousHistoryStatus(String id, String newStatus) async {
    try {
      final data = _anonymousHistoryBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data as Map);
        map['status'] = newStatus;
        await _anonymousHistoryBox.put(id, map);
      }
    } catch (e) {
      AppLogger.warning('Erro ao atualizar status no histórico anônimo', e);
    }
  }

  Future<void> fetchItems({List<String>? localidadeIds, String? municipioId}) async {
    _isLoading = true;
    notifyListeners();

    if (localidadeIds != null) {
      _currentLocalidadeIdsFilter = localidadeIds;
    }
    if (municipioId != null) {
      _currentMunicipioIdFilter = municipioId;
    }
    
    final filterLocs = _currentLocalidadeIdsFilter;
    final filterMun = _currentMunicipioIdFilter;

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
      
      // Aplica atualizações de status pendentes na visualização em memória
      final statusUpdates = _pendingStatusUpdatesBox.values.toList();
      for (var update in statusUpdates) {
        final map = Map<String, dynamic>.from(update as Map);
        final id = map['id'];
        final status = map['status'];
        // Se o item estiver na lista, atualiza status visualmente
        if (uniqueItems.containsKey(id)) {
            uniqueItems[id]!['status'] = status;
        }
      }
      _items = uniqueItems.values.toList();

      notifyListeners();

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      if (isOnline) {
        var query = _supabase
            .from('denuncias')
            .select('*, localidades(nome), municipios(nome)');

        if (filterMun != null) {
          query = query.eq('cidade', filterMun);
        } else if (filterLocs != null && filterLocs.isNotEmpty) {
          query = query.inFilter('localidade_id', filterLocs);
        }

        final response = await query;
        final remoteItems = List<Map<String, dynamic>>.from(response);

        await _denunciasCache.clear();
        for (var item in remoteItems) {
          _denunciasCache.put(item['id'], item);
        }

        await _downloadImages(remoteItems);

        final combined = _denunciasCache.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final pendingAgain = _pendingDenunciasBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final finalUniqueItems = <String, Map<String, dynamic>>{};
        for (var item in [...combined, ...pendingAgain]) {
          finalUniqueItems[item['id']] = item;
        }
        
        // Reaplica status pendentes na lista combinada final
        for (var update in statusUpdates) {
            final map = Map<String, dynamic>.from(update as Map);
            final id = map['id'];
            final status = map['status'];
            if (finalUniqueItems.containsKey(id)) {
                finalUniqueItems[id]!['status'] = status;
            }
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
                }
             }
           } catch (e) {
             // Ignore
           }
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao baixar imagens para cache', e);
    }
  }

  Future<String?> _persistLocalPhoto(String originalPath) async {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final offlineDir = Directory('${appDir.path}/offline_denuncias_photos');
        if (!await offlineDir.exists()) {
          await offlineDir.create(recursive: true);
        }
        
        final fileName = originalPath.split(Platform.pathSeparator).last;
        final newPath = '${offlineDir.path}/$fileName';
        final file = File(originalPath);
        
        if (await file.exists()) {
           await file.copy(newPath);
           AppLogger.info('Foto da denúncia copiada para segurança: $newPath');
           return newPath;
        }
        return originalPath; // Retorna o original se não der pra copiar
      } catch (e) {
        AppLogger.warning('Erro ao persistir foto da denúncia localmente', e);
        return originalPath;
      }
  }

  Future<void> saveDenuncia(Denuncia denuncia) async {
    String? securePhotoPath;
    if (denuncia.foto_url != null && !denuncia.foto_url!.startsWith('http')) {
         securePhotoPath = await _persistLocalPhoto(denuncia.foto_url!);
    }

    final denunciaToSave = securePhotoPath != null 
        ? denuncia.copyWith(foto_url: securePhotoPath)
        : denuncia;

    final data = denunciaToSave.toMap();
    data['status'] = 'pendente_envio'; 

    await _pendingDenunciasBox.put(denuncia.id, data);

    if (denuncia.userId == null) {
       AppLogger.info('Salvando cópia no histórico anônimo local: ${denuncia.id}');
       await _anonymousHistoryBox.put(denuncia.id, data);
    }

    if (denuncia.userId != null) {
        await fetchMyDenuncias();
    } else {
        await fetchMyDenuncias();
    }

    syncPendingDenuncias();
  }
  
  Future<void> updateDenunciaStatus(String denunciaId, String novoStatus) async {
    // 1. Atualização Otimista no Cache LOCAL (para UI mudar na hora)
    await _updateLocalCacheStatus(denunciaId, novoStatus);

    try {
      // 2. Tenta atualizar online
      await _supabase
          .from('denuncias')
          .update({'status': novoStatus})
          .eq('id', denunciaId);

      AppLogger.info('Status da denúncia $denunciaId atualizado online para $novoStatus');
      
    } catch (e) {
      AppLogger.warning('Erro ao atualizar status online. Salvando pendência para envio posterior.', e);
      
      // 3. Se falhar, salva na FILA DE PENDÊNCIAS
      await _pendingStatusUpdatesBox.put(denunciaId, {
         'id': denunciaId,
         'status': novoStatus,
         'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
  
  Future<void> _updateLocalCacheStatus(String id, String status) async {
      // Atualiza cache principal
      final cachedDenuncia = _denunciasCache.get(id);
      if (cachedDenuncia != null) {
        final denunciaMap = Map<String, dynamic>.from(cachedDenuncia as Map);
        denunciaMap['status'] = status;
        await _denunciasCache.put(id, denunciaMap);
        
        // Atualiza lista em memória para refletir na UI instantaneamente
        updateItemInList(denunciaMap);
      }
      
      // Atualiza histórico anônimo
      if (_anonymousHistoryBox.containsKey(id)) {
          await _updateAnonymousHistoryStatus(id, status);
      }
  }

  Future<void> fetchMunicipios() async {
    _isMunicipiosLoading = true;
    notifyListeners();
    
    try {
      if (_municipiosCacheBox.isNotEmpty) {
        final cached = _municipiosCacheBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _municipios = cached.map((map) => Municipio.fromMap(map)).toList();
        notifyListeners(); 
      }

      final response = await _supabase.from('municipios').select('id, nome');
      final remoteList = (response as List).map((map) => Municipio.fromMap(map)).toList();
      
      _municipios = remoteList;
      
      await _municipiosCacheBox.clear();
      for (var item in remoteList) {
        await _municipiosCacheBox.add(item.toMap());
      }
      
    } catch (e, s) {
      AppLogger.error('Erro ao buscar municípios (usando cache se disponível)', e, s);
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
