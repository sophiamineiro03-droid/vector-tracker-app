import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:uuid/uuid.dart'; // Será adicionado quando necessário
import '../models/ocorrencia.dart';
import '../repositories/ocorrencia_repository.dart';
import '../repositories/agente_repository.dart';
import '../core/app_logger.dart';
import '../core/exceptions.dart';
import '../core/service_locator.dart';

/// Serviço de ocorrências específico para agentes
/// 
/// ETAPA 4: Implementa offline-first com status_sincronizacao e RLS.
class AgentOcorrenciaService with ChangeNotifier {
  final OcorrenciaRepository _ocorrenciaRepository;
  final AgenteRepository _agenteRepository;
  final Box _pendingBox = Hive.box('pending_ocorrencias');
  // final _uuid = const Uuid(); // Será inicializado quando necessário

  List<Ocorrencia> _ocorrencias = [];
  List<Ocorrencia> get ocorrencias => _ocorrencias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int get pendingSyncCount => _pendingBox.length;

  AgentOcorrenciaService({
    required OcorrenciaRepository ocorrenciaRepository,
    required AgenteRepository agenteRepository,
  })  : _ocorrenciaRepository = ocorrenciaRepository,
        _agenteRepository = agenteRepository;

  /// Busca ocorrências do agente com cache offline-first
  Future<void> fetchOcorrencias({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }

      AppLogger.info('Buscando ocorrências do agente');

      // Primeira: busca do cache local
      final cachedOcorrencias = await _loadFromCache();
      if (cachedOcorrencias.isNotEmpty) {
        _ocorrencias = cachedOcorrencias;
        notifyListeners();
        AppLogger.info('${cachedOcorrencias.length} ocorrências carregadas do cache');
      }

      // Segunda: tenta buscar do Supabase
      try {
        final onlineOcorrencias = await _ocorrenciaRepository.fetchAllOcorrencias();
        
        // Filtra apenas as ocorrências do agente (RLS já faz isso, mas garante)
        final agente = await _agenteRepository.getCurrentAgent();
        final filteredOcorrencias = onlineOcorrencias.where((o) => 
          o.municipio == agente?.municipioNome || o.localidade?.contains(agente?.setorNome ?? '') == true
        ).toList();

        // Mescla com ocorrências pendentes localmente
        final mergedOcorrencias = await _mergeWithPending(filteredOcorrencias);
        
        _ocorrencias = mergedOcorrencias;
        notifyListeners();
        
        AppLogger.info('✓ ${mergedOcorrencias.length} ocorrências sincronizadas');

      } on NetworkException catch (e) {
        AppLogger.warning('Sem conectividade, usando cache: $e');
        // Continua com dados do cache
      } catch (e, stackTrace) {
        AppLogger.error('Erro ao buscar ocorrências online', e, stackTrace);
        // Continua com dados do cache
      }

    } catch (e, stackTrace) {
      AppLogger.error('Erro crítico ao buscar ocorrências', e, stackTrace);
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Salva ocorrência com estratégia offline-first
  Future<Ocorrencia> saveOcorrencia(Ocorrencia ocorrencia) async {
    try {
      AppLogger.info('Salvando ocorrência ${ocorrencia.id != null ? "(editando)" : "(nova)"}');

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.contains(ConnectivityResult.mobile) || 
                      connectivity.contains(ConnectivityResult.wifi);

      late Ocorrencia savedOcorrencia;

      if (isOnline) {
        try {
          // Tenta salvar diretamente no Supabase
          if (ocorrencia.id != null) {
            savedOcorrencia = await _ocorrenciaRepository.updateOcorrencia(ocorrencia);
          } else {
            // Adiciona dados do agente atual
            final agente = await _agenteRepository.getCurrentAgent();
            final ocorrenciaWithAgent = ocorrencia.copyWith(
              municipio: agente?.municipioNome,
              localidade: agente?.setorNome,
            );
            savedOcorrencia = await _ocorrenciaRepository.insertOcorrencia(ocorrenciaWithAgent);
          }
          
          AppLogger.info('✓ Ocorrência salva online');
          
        } catch (e) {
          AppLogger.warning('Falha ao salvar online, salvando localmente: $e');
          savedOcorrencia = await _savePending(ocorrencia);
        }
      } else {
        // Salva localmente para sincronização posterior
        savedOcorrencia = await _savePending(ocorrencia);
        AppLogger.info('Ocorrência salva offline para sincronização');
      }

      // Atualiza lista local
      await _updateLocalList(savedOcorrencia);
      
      return savedOcorrencia;

    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar ocorrência', e, stackTrace);
      rethrow;
    }
  }

  /// Sincroniza ocorrências pendentes
  Future<SyncResult> syncPendingOcorrencias() async {
    if (_isSyncing) {
      AppLogger.debug('Sync já em andamento');
      return SyncResult(success: false, message: 'Sincronização já em andamento');
    }

    try {
      _isSyncing = true;
      notifyListeners();

      AppLogger.sync('Iniciando sincronização de ocorrências pendentes');

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.contains(ConnectivityResult.mobile) || 
                      connectivity.contains(ConnectivityResult.wifi);

      if (!isOnline) {
        return SyncResult(success: false, message: 'Sem conexão com a internet');
      }

      final pendingKeys = _pendingBox.keys.toList();
      if (pendingKeys.isEmpty) {
        AppLogger.sync('Nenhuma ocorrência pendente para sincronizar');
        return SyncResult(success: true, message: 'Nenhuma pendência encontrada');
      }

      int successCount = 0;
      int errorCount = 0;

      for (var key in pendingKeys) {
        try {
          final data = Map<String, dynamic>.from(_pendingBox.get(key));
          final ocorrencia = Ocorrencia.fromMap(data);

          // Tenta sincronizar com Supabase
          Ocorrencia synced;
          if (ocorrencia.id != null) {
            synced = await _ocorrenciaRepository.updateOcorrencia(ocorrencia);
          } else {
            synced = await _ocorrenciaRepository.insertOcorrencia(ocorrencia);
          }

          // Remove da fila pendente
          await _pendingBox.delete(key);
          
          // Atualiza na lista local
          await _updateLocalList(synced);
          
          successCount++;
          AppLogger.sync('✓ Ocorrência $key sincronizada');

        } catch (e, stackTrace) {
          AppLogger.error('Erro ao sincronizar ocorrência $key', e, stackTrace);
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
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Carrega ocorrências do cache local
  Future<List<Ocorrencia>> _loadFromCache() async {
    try {
      final cacheBox = ServiceLocator.getNamed<Box>('ocorrencias_cache');
      final cached = cacheBox.values
          .whereType<Map>()
          .map((data) => Ocorrencia.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      
      // Ordena por data mais recente
      cached.sort((a, b) => (b.dataAtividade ?? DateTime(1900)).compareTo(a.dataAtividade ?? DateTime(1900)));
      
      return cached;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar cache de ocorrências', e, stackTrace);
      return [];
    }
  }

  /// Mescla ocorrências online com pendentes localmente
  Future<List<Ocorrencia>> _mergeWithPending(List<Ocorrencia> onlineOcorrencias) async {
    try {
      final pending = _pendingBox.values
          .whereType<Map>()
          .map((data) => Ocorrencia.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      final merged = <String, Ocorrencia>{};
      
      // Adiciona online
      for (var ocorrencia in onlineOcorrencias) {
        if (ocorrencia.id != null) {
          merged[ocorrencia.id!] = ocorrencia;
        }
      }
      
      // Adiciona/sobrescreve pendentes
      for (var ocorrencia in pending) {
        final key = ocorrencia.id ?? ocorrencia.localId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        merged[key] = ocorrencia.copyWith(isPending: true);
      }

      final result = merged.values.toList();
      result.sort((a, b) => (b.dataAtividade ?? DateTime(1900)).compareTo(a.dataAtividade ?? DateTime(1900)));
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao mesclar ocorrências', e, stackTrace);
      return onlineOcorrencias;
    }
  }

  /// Salva ocorrência como pendente
  Future<Ocorrencia> _savePending(Ocorrencia ocorrencia) async {
    final localId = ocorrencia.localId ?? _uuid.v4();
    final pendingOcorrencia = ocorrencia.copyWith(
      localId: localId,
      isPending: true,
    );

    await _pendingBox.put(localId, pendingOcorrencia.toMap());
    return pendingOcorrencia;
  }

  /// Atualiza lista local com ocorrência
  Future<void> _updateLocalList(Ocorrencia ocorrencia) async {
    final key = ocorrencia.id ?? ocorrencia.localId;
    if (key != null) {
      final index = _ocorrencias.indexWhere((o) => (o.id ?? o.localId) == key);
      
      if (index != -1) {
        _ocorrencias[index] = ocorrencia;
      } else {
        _ocorrencias.insert(0, ocorrencia);
      }
      
      // Reordena
      _ocorrencias.sort((a, b) => (b.dataAtividade ?? DateTime(1900)).compareTo(a.dataAtividade ?? DateTime(1900)));
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Force refresh
  Future<void> forceRefresh() async {
    AppLogger.info('Force refresh de ocorrências solicitado');
    await fetchOcorrencias(showLoading: true);
  }
}

/// Resultado de sincronização
class SyncResult {
  final bool success;
  final String message;

  SyncResult({required this.success, required this.message});
}
