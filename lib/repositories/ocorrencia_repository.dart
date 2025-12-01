import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';

class OcorrenciaRepository {
  final SupabaseClient supabase;
  final Box _cacheBox;
  final Box _pendingBox;

  OcorrenciaRepository({
    required this.supabase,
    required Box cacheBox,
    required Box pendingBox,
  })  : _cacheBox = cacheBox,
        _pendingBox = pendingBox;

  Future<List<Ocorrencia>> fetchOcorrenciasByAgenteFromSupabase(
      String agenteId) async {
    try {
      // CORREÇÃO CRÍTICA: Removi o '!inner'.
      // Agora ele traz a ocorrência mesmo se 'localidades' for nulo (manual).
      final response = await supabase
          .from('ocorrencias')
          .select('*, localidades(municipios(nome))') // << MUDOU AQUI (Tiramos o !inner)
          .eq('agente_id', agenteId);

      final ocorrencias = (response as List)
          .map((item) => Ocorrencia.fromMap(item as Map<String, dynamic>).copyWith(sincronizado: true))
          .toList();

      await _cacheBox.clear();
      for (var oc in ocorrencias) {
        await _cacheBox.put(oc.id, oc.toLocalMap());
      }
      return ocorrencias;
    } catch (e) {
      print('Erro ao buscar ocorrências do Supabase: $e');
      rethrow;
    }
  }

  Future<List<Ocorrencia>> getOcorrenciasFromCache() async {
    return _cacheBox.values
        .map((item) => Ocorrencia.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Ocorrencia> insertInSupabase(Ocorrencia ocorrencia) async {
    final response = await supabase
        .from('ocorrencias')
        .insert(ocorrencia.toMap())
        .select()
        .single();
    return Ocorrencia.fromMap(response).copyWith(sincronizado: true);
  }

  Future<Ocorrencia> updateInSupabase(Ocorrencia ocorrencia) async {
    final response = await supabase
        .from('ocorrencias')
        .update(ocorrencia.toMap())
        .eq('id', ocorrencia.id)
        .select()
        .single();
    return Ocorrencia.fromMap(response).copyWith(sincronizado: true);
  }

  // === NOVO MÉTODO ===
  Future<void> saveToCache(Ocorrencia ocorrencia) async {
    await _cacheBox.put(ocorrencia.id, ocorrencia.toLocalMap());
  }

  Future<void> saveToPendingBox(Ocorrencia ocorrencia) async {
    // CORREÇÃO: Usar toLocalMap para persistir caminhos de imagens locais e outros dados offline
    await _pendingBox.put(ocorrencia.id, ocorrencia.toLocalMap());
  }

  Future<List<Ocorrencia>> getFromPendingBox() async {
    return _pendingBox.values
        .map((item) => Ocorrencia.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> deleteFromPendingBox(String id) async {
    await _pendingBox.delete(id);
  }
}
