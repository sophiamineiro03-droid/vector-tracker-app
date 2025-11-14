import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/repositories/ocorrencia_repository.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart'; // Importa o serviço de denúncias

class AgentOcorrenciaService extends ChangeNotifier {
  final AgenteRepository _agenteRepository;
  final OcorrenciaRepository _ocorrenciaRepository;
  final SupabaseClient _supabase = GetIt.I.get<SupabaseClient>();

  AgentOcorrenciaService(this._agenteRepository, this._ocorrenciaRepository);

  List<Ocorrencia> _ocorrencias = [];
  List<Ocorrencia> get ocorrencias => _ocorrencias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int get pendingSyncCount {
    try {
      final box = GetIt.I.get<Box>(instanceName: 'pending_ocorrencias');
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> fetchOcorrencias() async {
    _setLoading(true);
    try {
      _ocorrencias = await _ocorrenciaRepository.getOcorrenciasFromCache();
      notifyListeners();
      await forceRefresh();
    } catch (e) {
      AppLogger.error('Erro ao buscar ocorrências', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forceRefresh() async {
    _setLoading(true);
    try {
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) {
        _ocorrencias = [];
        notifyListeners();
        return;
      }
      _ocorrencias = await _ocorrenciaRepository.fetchOcorrenciasByAgenteFromSupabase(agente.id);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Erro ao forçar atualização', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveOcorrencia(Ocorrencia ocorrencia) async {
    _setLoading(true);
    try {
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) throw Exception('Agente não identificado.');

      var ocorrenciaToUpload = ocorrencia.copyWith(agente_id: agente.id);

      List<String> finalImageUrls = [];
      if (ocorrenciaToUpload.fotos_urls != null) {
        finalImageUrls.addAll(ocorrenciaToUpload.fotos_urls!);
      }

      if (ocorrenciaToUpload.localImagePaths != null && ocorrenciaToUpload.localImagePaths!.isNotEmpty) {
        for (String path in ocorrenciaToUpload.localImagePaths!) {
          String? publicUrl = await _uploadImage(path, ocorrenciaToUpload.id);
          if (publicUrl != null) {
            finalImageUrls.add(publicUrl);
          }
        }
      }

      ocorrenciaToUpload = ocorrenciaToUpload.copyWith(
        fotos_urls: finalImageUrls,
        localImagePaths: [],
        sincronizado: true,
      );

      final data = ocorrenciaToUpload.toMap();
      await _supabase.from('ocorrencias').upsert(data);
      AppLogger.info('Ocorrência ${ocorrenciaToUpload.id} salva (upsert) no Supabase!');

      if (ocorrenciaToUpload.denuncia_id != null && ocorrenciaToUpload.denuncia_id!.isNotEmpty) {
        try {
          await _supabase
              .from('denuncias')
              .update({'status': 'atendida'})
              .eq('id', ocorrenciaToUpload.denuncia_id!);
          AppLogger.info('Status da denúncia ${ocorrenciaToUpload.denuncia_id} atualizado para "atendida".');

          // --- TODO RESOLVIDO! ---
          // Busca o DenunciaService e força a atualização
          final denunciaService = GetIt.I.get<DenunciaService>();
          await denunciaService.fetchItems(); // Força a busca de novos itens

        } catch (e, s) {
          AppLogger.error('Falha ao atualizar o status da denúncia original.', e, s);
        }
      }
    } catch (e) {
      AppLogger.warning('Falha ao salvar online, salvando localmente.', e);
      await _ocorrenciaRepository.saveToPendingBox(ocorrencia.copyWith(sincronizado: false));
    } finally {
      await forceRefresh();
      _setLoading(false);
      syncPendingOcorrencias();
    }
  }

  Future<String?> _uploadImage(String filePath, String ocorrenciaId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final fileName = '${ocorrenciaId}/${const Uuid().v4()}.${filePath.split('.').last}';

    try {
      await _supabase.storage.from('fotos-ocorrencias').upload(fileName, file);
      return _supabase.storage.from('fotos-ocorrencias').getPublicUrl(fileName);
    } catch (e) {
      AppLogger.error('Erro no upload da imagem da ocorrência: $e');
      return null;
    }
  }

  Future<String> syncPendingOcorrencias() async {
    if (_isSyncing) return "Sincronização já em andamento.";

    final pending = await _ocorrenciaRepository.getFromPendingBox();
    if (pending.isEmpty) {
      return "Nenhuma ocorrência pendente para sincronizar.";
    }

    _setSyncing(true);
    int successCount = 0;
    for (var ocorrencia in pending) {
      try {
        await saveOcorrencia(ocorrencia);
        await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);
        successCount++;
      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.id}', e, s);
      }
    }

    final message = successCount == pending.length
        ? "Todas as ${pending.length} ocorrências pendentes foram sincronizadas com sucesso!"
        : "Sincronização concluída. $successCount de ${pending.length} ocorrências foram sincronizadas.";

    AppLogger.sync(message);
    _setSyncing(false);
    await forceRefresh();
    return message;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setSyncing(bool value) {
    if (_isSyncing == value) return;
    _isSyncing = value;
    notifyListeners();
  }
}
