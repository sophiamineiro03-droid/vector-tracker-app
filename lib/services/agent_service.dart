import 'package:flutter/foundation.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/sync_result.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/repositories/denuncia_repository.dart';
import 'package:vector_tracker_app/repositories/ocorrencia_repository.dart';

class AgentService extends ChangeNotifier {
  final AgenteRepository _agenteRepository;
  final OcorrenciaRepository _ocorrenciaRepository;
  final DenunciaRepository _denunciaRepository;

  AgentService({
    required AgenteRepository agenteRepository,
    required OcorrenciaRepository ocorrenciaRepository,
    required DenunciaRepository denunciaRepository,
  })  : _agenteRepository = agenteRepository,
        _ocorrenciaRepository = ocorrenciaRepository,
        _denunciaRepository = denunciaRepository;

  // ... (getters e setters permanecem os mesmos)
  bool _isLoading = true, _isSyncing = false, _isOcorrenciasLoading = false, _isPendenciasLoading = false;
  Map<String, int> _stats = {};
  String _agentName = '';
  Agente? _currentAgent;
  List<Ocorrencia> _minhasOcorrencias = [];
  List<Denuncia> _pendencias = [];

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isOcorrenciasLoading => _isOcorrenciasLoading;
  bool get isPendenciasLoading => _isPendenciasLoading;
  Map<String, int> get stats => _stats;
  String get agentName => _agentName;
  Agente? get currentAgent => _currentAgent;
  List<Ocorrencia> get minhasOcorrencias => _minhasOcorrencias;
  List<Denuncia> get pendencias => _pendencias;
  
  // ... (funções de loading, sync, etc. permanecem as mesmas)
  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void _setSyncing(bool value) { _isSyncing = value; notifyListeners(); }

  Future<bool> loadAgentData() async {
    try {
      _setLoading(true);
      _currentAgent = await _agenteRepository.getCurrentAgent();
      if (_currentAgent == null) {
        _agentName = '';
        _stats = {};
        return true;
      }
      final agentStats = await _agenteRepository.getAgentStatistics();
      _agentName = _currentAgent!.nome;
      _stats = agentStats;
      return true;
    } catch (e, s) {
      AppLogger.error('Erro ao carregar dados do agente', e, s);
      _currentAgent = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getPendencias() async {
    try {
      _isPendenciasLoading = true;
      notifyListeners();
      _pendencias = await _denunciaRepository.fetchAllDenuncias();
    } catch (e, s) {
      AppLogger.error('Erro ao buscar todas as pendências', e, s);
      _pendencias = [];
    } finally {
      _isPendenciasLoading = false;
      notifyListeners();
    }
  }

  // CORRIGIDO: Agora busca todas as ocorrências.
  Future<void> getMeuTrabalho() async {
    try {
      _isOcorrenciasLoading = true;
      notifyListeners();
      // Lógica corrigida: busca todas as ocorrências, sem filtro de agente.
      _minhasOcorrencias = await _ocorrenciaRepository.fetchAllOcorrencias();
    } catch (e, s) {
      AppLogger.error('Erro ao buscar todas as ocorrências', e, s);
      _minhasOcorrencias = [];
    } finally {
      _isOcorrenciasLoading = false;
      notifyListeners();
    }
  }

  Future<void> criarOcorrencia(Ocorrencia ocorrencia) async {
    await _ocorrenciaRepository.salvarOcorrencia(ocorrencia);
    await getMeuTrabalho(); 
  }

  Future<void> editarOcorrencia(Ocorrencia ocorrencia) async {
    await _ocorrenciaRepository.atualizarOcorrencia(ocorrencia);
    await getMeuTrabalho();
  }

  Future<void> vincularDenuncia(Ocorrencia ocorrencia, Denuncia denuncia) async {
    await _ocorrenciaRepository.associarDenuncia(ocorrencia, denuncia);
     await getPendencias();
  }

  Future<SyncResult> performSync() async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sincronização já em andamento.');
    SyncResult result;
    try {
      _setSyncing(true);
      result = await _ocorrenciaRepository.syncPendingOcorrencias();
      if (result.success) {
        await loadAgentData();
        await getMeuTrabalho();
        await getPendencias();
      }
    } catch (e, s) {
      AppLogger.error('Erro na sincronização', e, s);
      result = SyncResult(success: false, message: 'Erro: $e');
    } finally {
      _setSyncing(false);
    }
    return result;
  }

  Future<Agente?> getPerfil() async {
    _currentAgent ??= await _agenteRepository.getCurrentAgent();
    return _currentAgent;
  }

  Future<void> atualizarPerfil(Agente agente) async {
    await _agenteRepository.atualizarAgente(agente);
    await loadAgentData();
  }
}
