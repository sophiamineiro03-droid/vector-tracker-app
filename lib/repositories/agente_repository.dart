import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/models/agente.dart';

class AgenteRepository {
  final SupabaseClient _supabase;

  AgenteRepository(this._supabase);

  Future<Agente?> getCurrentAgent() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      print('Nenhum usuário logado. Retornando null.');
      return null;
    }

    try {
      print('Buscando dados do agente logado: ${user.id}');
      final response = await _supabase
          .from('agentes')
          // Este select agora busca o nome do município e os nomes das localidades associadas
          .select('*, municipios(nome), agentes_localidades!inner(localidades(nome))')
          .eq('user_id', user.id)
          .single();

      return Agente.fromMap(response);
    } catch (e) {
      print('Erro ao buscar dados do agente logado: $e');
      return null;
    }
  }
}
