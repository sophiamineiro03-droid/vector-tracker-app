import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tracker_app/core/app_config.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/core/service_locator.dart';
import 'package:vector_tracker_app/screens/pendencias_localidade_screen.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/services/hive_sync_service.dart';

import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/community_home_screen.dart';
import 'package:vector_tracker_app/screens/agent_home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/minhas_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';

late final DenunciaService denunciaService;
late final HiveSyncService syncService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig.initialize();
    AppLogger.info('🚀 Iniciando aplicação...');

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    AppLogger.info('✓ Supabase inicializado');

    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    await Hive.openBox('denuncias_cache');
    await Hive.openBox('pending_sync');
    await Hive.openBox('pending_denuncias');
    await Hive.openBox('pending_ocorrencias');
    await Hive.openBox('ocorrencias_cache');
    AppLogger.info('✓ Hive inicializado');

    await ServiceLocator.setup();
    AppLogger.info('✓ Service Locator configurado');

  } catch (e, stackTrace) {
    AppLogger.error('Erro na inicialização principal', e, stackTrace);
    AppLogger.warning('Iniciando em modo de fallback...');

    await Supabase.initialize(
      url: 'https://wcxiziyrjiqvhmxvpfga.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjeGl6aXlyamlxdmhteHZwZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyOTg2NDksImV4cCI6MjA3NDg3NDY0OX0.EGNXOT3IhSVLR41q5xE2JGx-gPahQpwkwsitH1wJVLY',
    );

    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    await Hive.openBox('denuncias_cache');
    await Hive.openBox('pending_sync');
    await Hive.openBox('pending_denuncias');
    await Hive.openBox('pending_ocorrencias');
    await Hive.openBox('ocorrencias_cache');
    
    // CORRIGIDO: Garante que o ServiceLocator seja configurado mesmo em caso de erro.
    await ServiceLocator.setup();
    AppLogger.info('✓ Service Locator configurado no modo de fallback');
  }

  // Obtém instâncias dos serviços DEPOIS de garantir que o setup foi executado.
  denunciaService = ServiceLocator.get<DenunciaService>();
  syncService = ServiceLocator.get<HiveSyncService>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: denunciaService),
        ChangeNotifierProvider(create: (_) => ServiceLocator.get<AgentService>()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        syncService.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Tracker App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/community_home': (context) => const CommunityHomeScreen(),
        '/agent_home': (context) => const AgentHomeScreen(),
        '/painel_agente': (context) => const PainelAceScreen(),
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
        '/minhas_denuncias': (context) => const MinhasDenunciasScreen(),
        '/registro_ocorrencia': (context) => const RegistroOcorrenciaAgenteScreen(),
        '/pendencias_localidade': (context) => const PendenciasLocalidadeScreen(),
      },
    );
  }
}
