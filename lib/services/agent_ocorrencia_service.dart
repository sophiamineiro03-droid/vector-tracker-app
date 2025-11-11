import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
      print('Erro ao buscar ocorrências: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forceRefresh() async {
    _setLoading(true);
    try {
      _ocorrencias = await _ocorrenciaRepository.fetchAllOcorrenciasFromSupabase();
    } catch (e) {
      print('Erro ao forçar atualização: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveOcorrencia(Ocorrencia ocorrencia) async {
    _setLoading(true);
    try {
      final agente = await _agenteRepository.getCurrentAgent();
      if (agente == null) throw Exception('Agente não identificado.');

      var ocorrenciaToSave = ocorrencia.copyWith(agente_id: agente.id);

      final List<String> novasUrls = [];
      if (ocorrencia.localImagePaths != null) {
        for (var imagePath in ocorrencia.localImagePaths!) {
          if (!imagePath.startsWith('http')) {
            final imageUrl = await _uploadImage(imagePath);
            if (imageUrl != null) novasUrls.add(imageUrl);
          }
        }
      }

      final todasAsUrls = [...?ocorrencia.fotos_urls, ...novasUrls];
      ocorrenciaToSave = ocorrenciaToSave.copyWith(fotos_urls: todasAsUrls, sincronizado: true);

      await _ocorrenciaRepository.insertInSupabase(ocorrenciaToSave);

    } catch (e) {
      print('Falha ao salvar online, salvando localmente: $e');
      await _ocorrenciaRepository.saveToPendingBox(ocorrencia.copyWith(sincronizado: false));
    } finally {
      await fetchOcorrencias();
      _setLoading(false);
    }
  }

  Future<String?> _uploadImage(String filePath) async {
    final file = File(filePath);
    final fileName = '${const Uuid().v4()}.${filePath.split('.').last}';

    try {
      await _supabase.storage.from('fotos-ocorrencias').upload(fileName, file);
      return _supabase.storage.from('fotos-ocorrencias').getPublicUrl(fileName);
    } catch (e) {
      print('Erro no upload da imagem: $e');
      return null;
    }
  }

  Future<String> syncPendingOcorrencias() async {
    if (_isSyncing) return "Sincronização já em andamento.";

    _setSyncing(true);
    final pending = await _ocorrenciaRepository.getFromPendingBox();
    if (pending.isEmpty) {
      _setSyncing(false);
      return "Nenhuma ocorrência pendente para sincronizar.";
    }

    int successCount = 0;
    for (var ocorrencia in pending) {
      try {
        await saveOcorrencia(ocorrencia);
        await _ocorrenciaRepository.deleteFromPendingBox(ocorrencia.id);
        successCount++;
      } catch (e) {
        print('Erro ao sincronizar ocorrência ${ocorrencia.id}: $e');
      }
    }
    
    _setSyncing(false);
    await fetchOcorrencias();

    if (successCount == pending.length) {
      return "Todas as ${pending.length} ocorrências pendentes foram sincronizadas com sucesso!";
    } else {
      return "Sincronização concluída. $successCount de ${pending.length} ocorrências foram sincronizadas.";
    }
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
