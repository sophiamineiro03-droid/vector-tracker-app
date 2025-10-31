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
    if (kDebugMode) print('[SYNC_SERVICE] Iniciado.');

    // Tenta sincronizar ao iniciar o app.
    syncAll();

    // Tenta sincronizar quando a conexão com a internet é (re)estabelecida.
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = !result.contains(ConnectivityResult.none);
      if (isOnline) {
        if (kDebugMode) print('[SYNC_SERVICE] Conexão online detectada! Disparando sincronização.');
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    if (kDebugMode) print('[SYNC_SERVICE] Iniciando syncAll...');
    try {
      await _syncPendingDenuncias();
      await _syncPendingOcorrencias();
    } finally {
      _isSyncing = false;
      if (kDebugMode) print('[SYNC_SERVICE] syncAll finalizado.');
    }
  }

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
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${data['image_path'].split('/').last}';
            await supabase.storage.from('imagens_denuncias').upload(fileName, imageFile);
            imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(fileName);
          }
        }

        final Map<String, dynamic> cleanData = {
          'descricao': data['descricao'],
          'latitude': data['latitude']?.toString(),
          'longitude': data['longitude']?.toString(),
          'rua': data['rua'],
          'bairro': data['bairro'],
          'cidade': data['cidade'],
          'estado': data['estado'],
          'numero': data['numero']?.toString(),
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
        result['is_pending'] = false;
        _denunciaService.updateItemInList(result);
        if (kDebugMode) print('[SYNC_SERVICE] Denúncia $key SINCROZINADA COM SUCESSO!');

      } catch (e) {
        if (kDebugMode) print("[SYNC_SERVICE] Erro CRÍTICO ao sincronizar denúncia $key: $e.");
      }
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
        final List<String> newImageUrls = [];
        if (data['image_paths'] is List) {
          for (String path in data['image_paths']) {
            final imageFile = File(path);
            if (await imageFile.exists()) {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
              await supabase.storage.from('imagens_ocorrencias').upload(fileName, imageFile);
              final publicUrl = supabase.storage.from('imagens_ocorrencias').getPublicUrl(fileName);
              newImageUrls.add(publicUrl);
            }
          }
        }
        
        final Map<String, dynamic> cleanData = Map.from(data);
        final existingUrls = (cleanData['image_urls'] as List?)?.cast<String>() ?? [];
        cleanData['image_urls'] = [...existingUrls, ...newImageUrls];

        ['local_id', 'is_ocorrencia', 'is_pending', 'image_paths', 'local_image_paths'].forEach(cleanData.remove);
        
        final finalPayload = cleanData.map((key, value) {
            if (value is List || value is Map) return MapEntry(key, value);
            return MapEntry(key, value?.toString());
        });

        final recordId = finalPayload.remove('id');
        dynamic result;
        if (recordId != null && recordId.toString().isNotEmpty) {
          result = await supabase.from('ocorrencias').update(finalPayload).eq('id', recordId).select().single();
        } else {
          result = await supabase.from('ocorrencias').insert(finalPayload).select().single();
        }

        await _pendingOcorrenciasBox.delete(key);
        result['is_pending'] = false;
        _denunciaService.updateItemInList(result);
        if (kDebugMode) print('[SYNC_SERVICE] Ocorrência $key SINCROZINADA COM SUCESSO!');

      } catch (e) {
        if (kDebugMode) print("[SYNC_SERVICE] Erro CRÍTICO ao sincronizar ocorrência $key: $e.");
      }
    }
  }
}
