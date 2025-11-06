import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vector_tracker_app/models/ocorrencia_siocchagas.dart';
import 'package:vector_tracker_app/core/app_logger.dart';

class OcorrenciaSiocchagasService with ChangeNotifier {
  late Box<OcorrenciaSiocchagas> _box;

  OcorrenciaSiocchagasService() {
    _init();
  }

  List<OcorrenciaSiocchagas> _ocorrencias = [];

  List<OcorrenciaSiocchagas> get todasOcorrencias => _ocorrencias;

  List<OcorrenciaSiocchagas> get pendentesSincronizacao {
    return _ocorrencias
        .where((o) => o.status_envio == 'Local (Pendente de Sinc.)')
        .toList();
  }

  List<OcorrenciaSiocchagas> get meuTrabalho {
    return _ocorrencias
        .where((o) => o.status_envio == 'Enviada (Sincronizada)')
        .toList();
  }

  Future<void> _init() async {
    _box = Hive.box<OcorrenciaSiocchagas>('ocorrencias_siocchagas');
    _loadOcorrencias();
    _box.watch().listen((event) {
      _loadOcorrencias();
    });
  }

  void _loadOcorrencias() {
    _ocorrencias = _box.values.toList();
    // Ordena para mostrar as mais recentes primeiro
    _ocorrencias.sort((a, b) => (b.data_atividade ?? DateTime(1900))
        .compareTo(a.data_atividade ?? DateTime(1900)));
    AppLogger.info('Ocorrências SIOCCHAGAS carregadas: ${_ocorrencias.length}');
    notifyListeners();
  }

  Future<void> saveOcorrencia(OcorrenciaSiocchagas ocorrencia) async {
    try {
      await _box.put(ocorrencia.localId, ocorrencia);
      AppLogger.info('Ocorrência salva localmente: ${ocorrencia.localId}');
    } catch (e, s) {
      AppLogger.error('Erro ao salvar ocorrência localmente', e, s);
      rethrow;
    }
  }

  OcorrenciaSiocchagas? getOcorrenciaByDenunciaId(String denunciaId) {
    try {
      return _ocorrencias.firstWhere((o) => o.denuncia_id == denunciaId);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
}
