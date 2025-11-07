import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart'; // <<< ADICIONADO
import '../models/ocorrencia.dart';
import '../repositories/ocorrencia_repository.dart';
import '../repositories/agente_repository.dart';
import '../core/app_logger.dart';

// Classe auxiliar que movi do final do arquivo para o topo para clareza
class SyncResult {
  final bool success;
  final String message;
  SyncResult({required this.success, required this.message});
}

/// Serviço de ocorrências específico para agentes (VERSÃO CORRIGIDA)
///
/// ETAPA 4: Implementa offline-first com status_sincronizacao e RLS.
class AgentOcorrenciaService with ChangeNotifier {
  final OcorrenciaRepository _ocorrenciaRepository;
  final AgenteRepository _agenteRepository;
  final _uuid = const Uuid();

  List<Ocorrencia> _ocorrencias = [];
  List<Ocorrencia> get ocorrencias => _ocorrencias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int get pendingSyncCount =>
      _ocorrencias.where((o) => !o.sincronizado).length;

  AgentOcorrenciaService({
    required OcorrenciaRepository ocorrenciaRepository,
    required AgenteRepository agenteRepository,
  })  : _ocorrenciaRepository = ocorrenciaRepository,
        _agenteRepository = agenteRepository;

  /// Busca ocorrências do agente com estratégia offline-first.
  Future<void> fetchOcorrencias({bool showLoading = true}) async {
    try {
      if (showLoading) _setLoading(true);
      AppLogger.info('Buscando ocorrências do agente');

      // 1. Carrega do cache para uma resposta rápida
      final cachedOcorrencias =
      await _ocorrenciaRepository.getOcorrenciasFromCache();
      _ocorrencias = cachedOcorrencias;
      notifyListeners();
      AppLogger.info(
          '${cachedOcorrencias.length} ocorrências carregadas do cache');

      // 2. Mescla com itens pendentes que ainda não foram para o cache
      final pendingOcorrencias =
      await _ocorrenciaRepository.getFromPendingBox();
      _mergeLists(pendingOcorrencias);
      notifyListeners();

      // 3. Tenta buscar da nuvem para atualizar
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      if (isOnline) {
        AppLogger.info("Buscando dados frescos da nuvem...");
        final onlineOcorrencias =
        await _ocorrenciaRepository.fetchAllOcorrenciasFromSupabase();
        _ocorrencias = onlineOcorrencias; // A lista principal agora é a da nuvem
        _mergeLists(
            pendingOcorrencias); // Re-mescla pendentes com a lista fresca
        notifyListeners();
        AppLogger.info('✓ Ocorrências sincronizadas com a nuvem.');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro crítico ao buscar ocorrências', e, stackTrace);
    } finally {
      if (showLoading) _setLoading(false);
    }
  }

  /// Salva ocorrência com estratégia offline-first.
  Future<Ocorrencia> saveOcorrencia(Ocorrencia ocorrencia) async {
    try {
      AppLogger.info(
          'Salvando ocorrência: ${ocorrencia.id}');
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      final agente = await _agenteRepository.getCurrentAgent();
      Ocorrencia ocorrenciaToSave = ocorrencia.id.isEmpty
          ? ocorrencia.copyWith(
          id: _uuid.v4(), // Garante um ID local
          agente_id: agente?.id,
          municipio_id: agente?.municipioId,
          setor_id: agente?.setorId)
          : ocorrencia;

      if (isOnline) {
        try {
          // Tenta salvar diretamente na nuvem
          final syncedOcorrencia =
          await _ocorrenciaRepository.insertInSupabase(ocorrenciaToSave);
          _updateLocalList(syncedOcorrencia.copyWith(sincronizado: true));
          return syncedOcorrencia;
        } catch (e) {
          AppLogger.warning('Falha ao salvar online, salvando localmente: $e');
          await _ocorrenciaRepository.saveToPendingBox(ocorrenciaToSave);
          _updateLocalList(ocorrenciaToSave.copyWith(sincronizado: false));
          return ocorrenciaToSave;
        }
      } else {
        // Salva localmente para sincronização posterior
        AppLogger.info('Offline. Ocorrência salva para sincronização.');
        await _ocorrenciaRepository.saveToPendingBox(ocorrenciaToSave);
        _updateLocalList(ocorrenciaToSave.copyWith(sincronizado: false));
        return ocorrenciaToSave;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar ocorrência', e, stackTrace);
      rethrow;
    }
  }

  /// Sincroniza ocorrências pendentes.
  Future<SyncResult> syncPendingOcorrencias() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronização já em andamento');
    }
    _setSyncing(true);

    try {
      AppLogger.sync('Iniciando sincronização de ocorrências pendentes');
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return SyncResult(success: false, message: 'Sem conexão com a internet');
      }

      final pendingList = await _ocorrenciaRepository.getFromPendingBox();
      if (pendingList.isEmpty) {
        return SyncResult(success: true, message: 'Nenhuma pendência encontrada');
      }

      int successCount = 0;
      int errorCount = 0;

      for (var ocorrencia in pendingList) {
        try {
          // Tenta sincronizar com o Supabase
          final synced = await _ocorrenciaRepository.insertInSupabase(ocorrencia);

          // Remove da fila pendente
          await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);

          // Atualiza na lista local
          _updateLocalList(synced.copyWith(sincronizado: true));
          successCount++;
          AppLogger.sync('✓ Ocorrência ${ocorrencia.id} sincronizada');
        } catch (e, stackTrace) {
          AppLogger.error(
              'Erro ao sincronizar ocorrência ${ocorrencia.id}', e, stackTrace);
          errorCount++;
        }
      }

      final message = successCount > 0
          ? 'Sincronizadas $successCount ocorrências${errorCount > 0 ? ', $errorCount falharam' : ''}'
          : 'Falha ao sincronizar todas as ocorrências';

      AppLogger.sync('Sincronização concluída: $message');
      return SyncResult(success: successCount > 0, message: message);
    } catch (e, stackTrace) {
      AppLogger.error('Erro durante sincronização', e, stackTrace);
      return SyncResult(success: false, message: 'Erro na sincronização: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Mescla uma lista de ocorrências com a lista principal em memória.
  void _mergeLists(List<Ocorrencia> toMerge) {
    final tempMap = {for (var o in _ocorrencias) o.id: o};
    for (var o in toMerge) {
      tempMap[o.id] = o;
    }
    _ocorrencias = tempMap.values.toList();
    _ocorrencias.sort((a, b) => (b.data_atividade ?? DateTime(0))
        .compareTo(a.data_atividade ?? DateTime(0)));
  }

  /// Adiciona ou atualiza uma única ocorrência na lista em memória.
  void _updateLocalList(Ocorrencia ocorrencia) {
    final index = _ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
    if (index != -1) {
      _ocorrencias[index] = ocorrencia;
    } else {
      _ocorrencias.insert(0, ocorrencia);
    }
    _ocorrencias.sort((a, b) => (b.data_atividade ?? DateTime(0))
        .compareTo(a.data_atividade ?? DateTime(0)));
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSyncing(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      notifyListeners();
    }
  }

  /// Força a atualização dos dados da nuvem.
  Future<void> forceRefresh() async {
    AppLogger.info('Force refresh de ocorrências solicitado');
    await fetchOcorrencias(showLoading: true);
  }
}