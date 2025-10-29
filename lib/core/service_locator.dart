import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/denuncia_repository.dart';
import '../repositories/ocorrencia_repository.dart';
import '../repositories/agente_repository.dart';
import '../services/denuncia_service.dart';
import '../services/hive_sync_service.dart';
import '../services/agent_service.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  static Future<void> setup() async {
    _getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

    _getIt.registerLazySingleton<Box>(() => Hive.box('denuncias_cache'), instanceName: 'denuncias_cache');
    _getIt.registerLazySingleton<Box>(() => Hive.box('ocorrencias_cache'), instanceName: 'ocorrencias_cache');
    _getIt.registerLazySingleton<Box>(() => Hive.box('pending_denuncias'), instanceName: 'pending_denuncias');
    _getIt.registerLazySingleton<Box>(() => Hive.box('pending_ocorrencias'), instanceName: 'pending_ocorrencias');

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

    // Registra o AgentService com a nova dependência
    _getIt.registerLazySingleton<AgentService>(
      () => AgentService(
        agenteRepository: _getIt<AgenteRepository>(),
        ocorrenciaRepository: _getIt<OcorrenciaRepository>(),
        denunciaRepository: _getIt<DenunciaRepository>(), // <-- CORREÇÃO APLICADA
      ),
    );
    
    // O DenunciaService provavelmente não é mais necessário da forma que estava, 
    // mas vamos manter por enquanto para não quebrar outras partes do app.
    _getIt.registerLazySingleton<DenunciaService>(
      () => DenunciaService(),
    );

    _getIt.registerLazySingleton<HiveSyncService>(
      () => HiveSyncService(denunciaService: _getIt<DenunciaService>()),
    );

    _getIt<DenunciaService>().setSyncService(_getIt<HiveSyncService>());
  }

  static T get<T extends Object>() => _getIt<T>();
  static T getNamed<T extends Object>(String name) => _getIt<T>(instanceName: name);
}
