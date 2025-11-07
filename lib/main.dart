import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tracker_app/core/app_config.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/core/service_locator.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/screens/pendencias_list_screen.dart';
import 'package:vector_tracker_app/screens/sincronizar_list_screen.dart';
import 'package:vector_tracker_app/screens/meu_trabalho_list_screen.dart';
import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/community_home_screen.dart';
import 'package:vector_tracker_app/screens/agent_home_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/minhas_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';

late final DenunciaService denunciaService;

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
    await Hive.openBox('pending_denuncias');
    await Hive.openBox('localidades_cache');
    await Hive.openBox('ocorrencias_cache');
    await Hive.openBox('pending_ocorrencias');

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
    await Hive.openBox('pending_denuncias');
    await Hive.openBox('localidades_cache');
    await Hive.openBox('ocorrencias_cache');
    await Hive.openBox('pending_ocorrencias');

    await ServiceLocator.setup();
    AppLogger.info('✓ Service Locator configurado no modo de fallback');
  }

  denunciaService = ServiceLocator.get<DenunciaService>();

  runApp(
    MultiProvider(
      providers: [
        // CORREÇÃO: Fornece o AgenteRepository para todo o app.
        Provider(create: (_) => ServiceLocator.get<AgenteRepository>()),
        ChangeNotifierProvider.value(value: denunciaService),
        ChangeNotifierProvider(create: (_) => ServiceLocator.get<AgentOcorrenciaService>()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
        '/minhas_denuncias': (context) => const MinhasDenunciasScreen(),
        '/registro_ocorrencia': (context) => const RegistroOcorrenciaAgenteScreen(),
        '/pendencias_localidade': (context) => const PendenciasListScreen(),
        '/novo_registro_proativo': (context) => const RegistroOcorrenciaAgenteScreen(),
        '/meu_trabalho': (context) => const MeuTrabalhoListScreen(),
        '/sincronizar_dados': (context) => const SincronizarListScreen(),
        '/atendimento_denuncia': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Denuncia) {
            return RegistroOcorrenciaAgenteScreen(denunciaOrigem: args);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(
              child: Text('Erro ao carregar a denúncia. Argumentos inválidos.'),
            ),
          );
        }
      },
    );
  }
}
