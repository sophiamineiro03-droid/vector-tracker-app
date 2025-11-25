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
import 'package:vector_tracker_app/services/denuncia_service.dart';

class AgentOcorrenciaService extends ChangeNotifier {
  final AgenteRepository _agenteRepository;
  final OcorrenciaRepository _ocorrenciaRepository;
  final SupabaseClient _supabase = GetIt.I.get<SupabaseClient>();

  AgentOcorrenciaService(this._agenteRepository, this._ocorrenciaRepository);

  List<Ocorrencia> _ocorrencias = [];
  // Histórico de ocorrências (já sincronizadas ou salvas localmente para histórico)
  List<Ocorrencia> get ocorrencias => _ocorrencias;

  // Lista separada apenas para itens pendentes de envio
  List<Ocorrencia> _pendingOcorrencias = [];
  List<Ocorrencia> get pendingOcorrencias => _pendingOcorrencias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Conta apenas os itens que realmente estão na fila de sincronização
  int get pendingSyncCount => _pendingOcorrencias.length;

  // Busca apenas os itens da caixa de pendentes
  Future<void> fetchPendingOcorrencias() async {
    try {
      _pendingOcorrencias = await _ocorrenciaRepository.getFromPendingBox();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Erro ao buscar ocorrências pendentes', e);
      _pendingOcorrencias = [];
      notifyListeners();
    }
  }

  Future<void> fetchOcorrencias() async {
    _setLoading(true);
    try {
      // Carrega histórico do cache
      _ocorrencias = await _ocorrenciaRepository.getOcorrenciasFromCache();
      // Carrega pendentes
      await fetchPendingOcorrencias();
      notifyListeners();
      
      // Tenta buscar dados novos do servidor
      await forceRefresh();
    } catch (e) {
      AppLogger.error('Erro ao buscar ocorrências', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forceRefresh() async {
    // Não ativa loading global para não travar a UI se for apenas atualização de fundo
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
      AppLogger.warning('Erro ao forçar atualização (possivelmente offline)', e);
    }
  }

  Future<void> saveOcorrencia(Ocorrencia ocorrencia) async {
    _setLoading(true);
    try {
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) throw Exception('Agente não identificado.');

      var ocorrenciaToUpload = ocorrencia.copyWith(agente_id: agente.id);

      // Prepara URLs de imagens
      List<String> finalImageUrls = List.from(ocorrencia.fotos_urls ?? []);

      // Upload de imagens novas
      if (ocorrenciaToUpload.localImagePaths != null &&
          ocorrenciaToUpload.localImagePaths!.isNotEmpty) {
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
      
      // Tenta salvar no Supabase
      await _supabase.from('ocorrencias').upsert(data);
      AppLogger.info('Ocorrência ${ocorrenciaToUpload.id} salva (upsert) no Supabase!');

      // SE SUCESSO: Remove da caixa de pendentes (caso estivesse lá)
      await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);

      // Atualiza status da denúncia se houver
      if (ocorrenciaToUpload.denuncia_id != null &&
          ocorrenciaToUpload.denuncia_id!.isNotEmpty) {
        try {
          await _supabase
              .from('denuncias')
              .update({'status': 'atendida'}).eq('id', ocorrenciaToUpload.denuncia_id!);
          
          final denunciaService = GetIt.I.get<DenunciaService>();
          await denunciaService.updateDenunciaStatus(ocorrenciaToUpload.denuncia_id!, 'atendida');
        } catch (e, s) {
          AppLogger.error('Falha ao atualizar o status da denúncia original.', e, s);
        }
      }
      
      // Atualiza listas em memória
      await fetchPendingOcorrencias();
      await forceRefresh();

    } catch (e) {
      AppLogger.warning('Falha ao salvar online, salvando localmente.', e);
      // SE FALHA: Salva na caixa de pendentes
      await _ocorrenciaRepository.saveToPendingBox(ocorrencia.copyWith(sincronizado: false));
      await fetchPendingOcorrencias();
    } finally {
      _setLoading(false);
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

    await fetchPendingOcorrencias();
    if (_pendingOcorrencias.isEmpty) {
      return "Nenhuma ocorrência pendente para sincronizar.";
    }

    _setSyncing(true);
    int successCount = 0;
    final itemsToSync = List<Ocorrencia>.from(_pendingOcorrencias);

    for (var ocorrencia in itemsToSync) {
      try {
        // Reutiliza saveOcorrencia que já trata upload e remoção de pendentes
        await saveOcorrencia(ocorrencia);
        
        // Verifica se foi removido dos pendentes para confirmar sucesso
        final stillPending = await _ocorrenciaRepository.getFromPendingBox();
        if (!stillPending.any((o) => o.id == ocorrencia.id)) {
           successCount++;
        }
      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.id}', e, s);
      }
    }

    _setSyncing(false);
    await fetchPendingOcorrencias(); // Garante UI atualizada

    final message = successCount == itemsToSync.length
        ? "Todas as ${itemsToSync.length} ocorrências foram sincronizadas!"
        : "Sincronização concluída. $successCount de ${itemsToSync.length} enviadas.";

    AppLogger.sync(message);
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
