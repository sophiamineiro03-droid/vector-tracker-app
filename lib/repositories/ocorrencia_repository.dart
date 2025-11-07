import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';

/// O Repositório de Ocorrências é a única fonte da verdade para os dados de ocorrência,
/// abstraindo a origem dos dados (Supabase, Cache, Caixa de Pendências).
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

  /// Busca todas as ocorrências da nuvem (Supabase).
  Future<List<Ocorrencia>> fetchAllOcorrenciasFromSupabase() async {
    try {
      AppLogger.info('Buscando todas as ocorrências do Supabase');
      final response = await supabase.from('ocorrencias').select();

      final ocorrencias = (response as List)
          .map((item) => Ocorrencia.fromMap(item as Map<String, dynamic>))
          .toList();

      AppLogger.info('${ocorrencias.length} ocorrências encontradas na nuvem.');
      // Atualiza o cache local com os dados frescos da nuvem.
      await _cacheBox.clear();
      for (var oc in ocorrencias) {
        await _cacheBox.put(oc.id, oc.toMap());
      }
      return ocorrencias;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar ocorrências do Supabase', e, stackTrace);
      rethrow; // Propaga o erro para o serviço tratar.
    }
  }

  /// Busca ocorrências do cache local.
  Future<List<Ocorrencia>> getOcorrenciasFromCache() async {
    AppLogger.info('Carregando ocorrências do cache local.');
    return _cacheBox.values
        .map((item) => Ocorrencia.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Insere uma nova ocorrência diretamente na nuvem (Supabase).
  Future<Ocorrencia> insertInSupabase(Ocorrencia ocorrencia) async {
    AppLogger.info('Inserindo ocorrência no Supabase: ${ocorrencia.id}');
    final response = await supabase
        .from('ocorrencias')
        .insert(ocorrencia.toMap())
        .select()
        .single();
    return Ocorrencia.fromMap(response);
  }

  /// Atualiza uma ocorrência existente na nuvem (Supabase).
  Future<Ocorrencia> updateInSupabase(Ocorrencia ocorrencia) async {
    AppLogger.info('Atualizando ocorrência no Supabase: ${ocorrencia.id}');
    final response = await supabase
        .from('ocorrencias')
        .update(ocorrencia.toMap())
        .eq('id', ocorrencia.id)
        .select()
        .single();
    return Ocorrencia.fromMap(response);
  }

  /// Salva uma ocorrência na caixa de pendências para sincronização futura.
  Future<void> saveToPendingBox(Ocorrencia ocorrencia) async {
    AppLogger.info('Salvando ocorrência na caixa de pendências: ${ocorrencia.id}');
    await _pendingBox.put(ocorrencia.id, ocorrencia.toMap());
  }

  /// Retorna todas as ocorrências da caixa de pendências.
  Future<List<Ocorrencia>> getFromPendingBox() async {
    return _pendingBox.values
        .map((item) => Ocorrencia.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Remove uma ocorrência da caixa de pendências após a sincronização.
  Future<void> deleteFromPendingBox(String id) async {
    AppLogger.info('Removendo ocorrência da caixa de pendências: $id');
    await _pendingBox.delete(id);
  }
}