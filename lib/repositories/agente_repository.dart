import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/models/agente.dart';

class AgenteRepository {
  final SupabaseClient _supabase;

  // ---1. A "MEMÓRIA" DO AGENTE ---
  // Variável privada para guardar o agente logado após a primeira busca.
  Agente? _cachedAgent;

  AgenteRepository(this._supabase);

  // --- 2. MÉTODO CORRIGIDO COM CACHE ---
  Future<Agente?> getCurrentAgent() async {
    // Se já temos o agente na memória, retorna imediatamente.
    if (_cachedAgent != null) {
      return _cachedAgent;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      print('Nenhum usuário logado. Retornando null.');
      return null;
    }

    try {
      print('Buscando dados do agente logado da REDE: ${user.id}');
      final response = await _supabase
          .from('agentes')
          .select('*, municipios(nome), agentes_localidades!inner(localidades(id, nome, codigo, categoria))')
          .eq('user_id', user.id)
          .single();

      final agente = Agente.fromMap(response);

      // --- 3. SALVA NA MEMÓRIA ANTES DE RETORNAR ---
      // Guarda o agente encontrado no cache para as próximas vezes.
      _cachedAgent = agente;

      return agente;
    } catch (e) {
      print('Erro ao buscar dados do agente logado: $e');
      return null;
    }
  }

  // --- 4. MÉTODO PARA LIMPAR A MEMÓRIA NO LOGOUT ---
  Future<void> clearAgentOnLogout() async {
    _cachedAgent = null;
    await _supabase.auth.signOut();
  }
}