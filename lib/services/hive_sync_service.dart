import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';


class HiveSyncService {
  final DenunciaService _denunciaService;
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');
  final Box _pendingOcorrenciasBox = Hive.box('pending_ocorrencias');

  bool _isSyncing = false;

  HiveSyncService({required DenunciaService denunciaService}) : _denunciaService = denunciaService;

  void start() {
    if (kDebugMode) {
      print('[SYNC_SERVICE] Iniciado e ouvindo a conectividade.');
    }
    syncAll();
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi);
      if (isOnline) {
        if (kDebugMode) print('[SYNC_SERVICE] Conexão detectada! Disparando sincronização.');
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    if (kDebugMode) print('[SYNC_SERVICE] Iniciando syncAll.');
    try {
      await _syncPendingOcorrencias();
      await _syncPendingDenuncias();
    } finally {
      _isSyncing = false;
      if (kDebugMode) print('[SYNC_SERVICE] Finalizado syncAll.');
    }
  }

  Future<void> _syncPendingOcorrencias() async {
    if (_pendingOcorrenciasBox.isEmpty) return;
    if (kDebugMode) print("[SYNC_SERVICE] Encontradas ${_pendingOcorrenciasBox.length} ocorrências pendentes.");

    final List pendingKeys = _pendingOcorrenciasBox.keys.toList();

    for (var key in pendingKeys) {
      final data = Map<String, dynamic>.from(_pendingOcorrenciasBox.get(key) as Map);
      if (kDebugMode) print('[SYNC_SERVICE] Sincronizando ocorrência $key...');

      try {
        final List<String> existingImageUrls = List<String>.from(data['image_urls'] ?? []);
        final List<String> newImageUrls = [];
        if (data['image_paths'] != null) {
          final imagePaths = List<String>.from(data['image_paths']);
          for (String path in imagePaths) {
            final imageFile = File(path);
            if (await imageFile.exists()) {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
              final userId = supabase.auth.currentUser?.id ?? 'anonymous';
              final uploadPath = '$userId/ocorrencias/$fileName';
              await supabase.storage.from('imagens_denuncias').upload(uploadPath, imageFile);
              newImageUrls.add(supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath));
            }
          }
        }

        final Map<String, dynamic> cleanData = Map.from(data);
        cleanData.remove('local_id');
        cleanData.remove('is_ocorrencia');
        cleanData.remove('is_pending');
        cleanData.remove('image_paths');
        cleanData.remove('local_image_paths');
        cleanData.remove('created_at');
        cleanData.remove('status');

        cleanData['image_urls'] = [...existingImageUrls, ...newImageUrls];
        cleanData['uid'] = supabase.auth.currentUser?.id;

        final recordId = cleanData.remove('id');
        dynamic result;
        if (recordId != null) {
          result = await supabase.from('ocorrencias').update(cleanData).eq('id', recordId).select().single();
        } else {
          result = await supabase.from('ocorrencias').insert(cleanData).select().single();
        }

        await _pendingOcorrenciasBox.delete(key);

        final localDataToUpdate = Map<String, dynamic>.from(data);
        localDataToUpdate['is_pending'] = false;
        localDataToUpdate['id'] = result['id'];

        _denunciaService.updateItemInList(localDataToUpdate);
        if (kDebugMode) print('[SYNC_SERVICE] Ocorrência $key SINCROZINADA COM SUCESSO e UI notificada!');

      } catch (e) {
        if (kDebugMode) print("[SYNC_SERVICE] Erro ao sincronizar ocorrência $key: $e. Tentará novamente.");
      }
    }
  }


  // MODIFICADO: Removido o UID e a dependência de um usuário logado
  Future<void> _syncPendingDenuncias() async {
    if (_pendingDenunciasBox.isEmpty) return;
    if (kDebugMode) print("[SYNC_SERVICE] Encontradas ${_pendingDenunciasBox.length} denúncias pendentes.");

    final List pendingKeys = _pendingDenunciasBox.keys.toList();

    for (var key in pendingKeys) {
      final data = Map<String, dynamic>.from(_pendingDenunciasBox.get(key) as Map);
      if (kDebugMode) print('[SYNC_SERVICE] Sincronizando denúncia $key...');

      try {
        String? imageUrl = data['image_url'];
        if (data['image_path'] != null) {
          final imageFile = File(data['image_path']);
          if (await imageFile.exists()) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
            final uploadPath = 'public/denuncias/$fileName'; // Caminho público
            await supabase.storage.from('imagens_denuncias').upload(uploadPath, imageFile);
            imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath);
          }
        }

        final Map<String, dynamic> cleanData = {
          // Removido o 'uid'
          'descricao': data['descricao'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'rua': data['rua'],
          'bairro': data['bairro'],
          'cidade': data['cidade'],
          'estado': data['estado'],
          'numero': data['numero'],
          'status': data['status'],
          'image_url': imageUrl,
        };

        final recordId = data['id'];
        dynamic result;
        if (recordId != null) {
          result = await supabase.from('denuncias').update(cleanData).eq('id', recordId).select().single();
        } else {
          result = await supabase.from('denuncias').insert(cleanData).select().single();
        }

        await _pendingDenunciasBox.delete(key);

        final localDataToUpdate = Map<String, dynamic>.from(data);
        localDataToUpdate['is_pending'] = false;
        localDataToUpdate['id'] = result['id'];
        
        _denunciaService.updateItemInList(localDataToUpdate);
        if (kDebugMode) print('[SYNC_SERVICE] Denúncia $key SINCROZINADA COM SUCESSO e UI notificada!');

      } catch (e) {
        if (kDebugMode) print("[SYNC_SERVICE] Erro ao sincronizar denúncia $key: $e. Tentará novamente.");
      }
    }
  }
}
