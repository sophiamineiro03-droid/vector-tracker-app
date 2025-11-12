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
      _ocorrencias = await _ocorrenciaRepository.fetchAllOcorrenciasFromSupabase();
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

      // Lista que vai guardar todas as URLs finais
      List<String> finalImageUrls = [];
      // Adiciona as fotos que já eram URLs (vindas de uma denúncia ou edição)
      if(ocorrenciaToUpload.fotos_urls != null) {
        finalImageUrls.addAll(ocorrenciaToUpload.fotos_urls!);
      }

      // Faz o upload das novas fotos que foram tiradas no celular
      if (ocorrenciaToUpload.localImagePaths != null && ocorrenciaToUpload.localImagePaths!.isNotEmpty) {
        for (String path in ocorrenciaToUpload.localImagePaths!) {
          String? publicUrl = await _uploadImage(path, ocorrenciaToUpload.id);
          if (publicUrl != null) {
            finalImageUrls.add(publicUrl);
          }
        }
      }

      // Cria o objeto final com as URLs consolidadas e status de sincronizado
      ocorrenciaToUpload = ocorrenciaToUpload.copyWith(
        fotos_urls: finalImageUrls,
        localImagePaths: [], // Limpa os caminhos locais, pois já foram processados
        sincronizado: true,
      );

      // Agora sim, insere o registro completo e correto no Supabase
      await _ocorrenciaRepository.insertInSupabase(ocorrenciaToUpload);
      print('Ocorrência salva diretamente no Supabase com sucesso!');

    } catch (e) {
      AppLogger.warning('Falha ao salvar online, salvando localmente.', e);
      // Se falhar, o objeto 'ocorrencia' original ainda tem os caminhos locais
      await _ocorrenciaRepository.saveToPendingBox(ocorrencia.copyWith(sincronizado: false));
    } finally {
      await fetchOcorrencias();
      _setLoading(false);
      // Dispara a sincronização para garantir que qualquer pendência seja resolvida
      syncPendingOcorrencias();
    }
  }

  Future<String?> _uploadImage(String filePath, String ocorrenciaId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      AppLogger.warning('Arquivo local não encontrado para upload: $filePath');
      return null;
    }

    // Cria um nome de arquivo único para evitar sobreposições
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
        var ocorrenciaToSync = ocorrencia;
        List<String> finalImageUrls = [];

        if (ocorrencia.localImagePaths != null && ocorrencia.localImagePaths!.isNotEmpty) {
          AppLogger.sync('Processando ${ocorrencia.localImagePaths!.length} imagens para a ocorrência ${ocorrencia.id}');
          for (String path in ocorrencia.localImagePaths!) {
            if (path.startsWith('http')) {
              finalImageUrls.add(path); // Já é uma URL, mantém
            } else {
              // É um caminho local, precisa fazer upload
              String? publicUrl = await _uploadImage(path, ocorrencia.id);
              if (publicUrl != null) {
                finalImageUrls.add(publicUrl);
              }
            }
          }
          // Atualiza o objeto com as novas URLs
          ocorrenciaToSync = ocorrenciaToSync.copyWith(fotos_urls: finalImageUrls);
        }

        // Garante que o status de sincronizado seja verdadeiro
        ocorrenciaToSync = ocorrenciaToSync.copyWith(sincronizado: true);

        // Salva a ocorrência completa no Supabase
        await _ocorrenciaRepository.insertInSupabase(ocorrenciaToSync);

        // Se tudo deu certo, remove do cache de pendentes
        await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);
        successCount++;
        AppLogger.sync('Ocorrência ${ocorrencia.id} sincronizada com sucesso!');

      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.id}', e, s);
      }
    }

    final message = successCount == pending.length
        ? "Todas as ${pending.length} ocorrências pendentes foram sincronizadas com sucesso!"
        : "Sincronização concluída. $successCount de ${pending.length} ocorrências foram sincronizadas.";

    AppLogger.sync(message);
    _setSyncing(false);
    await fetchOcorrencias(); // Atualiza a UI com os dados novos
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