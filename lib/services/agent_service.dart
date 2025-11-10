
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:vector_tracker_app/core/service_locator.dart';

class AgentService {
  final SupabaseClient _supabase = ServiceLocator.get<SupabaseClient>();

  Future<List<Agente>> getAgentes() async {
    try {
      AppLogger.info('Buscando agentes no Supabase');
      final response = await _supabase.from('agentes').select();

      final List<Agente> agentes = (response as List)
          .map((json) => Agente.fromMap(json))
          .toList();

      AppLogger.info('✓ ${agentes.length} agentes encontrados');
      return agentes;
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar agentes no Supabase', e, stackTrace);
      // Aqui você poderia adicionar um fallback para o cache do Hive
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Erro inesperado ao buscar agentes', e, stackTrace);
      rethrow;
    }
  }
}
