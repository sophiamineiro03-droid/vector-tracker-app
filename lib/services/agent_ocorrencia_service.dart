import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
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

  // Método auxiliar para combinar cache + pendentes
  void _mergeOcorrencias(List<Ocorrencia> cachedOrServerList) {
    final Map<String, Ocorrencia> combinedMap = {};
    
    // 1. Adiciona a lista base (cache ou servidor)
    for (var o in cachedOrServerList) {
      combinedMap[o.id] = o;
    }
    
    // 2. Sobrepõe com pendentes (pendentes têm prioridade pois são edições locais ou novos registros)
    for (var p in _pendingOcorrencias) {
      combinedMap[p.id] = p;
    }
    
    _ocorrencias = combinedMap.values.toList();
    // A ordenação é feita na UI, mas poderíamos ordenar aqui se necessário
  }

  Future<void> fetchOcorrencias() async {
    _setLoading(true);
    try {
      // Carrega histórico do cache
      final cached = await _ocorrenciaRepository.getOcorrenciasFromCache();
      // Carrega pendentes
      await fetchPendingOcorrencias();
      
      // Combina para exibição
      _mergeOcorrencias(cached);
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
      final serverList = await _ocorrenciaRepository.fetchOcorrenciasByAgenteFromSupabase(agente.id);
      
      // Garante que pendentes estejam atualizados
      await fetchPendingOcorrencias();
      
      // Combina server + pendentes
      _mergeOcorrencias(serverList);
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
          
          // CORREÇÃO: Se falhar o upload, lança exceção para abortar o salvamento
          // e manter o item na lista de pendentes (offline).
          if (publicUrl != null) {
            finalImageUrls.add(publicUrl);
            
            // CACHE MANUAL: Copia a imagem local para o diretório de cache do SmartImage
            await _cacheImageForOffline(path, publicUrl);

          } else {
             throw Exception("Falha crítica: Não foi possível fazer upload da imagem $path. Abortando sincronização.");
          }
        }
      }

      ocorrenciaToUpload = ocorrenciaToUpload.copyWith(
        fotos_urls: finalImageUrls,
        localImagePaths: [], // Limpa os caminhos locais pois já subiram (e foram cacheados)
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
      
      // ATUALIZAÇÃO MANUAL DA LISTA LOCAL
      final index = _ocorrencias.indexWhere((o) => o.id == ocorrenciaToUpload.id);
      if (index != -1) {
        _ocorrencias[index] = ocorrenciaToUpload;
      } else {
        _ocorrencias.insert(0, ocorrenciaToUpload);
      }
      notifyListeners();

      forceRefresh();

    } catch (e) {
      AppLogger.warning('Falha ao salvar online. Iniciando persistência local...', e);
      
      // SE FALHA: Persiste imagens e salva na caixa de pendentes
      final ocorrenciaSegura = await _persistLocalImages(ocorrencia);
      
      final pendente = ocorrenciaSegura.copyWith(sincronizado: false);
      await _ocorrenciaRepository.saveToPendingBox(pendente);
      await fetchPendingOcorrencias();
      
      // Atualiza lista local
      final index = _ocorrencias.indexWhere((o) => o.id == pendente.id);
      if (index != -1) {
        _ocorrencias[index] = pendente;
      } else {
        _ocorrencias.insert(0, pendente);
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  /// Copia imagens temporárias para uma pasta segura do app.
  Future<Ocorrencia> _persistLocalImages(Ocorrencia ocorrencia) async {
    if (ocorrencia.localImagePaths == null || ocorrencia.localImagePaths!.isEmpty) {
      return ocorrencia;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDir.path}/offline_photos');
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      List<String> newPaths = [];
      for (String path in ocorrencia.localImagePaths!) {
        final file = File(path);
        AppLogger.info("Verificando imagem original: $path");
        
        // Verifica se arquivo existe
        if (await file.exists()) {
          // Se já está no diretório offline, mantém
          if (path.startsWith(offlineDir.path)) {
            newPaths.add(path);
            continue;
          }
          
          // Copia para lá
          final fileName = path.split(Platform.pathSeparator).last;
          final newPath = '${offlineDir.path}/$fileName';
          final targetFile = File(newPath);
          
          if (!await targetFile.exists()) {
             await file.copy(newPath);
             AppLogger.info("Imagem copiada para: $newPath");
          } else {
             AppLogger.info("Imagem já existe no destino: $newPath");
          }
          newPaths.add(newPath);
        } else {
          AppLogger.warning("Imagem original NÃO ENCONTRADA: $path");
          // Mantém path original como fallback, mas provavelmente falhará
          newPaths.add(path);
        }
      }
      return ocorrencia.copyWith(localImagePaths: newPaths);
    } catch (e) {
      AppLogger.error("Erro ao persistir imagens locais: $e");
      return ocorrencia;
    }
  }
  
  Future<void> _cacheImageForOffline(String originalPath, String publicUrl) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/images_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final uri = Uri.parse(publicUrl);
      final filename = uri.pathSegments.last;
      final targetFile = File('${cacheDir.path}/$filename');

      final sourceFile = File(originalPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetFile.path);
        AppLogger.info('Imagem cacheada manualmente: ${targetFile.path}');
      }
    } catch (e) {
      AppLogger.warning('Falha ao cachear imagem manualmente: $e');
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
        await saveOcorrencia(ocorrencia);
        
        final stillPending = await _ocorrenciaRepository.getFromPendingBox();
        if (!stillPending.any((o) => o.id == ocorrencia.id)) {
           successCount++;
        }
      } catch (e, s) {
        AppLogger.error('Erro ao sincronizar ocorrência ${ocorrencia.id}', e, s);
      }
    }

    _setSyncing(false);
    await fetchPendingOcorrencias();

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
