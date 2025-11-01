import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/denuncia.dart';
import '../core/app_logger.dart';
import '../core/exceptions.dart';
import 'base_repository.dart';

/// Repository para operações com denúncias
/// 
/// ETAPA 2: Implementação do padrão Repository para separar lógica de acesso a dados.
class DenunciaRepository extends BaseRepository {
  DenunciaRepository({
    required SupabaseClient supabase,
    required Box cacheBox,
  }) : super(
          supabase: supabase,
          cacheBox: cacheBox,
          tableName: 'denuncias',
        );

  /// Fetch all denuncias
  Future<List<Denuncia>> fetchAllDenuncias() async {
    try {
      AppLogger.database('Fetching all denuncias');
      final data = await fetchAll();
      return data.map((map) => Denuncia.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching all denuncias', e, stackTrace);
      rethrow;
    }
  }

  /// Fetch denuncia by ID
  Future<Denuncia?> fetchDenunciaById(String id) async {
    try {
      AppLogger.database('Fetching denuncia id: $id');
      final data = await fetchById(id);
      return data != null ? Denuncia.fromMap(data) : null;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching denuncia by id', e, stackTrace);
      rethrow;
    }
  }

  /// Insert a new denuncia
  Future<Denuncia> insertDenuncia(Denuncia denuncia) async {
    try {
      AppLogger.database('Inserting new denuncia');
      
      final data = denuncia.toMap();
      final result = await insert(data);
      
      return Denuncia.fromMap(result);
    } catch (e, stackTrace) {
      AppLogger.error('Error inserting denuncia', e, stackTrace);
      throw SupabaseException('Erro ao inserir denúncia', originalError: e);
    }
  }

  /// Update an existing denuncia
  Future<Denuncia> updateDenuncia(Denuncia denuncia) async {
    try {
      if (denuncia.id == null) {
        throw ValidationException('ID da denúncia não pode ser nulo para atualização');
      }
      
      AppLogger.database('Updating denuncia id: ${denuncia.id}');
      
      final data = denuncia.toMap();
      final result = await update(denuncia.id!, data);
      
      return Denuncia.fromMap(result);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating denuncia', e, stackTrace);
      
      if (e is ValidationException) rethrow;
      throw SupabaseException('Erro ao atualizar denúncia', originalError: e);
    }
  }

  /// Delete a denuncia
  Future<void> deleteDenuncia(String id) async {
    try {
      AppLogger.database('Deleting denuncia id: $id');
      await delete(id);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting denuncia', e, stackTrace);
      throw SupabaseException('Erro ao deletar denúncia', originalError: e);
    }
  }

  /// Get pending denuncias from local Hive
  List<Map<String, dynamic>> getPendingDenuncias(Box pendingBox) {
    try {
      AppLogger.sync('Getting pending denuncias from local cache');
      return pendingBox.values
          .whereType<Map>()
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting pending denuncias', e, stackTrace);
      return [];
    }
  }

  /// Store pending denuncia locally
  Future<void> storePendingDenuncia(Box pendingBox, Map<String, dynamic> denuncia) async {
    try {
      AppLogger.sync('Storing pending denuncia with local_id: ${denuncia['local_id']}');
      await pendingBox.put(denuncia['local_id'] ?? denuncia['id'], denuncia);
    } catch (e, stackTrace) {
      AppLogger.error('Error storing pending denuncia', e, stackTrace);
      throw LocalDatabaseException('Erro ao armazenar denúncia localmente', originalError: e);
    }
  }

  /// Remove pending denuncia after successful sync
  Future<void> removePendingDenuncia(Box pendingBox, dynamic key) async {
    try {
      AppLogger.sync('Removing pending denuncia: $key');
      await pendingBox.delete(key);
    } catch (e, stackTrace) {
      AppLogger.error('Error removing pending denuncia', e, stackTrace);
      throw LocalDatabaseException('Erro ao remover denúncia pendente', originalError: e);
    }
  }
}


