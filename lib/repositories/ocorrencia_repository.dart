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
      // LINHA CORRIGIDA:
      final response = await supabase
          .from('ocorrencias')
          .select('*, localidades!inner(municipios!inner(nome))')
          .eq('agente_id', agenteId);

      final ocorrencias = (response as List)
          .map((item) => Ocorrencia.fromMap(item as Map<String, dynamic>))
          .toList();

      await _cacheBox.clear();
      for (var oc in ocorrencias) {
        await _cacheBox.put(oc.id, oc.toMap());
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
    return Ocorrencia.fromMap(response);
  }

  Future<Ocorrencia> updateInSupabase(Ocorrencia ocorrencia) async {
    final response = await supabase
        .from('ocorrencias')
        .update(ocorrencia.toMap())
        .eq('id', ocorrencia.id)
        .select()
        .single();
    return Ocorrencia.fromMap(response);
  }

  Future<void> saveToPendingBox(Ocorrencia ocorrencia) async {
    await _pendingBox.put(ocorrencia.id, ocorrencia.toMap());
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