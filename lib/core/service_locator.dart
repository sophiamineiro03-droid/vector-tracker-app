import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/repositories/denuncia_repository.dart';
import 'package:vector_tracker_app/repositories/ocorrencia_repository.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import '../services/denuncia_service.dart';
import '../services/hive_sync_service.dart';
import '../services/agent_service.dart';
import 'package:hive/hive.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  static Future<void> setup() async {
    _getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

    // Registra os boxes para os repositórios antigos
    if (!_getIt.isRegistered<Box>(instanceName: 'denuncias_cache')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('denuncias_cache'), instanceName: 'denuncias_cache');
    }
    if (!_getIt.isRegistered<Box>(instanceName: 'ocorrencias_cache')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('ocorrencias_cache'), instanceName: 'ocorrencias_cache');
    }

    // Registra os repositórios antigos
    _getIt.registerLazySingleton<DenunciaRepository>(
      () => DenunciaRepository(
        supabase: _getIt<SupabaseClient>(),
        cacheBox: _getIt<Box>(instanceName: 'denuncias_cache'),
      ),
    );
    _getIt.registerLazySingleton<OcorrenciaRepository>(
      () => OcorrenciaRepository(
        supabase: _getIt<SupabaseClient>(),
        cacheBox: _getIt<Box>(instanceName: 'ocorrencias_cache'),
      ),
    );
    _getIt.registerLazySingleton<AgenteRepository>(
      () => AgenteRepository(
        supabase: _getIt<SupabaseClient>(),
        cacheBox: _getIt<Box>(instanceName: 'denuncias_cache'),
      ),
    );

    // Serviços principais
    _getIt.registerLazySingleton<DenunciaService>(
      () => DenunciaService(),
    );
    
    _getIt.registerLazySingleton<OcorrenciaSiocchagasService>(
      () => OcorrenciaSiocchagasService(),
    );

    _getIt.registerLazySingleton<AgentService>(
      () => AgentService(
        agenteRepository: _getIt<AgenteRepository>(),
        ocorrenciaRepository: _getIt<OcorrenciaRepository>(),
        denunciaRepository: _getIt<DenunciaRepository>(),
      ),
    );

    _getIt.registerLazySingleton<HiveSyncService>(
      () => HiveSyncService(
        denunciaService: _getIt<DenunciaService>(),
        ocorrenciaService: _getIt<OcorrenciaSiocchagasService>(),
      ),
    );

    _getIt<DenunciaService>().setSyncService(_getIt<HiveSyncService>());
  }

  static T get<T extends Object>() => _getIt<T>();
}
