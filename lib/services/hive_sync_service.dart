import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/core/exceptions.dart';
import 'package:vector_tracker_app/core/service_locator.dart';

/// Serviço de sincronização usando Hive para armazenamento local
/// 
/// ETAPA 2: Refatorado para usar AppLogger e tratamento de erros estruturado.
class HiveSyncService {
  final DenunciaService _denunciaService;
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');
  final Box _pendingOcorrenciasBox = Hive.box('pending_ocorrencias');

  bool _isSyncing = false;

  HiveSyncService({required DenunciaService denunciaService}) : _denunciaService = denunciaService;

  void start() {
    AppLogger.sync('Serviço de sincronização iniciado e ouvindo conectividade');
    syncAll();
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi);
      if (isOnline) {
        AppLogger.sync('Conexão detectada! Disparando sincronização');
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      AppLogger.debug('Sync já em progresso, ignorando');
      return;
    }
    _isSyncing = true;

    AppLogger.sync('Iniciando sincronização de todos os dados pendentes');
    try {
      await _syncPendingOcorrencias();
      await _syncPendingDenuncias();
    } catch (e, stackTrace) {
      AppLogger.error('Erro durante sincronização', e, stackTrace);
    } finally {
      _isSyncing = false;
      AppLogger.sync('Sincronização finalizada');
    }
  }

  Future<void> _syncPendingOcorrencias() async {
    if (_pendingOcorrenciasBox.isEmpty) {
      AppLogger.sync('Nenhuma ocorrência pendente para sincronizar');
      return;
    }
    
    AppLogger.sync('Encontradas ${_pendingOcorrenciasBox.length} ocorrências pendentes');

    final List pendingKeys = _pendingOcorrenciasBox.keys.toList();

    for (var key in pendingKeys) {
      try {
        final data = Map<String, dynamic>.from(_pendingOcorrenciasBox.get(key) as Map);
        AppLogger.sync('Sincronizando ocorrência $key');

        final List<String> existingImageUrls = List<String>.from(data['image_urls'] ?? []);
        final List<String> newImageUrls = [];
        
        if (data['image_paths'] != null) {
          final imagePaths = List<String>.from(data['image_paths']);
          for (String path in imagePaths) {
            final imageFile = File(path);
            if (await imageFile.exists()) {
              AppLogger.sync('Fazendo upload de imagem: $path');
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
          AppLogger.sync('Atualizando ocorrência existente $recordId');
          result = await supabase.from('ocorrencias').update(cleanData).eq('id', recordId).select().single();
        } else {
          AppLogger.sync('Criando nova ocorrência');
          result = await supabase.from('ocorrencias').insert(cleanData).select().single();
        }

        await _pendingOcorrenciasBox.delete(key);

        final localDataToUpdate = Map<String, dynamic>.from(data);
        localDataToUpdate['is_pending'] = false;
        localDataToUpdate['id'] = result['id'];

        _denunciaService.updateItemInList(localDataToUpdate);
        AppLogger.sync('✓ Ocorrência $key sincronizada com sucesso');

      } catch (e, stackTrace) {
        AppLogger.error('Erro ao sincronizar ocorrência $key', e, stackTrace);
        // Continua para próxima ocorrência
      }
    }
  }


  /// ETAPA 2: Refatorado para usar AppLogger
  Future<void> _syncPendingDenuncias() async {
    if (_pendingDenunciasBox.isEmpty) {
      AppLogger.sync('Nenhuma denúncia pendente para sincronizar');
      return;
    }
    
    AppLogger.sync('Encontradas ${_pendingDenunciasBox.length} denúncias pendentes');

    final List pendingKeys = _pendingDenunciasBox.keys.toList();

    for (var key in pendingKeys) {
      try {
        final data = Map<String, dynamic>.from(_pendingDenunciasBox.get(key) as Map);
        AppLogger.sync('Sincronizando denúncia $key');

        String? imageUrl = data['image_url'];
        if (data['image_path'] != null) {
          final imageFile = File(data['image_path']);
          if (await imageFile.exists()) {
            AppLogger.sync('Fazendo upload de imagem da denúncia: $imageFile');
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
            final uploadPath = 'public/denuncias/$fileName';
            await supabase.storage.from('imagens_denuncias').upload(uploadPath, imageFile);
            imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath);
          }
        }

        final Map<String, dynamic> cleanData = {
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
          AppLogger.sync('Atualizando denúncia existente $recordId');
          result = await supabase.from('denuncias').update(cleanData).eq('id', recordId).select().single();
        } else {
          AppLogger.sync('Criando nova denúncia');
          result = await supabase.from('denuncias').insert(cleanData).select().single();
        }

        await _pendingDenunciasBox.delete(key);

        final localDataToUpdate = Map<String, dynamic>.from(data);
        localDataToUpdate['is_pending'] = false;
        localDataToUpdate['id'] = result['id'];
        
        _denunciaService.updateItemInList(localDataToUpdate);
        AppLogger.sync('✓ Denúncia $key sincronizada com sucesso');

      } catch (e, stackTrace) {
        AppLogger.error('Erro ao sincronizar denúncia $key', e, stackTrace);
        // Continua para próxima denúncia
      }
    }
  }
}
