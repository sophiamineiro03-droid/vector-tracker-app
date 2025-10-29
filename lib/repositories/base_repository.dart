import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import '../core/exceptions.dart';

/// Repository base com operações comuns de CRUD
/// 
/// ETAPA 2: Padrão Repository implementado para separar lógica de acesso a dados.
abstract class BaseRepository {
  final SupabaseClient _supabase;
  final Box _cacheBox;
  final String _tableName;

  BaseRepository({
    required SupabaseClient supabase,
    required Box cacheBox,
    required String tableName,
  })  : _supabase = supabase,
        _cacheBox = cacheBox,
        _tableName = tableName;

  /// Fetch all items from Supabase
  Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      AppLogger.database('Fetching all from $_tableName');
      
      final data = await _supabase.from(_tableName).select();
      final items = data as List;
      
      // Atualiza cache local
      await _cacheBox.clear();
      for (var item in items) {
        await _cacheBox.put(item['id'], item);
      }
      
      AppLogger.database('Fetched ${items.length} items from $_tableName');
      return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.error('Supabase error fetching $_tableName', e, stackTrace);
      throw SupabaseException('Erro ao buscar dados: ${e.message}', originalError: e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error fetching $_tableName', e, stackTrace);
      
      // Fallback para cache local
      AppLogger.warning('Using cache data for $_tableName');
      final cachedData = _cacheBox.values.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();
      return cachedData;
    }
  }

  /// Fetch a single item by ID
  Future<Map<String, dynamic>?> fetchById(dynamic id) async {
    try {
      AppLogger.database('Fetching $_tableName by id: $id');
      
      final data = await _supabase.from(_tableName).select().eq('id', id).maybeSingle();
      
      if (data != null) {
        final item = Map<String, dynamic>.from(data as Map);
        await _cacheBox.put(id, item);
        AppLogger.database('Fetched item $id from $_tableName');
      }
      
      return data != null ? Map<String, dynamic>.from(data as Map) : null;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching $_tableName by id', e, stackTrace);
      
      // Fallback para cache
      final cached = _cacheBox.get(id);
      return cached != null ? Map<String, dynamic>.from(cached as Map) : null;
    }
  }

  /// Insert a new item
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    try {
      AppLogger.database('Inserting into $_tableName');
      
      // Remove campos internos
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('local_id');
      cleanData.remove('is_pending');
      cleanData.remove('is_ocorrencia');
      
      final result = await _supabase
          .from(_tableName)
          .insert(cleanData)
          .select()
          .single();
      
      final insertedItem = Map<String, dynamic>.from(result as Map);
      await _cacheBox.put(insertedItem['id'], insertedItem);
      
      AppLogger.database('Inserted into $_tableName with id: ${insertedItem['id']}');
      return insertedItem;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error inserting into $_tableName', e, stackTrace);
      throw SupabaseException('Erro ao inserir dados: $e', originalError: e);
    }
  }

  /// Update an existing item
  Future<Map<String, dynamic>> update(dynamic id, Map<String, dynamic> data) async {
    try {
      AppLogger.database('Updating $_tableName id: $id');
      
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('local_id');
      cleanData.remove('is_pending');
      
      final result = await _supabase
          .from(_tableName)
          .update(cleanData)
          .eq('id', id)
          .select()
          .single();
      
      final updatedItem = Map<String, dynamic>.from(result as Map);
      await _cacheBox.put(id, updatedItem);
      
      AppLogger.database('Updated $_tableName id: $id');
      return updatedItem;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error updating $_tableName', e, stackTrace);
      throw SupabaseException('Erro ao atualizar dados: $e', originalError: e);
    }
  }

  /// Delete an item
  Future<void> delete(dynamic id) async {
    try {
      AppLogger.database('Deleting $_tableName id: $id');
      
      await _supabase.from(_tableName).delete().eq('id', id);
      await _cacheBox.delete(id);
      
      AppLogger.database('Deleted $_tableName id: $id');
      
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting $_tableName', e, stackTrace);
      throw SupabaseException('Erro ao deletar dados: $e', originalError: e);
    }
  }

  /// Get cache box for custom operations
  Box get cacheBox => _cacheBox;
  
  /// Get Supabase client for custom operations
  SupabaseClient get supabase => _supabase;
}


