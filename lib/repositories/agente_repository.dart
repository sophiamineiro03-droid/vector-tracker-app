import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:hive/hive.dart';

class AgenteRepository {
  final SupabaseClient _supabase;
  final Box _cacheBox;
  Agente? _cachedAgent;

  AgenteRepository(this._supabase, this._cacheBox);

  Future<Agente?> getCurrentAgent({bool forceRefresh = false}) async {
    if (_cachedAgent != null && !forceRefresh) {
      return _cachedAgent;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Tenta recuperar do cache mesmo se o currentUser do Supabase estiver null (pode acontecer offline)
      // Mas cuidado: só faz sentido se tivermos certeza que era esse usuário.
      // Por segurança, vamos verificar o cache.
      final cachedMap = _cacheBox.get('current_agent');
      if (cachedMap != null) {
         final map = Map<String, dynamic>.from(cachedMap);
         final agenteCache = Agente.fromMap(map);
         _cachedAgent = agenteCache;
         return agenteCache;
      }
      return null;
    }

    try {
      final response = await _supabase
          .from('agentes')
          .select('*, municipios(nome), agentes_localidades!inner(localidades(id, nome, codigo, categoria))')
          .eq('user_id', user.id)
          .single();

      final agente = Agente.fromMap(response);
      
      // Salva no Cache
      await _cacheBox.put('current_agent', agente.toMap());
      
      _cachedAgent = agente;
      return agente;
    } catch (e) {
      print('Erro ao buscar agente online: $e. Tentando cache...');
      
      // Fallback para Cache
      final cachedMap = _cacheBox.get('current_agent');
      if (cachedMap != null) {
         final map = Map<String, dynamic>.from(cachedMap);
         final agenteCache = Agente.fromMap(map);
         
         // Verifica se o agente do cache pertence ao usuário logado (se tiver internet parcial)
         if (user.id == agenteCache.userId) {
             _cachedAgent = agenteCache;
             return agenteCache;
         }
      }
      
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

      // Atualiza cache se já estiver carregado
      if (_cachedAgent != null) {
         final novoAgente = _cachedAgent!.copyWith(avatarUrl: publicUrl);
         _cachedAgent = novoAgente;
         await _cacheBox.put('current_agent', novoAgente.toMap());
      } else {
         _cachedAgent = null; 
      }

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

    if (newEmail.toLowerCase() != user.email?.toLowerCase()) {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    }

    await _supabase.from('agentes').update({'nome': newName}).eq('user_id', user.id);

    _cachedAgent = null; // Força refresh
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> clearAgentOnLogout() async {
    _cachedAgent = null;
    await _cacheBox.delete('current_agent');
    await _supabase.auth.signOut();
  }
}
