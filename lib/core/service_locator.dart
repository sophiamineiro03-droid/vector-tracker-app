import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/repositories/denuncia_repository.dart';
import 'package:vector_tracker_app/repositories/ocorrencia_repository.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  static Future<void> setup() async {
    _getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

    if (!_getIt.isRegistered<Box>(instanceName: 'denuncias_cache')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('denuncias_cache'),
          instanceName: 'denuncias_cache');
    }
    if (!_getIt.isRegistered<Box>(instanceName: 'ocorrencias_cache')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('ocorrencias_cache'),
          instanceName: 'ocorrencias_cache');
    }
    if (!_getIt.isRegistered<Box>(instanceName: 'pending_ocorrencias')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('pending_ocorrencias'),
          instanceName: 'pending_ocorrencias');
    }
    // Passo 4: Registra a caixa de cache do agente
    if (!_getIt.isRegistered<Box>(instanceName: 'agente_cache')) {
      _getIt.registerLazySingleton<Box>(() => Hive.box('agente_cache'),
          instanceName: 'agente_cache');
    }

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
        pendingBox: _getIt<Box>(instanceName: 'pending_ocorrencias'),
      ),
    );

    _getIt.registerLazySingleton<AgenteRepository>(
          () => AgenteRepository(
            _getIt<SupabaseClient>(),
            _getIt<Box>(instanceName: 'agente_cache'), // Injeta o cache
          ),
    );

    _getIt.registerLazySingleton<DenunciaService>(
          () => DenunciaService(),
    );

    _getIt.registerLazySingleton<AgentService>(
          () => AgentService(),
    );

    // CORREÇÃO: Fornece os repositórios necessários para o serviço
    _getIt.registerLazySingleton<AgentOcorrenciaService>(
          () => AgentOcorrenciaService(
        _getIt<AgenteRepository>(),
        _getIt<OcorrenciaRepository>(),
      ),
    );
  }

  static T get<T extends Object>() => _getIt<T>();
}
