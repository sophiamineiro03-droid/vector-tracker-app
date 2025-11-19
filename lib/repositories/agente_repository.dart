import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/models/agente.dart';

class AgenteRepository {
  final SupabaseClient _supabase;
  Agente? _cachedAgent;

  AgenteRepository(this._supabase);

  Future<Agente?> getCurrentAgent({bool forceRefresh = false}) async {
    if (_cachedAgent != null && !forceRefresh) {
      return _cachedAgent;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final response = await _supabase
          .from('agentes')
          .select('*, municipios(nome), agentes_localidades!inner(localidades(id, nome, codigo, categoria))')
          .eq('user_id', user.id)
          .single();

      final agente = Agente.fromMap(response);
      _cachedAgent = agente;
      return agente;
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado para fazer upload.');
    }

    try {
      final fileName = '${user.id}.${imageFile.path.split('.').last}';

      await _supabase.storage.from('profile_pictures').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _supabase.storage.from('profile_pictures').getPublicUrl(fileName);

      await _supabase.from('agentes').update({'avatar_url': publicUrl}).eq('user_id', user.id);

      _cachedAgent = null;

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAgentProfile({required String newName, required String newEmail}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    // Atualiza o e-mail na autenticação do Supabase
    if (newEmail.toLowerCase() != user.email?.toLowerCase()) {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    }

    // Atualiza o nome na tabela de agentes
    await _supabase.from('agentes').update({'nome': newName}).eq('user_id', user.id);

    _cachedAgent = null; // Limpa o cache para forçar a atualização
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> clearAgentOnLogout() async {
    _cachedAgent = null;
    await _supabase.auth.signOut();
  }
}
