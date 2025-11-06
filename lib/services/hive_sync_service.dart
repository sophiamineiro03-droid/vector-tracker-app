import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/ocorrencia_siocchagas.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';

class HiveSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DenunciaService _denunciaService;
  final OcorrenciaSiocchagasService _ocorrenciaService;

  bool _isSyncing = false;

  HiveSyncService({
    required DenunciaService denunciaService,
    required OcorrenciaSiocchagasService ocorrenciaService,
  })  : _denunciaService = denunciaService,
        _ocorrenciaService = ocorrenciaService;

  void start() {
    AppLogger.sync('Serviço de sincronização iniciado.');
    syncAll();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        AppLogger.sync('Conexão detectada! Disparando sincronização.');
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    AppLogger.sync('Iniciando sincronização de dados pendentes.');

    try {
      await _syncOcorrencias();
    } catch (e, s) {
      AppLogger.error('Erro durante a sincronização', e, s);
    } finally {
      _isSyncing = false;
      AppLogger.sync('Sincronização finalizada.');
    }
  }

  Future<String?> _uploadFoto(String? fotoPath) async {
    if (fotoPath == null || fotoPath.isEmpty) return null;
    final file = File(fotoPath);
    if (!await file.exists()) return null;

    final fileName = '${Uuid().v4()}_${fotoPath.split('/').last}';
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final uploadPath = '$userId/ocorrencias/$fileName';

    try {
      await _supabase.storage.from('imagens_denuncias').upload(uploadPath, file);
      return _supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath);
    } catch (e, s) {
      AppLogger.error('Erro no upload da foto: $fotoPath', e, s);
      return null;
    }
  }

  Future<void> _syncOcorrencias() async {
    final pendentes = _ocorrenciaService.pendentesSincronizacao;
    final currentUser = _supabase.auth.currentUser;

    if (pendentes.isEmpty) {
      return;
    }

    if (currentUser == null) {
      AppLogger.sync('Sincronização de ocorrências adiada: Nenhum usuário logado.');
      return;
    }

    AppLogger.sync('Sincronizando ${pendentes.length} ocorrências.');

    for (final ocorrencia in pendentes) {
      try {
        final url1 = await _uploadFoto(ocorrencia.foto_url_1);
        final url2 = await _uploadFoto(ocorrencia.foto_url_2);
        final url3 = await _uploadFoto(ocorrencia.foto_url_3);
        final url4 = await _uploadFoto(ocorrencia.foto_url_4);

        final dataToSync = ocorrencia.toMap();

        dataToSync['agente_id'] ??= currentUser.id;

        dataToSync.addAll({
          'foto_url_1': url1,
          'foto_url_2': url2,
          'foto_url_3': url3,
          'foto_url_4': url4,
        });

        await _supabase.from('ocorrencias').insert(dataToSync);

        if (ocorrencia.denuncia_id != null) {
          await _supabase
              .from('denuncias')
              .update({'status': 'Atendida'})
              .eq('id', ocorrencia.denuncia_id!);
        }

        ocorrencia.status_envio = 'Enviada (Sincronizada)';
        await _ocorrenciaService.saveOcorrencia(ocorrencia);

      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.localId}', e, s);
      }
    }
    await _denunciaService.fetchItems();
  }
}
