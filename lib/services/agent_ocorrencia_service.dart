import 'dart:io';
import 'package:flutter/foundation.dart';import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/repositories/ocorrencia_repository.dart';

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
      // Continua carregando do cache primeiro para uma UI rápida
      _ocorrencias = await _ocorrenciaRepository.getOcorrenciasFromCache();
      notifyListeners();
      // Depois busca os dados mais recentes da rede
      await forceRefresh();
    } catch (e) {
      AppLogger.error('Erro ao buscar ocorrências', e);
    } finally {
      _setLoading(false);
    }
  }

  // --- 1. MÉTODO DE BUSCA CORRIGIDO ---
  Future<void> forceRefresh() async {
    _setLoading(true);
    try {
      // Busca o agente logado para saber quem estamos buscando
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) {
        AppLogger.warning('Nenhum agente logado, limpando lista de ocorrências.');
        _ocorrencias = [];
        notifyListeners();
        return;
      }

      // Chama o método CORRETO do repositório, passando o ID do agente
      _ocorrencias = await _ocorrenciaRepository.fetchOcorrenciasByAgenteFromSupabase(agente.id);
      notifyListeners();

    } catch (e) {
      AppLogger.error('Erro ao forçar atualização', e);
    } finally {
      _setLoading(false);
    }
  }

  // --- 2. MÉTODO DE SALVAMENTO CORRIGIDO (COM UPDATE) ---
  Future<void> saveOcorrencia(Ocorrencia ocorrencia) async {
    _setLoading(true);
    try {
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) throw Exception('Agente não identificado.');

      var ocorrenciaToUpload = ocorrencia.copyWith(agente_id: agente.id);

      List<String> finalImageUrls = [];
      if(ocorrenciaToUpload.fotos_urls != null) {
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

      // --- LÓGICA DE SALVAMENTO SIMPLIFICADA COM UPSERT ---
      // A função 'upsert' do Supabase faz o trabalho de dois:
      // 1. Se um registro com o mesmo 'id' já existe, ele ATUALIZA.
      // 2. Se não existe, ele CRIA um novo.
      // Isso elimina a necessidade da verificação manual.
      final data = ocorrenciaToUpload.toMap();
      await _supabase.from('ocorrencias').upsert(data);
      AppLogger.info('Ocorrência ${ocorrenciaToUpload.id} salva (upsert) no Supabase!');
      // --- INÍCIO DA CORREÇÃO ---
      // Se esta ocorrência veio de uma denúncia, atualizamos o status dela.
      if (ocorrenciaToUpload.denuncia_id != null && ocorrenciaToUpload.denuncia_id!.isNotEmpty) {
        try {
          await _supabase
              .from('denuncias')
              .update({'status': 'atendida'}) // Muda o status para 'atendida'
              .eq('id', ocorrenciaToUpload.denuncia_id!);
          AppLogger.info('Status da denúncia ${ocorrenciaToUpload.denuncia_id} atualizado para "atendida".');
          // TODO: INICIAR ATUALIZAÇÃO DO CACHE DE DENÚNCIAS.
          // O status da denúncia foi atualizado no Supabase, mas a lista de
          // pendências (DenunciaService) pode estar usando um cache local.
          // É preciso invalidar esse cache para que a denúncia atendida
          // desapareça da tela de pendências imediatamente.
          //
          // AÇÃO FUTURA:
          // 1. Adicionar: import 'package:vector_tracker_app/services/denuncia_service.dart';
          // 2. Registrar o DenunciaService no GetIt (no main.dart).
          // 3. Obter a instância com: GetIt.I.get<DenunciaService>()
          // 4. Chamar um método para forçar a atualização: await service.fetchItems();
        } catch (e, s) {
          // Apenas registra o erro, não para a execução
          AppLogger.error('Falha ao atualizar o status da denúncia original.', e, s);
        }
      }
      // --- FIM DA CORREÇÃO ---
    } catch (e) {
      AppLogger.warning('Falha ao salvar online, salvando localmente.', e);
      await _ocorrenciaRepository.saveToPendingBox(ocorrencia.copyWith(sincronizado: false));
    } finally {
      // Força a atualização da lista para refletir a mudança
      await forceRefresh();
      _setLoading(false);
      syncPendingOcorrencias();
    }
  }

  Future<String?> _uploadImage(String filePath, String ocorrenciaId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      AppLogger.warning('Arquivo local não encontrado para upload: $filePath');
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
    AppLogger.sync('Sincronizando ${pending.length} ocorrências pendentes.');

    int successCount = 0;
    for (var ocorrencia in pending) {
      try {
        // Reutiliza a lógica principal de salvamento para sincronizar
        await saveOcorrencia(ocorrencia);
        await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);
        successCount++;
        AppLogger.sync('Ocorrência pendente ${ocorrencia.id} sincronizada com sucesso!');
      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.id}', e, s);
      }
    }

    final message = successCount == pending.length
        ? "Todas as ${pending.length} ocorrências pendentes foram sincronizadas com sucesso!"
        : "Sincronização concluída. $successCount de ${pending.length} ocorrências foram sincronizadas.";

    AppLogger.sync(message);
    _setSyncing(false);
    await forceRefresh(); // Atualiza a UI com os dados novos
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
