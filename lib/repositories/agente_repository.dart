import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/repositories/base_repository.dart';
import '../models/agente.dart';
import '../core/app_logger.dart';
import '../core/exceptions.dart';

class AgenteRepository {
  final SupabaseClient supabase;
  final Box cacheBox;

  AgenteRepository({
    required this.supabase,
    required this.cacheBox,
  });

  Future<Agente?> getCurrentAgent() async {
    try {
      AppLogger.info('Buscando agente padrão para modo de teste');

      // Lógica simplificada: Busca o PRIMEIRO agente da tabela, ignorando auth.
      final data = await supabase
          .from('agentes')
          .select('''
            id, nome, email, telefone, cargo, ativo, created_at,
            municipio_id, setor_id,
            municipios(nome, codigo_ibge),
            setores(nome)
          ''')
          .limit(1)
          .maybeSingle();

      if (data == null) {
        AppLogger.warning('Nenhum agente encontrado na tabela `agentes` para o modo de teste.');
        return null;
      }

      final agente = Agente.fromMap(data);
      
      await cacheBox.put('current_agent', data);
      
      AppLogger.info('✓ Agente de teste carregado: ${agente.nome}');
      return agente;

    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar agente de teste', e, stackTrace);
      final cached = cacheBox.get('current_agent');
      if (cached != null) {
        return Agente.fromMap(Map<String, dynamic>.from(cached));
      }
      rethrow;
    }
  }

  Future<void> atualizarAgente(Agente agente) async {
    // A lógica de atualização permanece a mesma, baseada no ID do objeto agente.
    await supabase
      .from('agentes')
      .update({
        'nome': agente.nome,
        'telefone': agente.telefone,
        'cargo': agente.cargo,
      })
      .eq('id', agente.id);
  }

  Future<Map<String, int>> getAgentStatistics() async {
    try {
      AppLogger.info('Buscando estatísticas do agente de teste');
      
      // Carrega o agente de teste para obter seu ID e município
      final agent = await getCurrentAgent();
      if (agent == null) {
        AppLogger.warning('Nenhum agente de teste encontrado para buscar estatísticas.');
        return {'total_ocorrencias': 0, 'pendentes_sync': 0, 'denuncias_municipio': 0};
      }

      final results = await Future.wait([
        supabase.from('ocorrencias').select('id').eq('agente_id', agent.id),
        supabase.from('ocorrencias').select('id').eq('agente_id', agent.id), // Simplificado: contagem total
        supabase.from('denuncias').select('id').eq('municipio_id', agent.municipioId ?? ''),
      ]);

      final stats = {
        'total_ocorrencias': (results[0] as List).length,
        'pendentes_sync': (results[1] as List).length, // Esta estatística pode não ser precisa sem status local
        'denuncias_municipio': (results[2] as List).length,
      };

      AppLogger.info('✓ Estatísticas obtidas: $stats');
      return stats;

    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar estatísticas', e, stackTrace);
      return {'total_ocorrencias': 0, 'pendentes_sync': 0, 'denuncias_municipio': 0};
    }
  }

  Future<void> clearCache() async {
    try {
      AppLogger.info('Limpando cache do agente');
      await cacheBox.delete('current_agent');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao limpar cache do agente', e, stackTrace);
    }
  }
}
