import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/sync_result.dart';

class OcorrenciaRepository {
  final SupabaseClient supabase;
  final Box cacheBox;

  OcorrenciaRepository({required this.supabase, required this.cacheBox});

  // NOVO: Busca todas as ocorrências sem filtro.
  Future<List<Ocorrencia>> fetchAllOcorrencias() async {
    try {
      AppLogger.info('Buscando todas as ocorrências do Supabase');
      
      final response = await supabase.from('ocorrencias').select();

      final ocorrencias = (response as List)
          .map((item) => Ocorrencia.fromMap(item as Map<String, dynamic>))
          .toList();

      AppLogger.info('${ocorrencias.length} ocorrências encontradas.');
      return ocorrencias;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar todas as ocorrências', e, stackTrace);
      return [];
    }
  }

  Future<void> salvarOcorrencia(Ocorrencia ocorrencia) async {
    AppLogger.info('Salvando ocorrência no Hive: ${ocorrencia.id}');
    final box = Hive.box('pending_ocorrencias');
    await box.put(ocorrencia.id, ocorrencia.toMap());
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    AppLogger.info('Atualizando ocorrência no Hive: ${ocorrencia.id}');
    final box = Hive.box('pending_ocorrencias');
    await box.put(ocorrencia.id, ocorrencia.toMap());
  }
  
  // A lógica abaixo será mantida por enquanto, mas não será usada no fluxo principal de teste.

  Future<List<Denuncia>> buscarDenunciasPendentesPorSetor(String setorId) async {
    try {
      final response = await supabase.from('denuncias').select().eq('setor_id', setorId).eq('status', 'pendente');
      return (response as List).map((item) => Denuncia.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar denúncias pendentes por setor', e, stackTrace);
      return [];
    }
  }

  Future<void> associarDenuncia(Ocorrencia ocorrencia, Denuncia denuncia) async {
    AppLogger.info('Associando denúncia ${denuncia.id} à ocorrência ${ocorrencia.id}');
  }

  Future<List<Ocorrencia>> buscarOcorrenciasDoAgente(String agenteId) async {
    AppLogger.info('Buscando ocorrências para o agente (desativado em modo de teste): $agenteId');
    return [];
  }

  Future<SyncResult> syncPendingOcorrencias() async {
    AppLogger.info('Sincronizando ocorrências pendentes...');
    return SyncResult(success: true, message: 'Sincronização simulada com sucesso!');
  }
}
