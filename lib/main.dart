 import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tracker_app/core/app_config.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/core/service_locator.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/screens/agent_profile_screen.dart';
import 'package:vector_tracker_app/screens/edit_agent_profile_screen.dart';
import 'package:vector_tracker_app/screens/report_problem_screen.dart';
import 'package:vector_tracker_app/screens/update_password_screen.dart';
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
import 'package:vector_tracker_app/screens/splash_screen.dart';
import 'package:vector_tracker_app/screens/agent_signup_screen.dart';

// Chave global para navegação (permite navegar de qualquer lugar)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    // Passo 3: Abre a caixa de cache do agente
    await Hive.openBox('agente_cache');

    AppLogger.info('✓ Hive inicializado');

    ServiceLocator.setup();
    AppLogger.info('✓ Service Locator configurado');

  } catch (e, stackTrace) {
    AppLogger.error('Erro na inicialização principal', e, stackTrace);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ServiceLocator.get<AgenteRepository>()),
        ChangeNotifierProvider.value(value: GetIt.I.get<DenunciaService>()),
        ChangeNotifierProvider(create: (_) => ServiceLocator.get<AgentOcorrenciaService>()),
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Ouvinte GLOBAL de autenticação.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      AppLogger.info('🔐 Evento de Auth Detectado Globalmente: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        AppLogger.info('>> RECUPERAÇÃO DE SENHA DETECTADA <<');
        _navigateToUpdatePassword();
      } else if (event == AuthChangeEvent.signedIn) {
        // Às vezes, links mágicos disparam apenas signedIn.
        // Vamos verificar se a URL inicial tinha type=recovery (isso é mais complexo sem deep link nativo, mas vamos tentar pelo evento)
        AppLogger.info('Usuário logado. Verificando se precisa de troca de senha...');
      }
    });
  }

  void _navigateToUpdatePassword() {
    // Pequeno delay para garantir que o contexto esteja pronto se o app acabou de abrir
    Future.delayed(const Duration(milliseconds: 500), () {
      if (navigatorKey.currentState != null) {
        AppLogger.info('Navegando para /update_password agora!');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/update_password',
          (route) => false,
        );
      } else {
        AppLogger.error('NavigatorKey current state is null! Não consigo navegar.');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Conecta a chave global ao MaterialApp
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
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/agent_signup': (context) => const AgentSignupScreen(),
        '/community_home': (context) => const CommunityHomeScreen(),
        '/agent_home': (context) => const AgentHomeScreen(),
        '/agent_profile': (context) => const AgentProfileScreen(),
        '/update_password': (context) => const UpdatePasswordScreen(), // A tela está aqui!
        '/edit_agent_profile': (context) {
          final agente = ModalRoute.of(context)!.settings.arguments as Agente;
          return EditAgentProfileScreen(agente: agente);
        },
        '/report_problem': (context) => const ReportProblemScreen(),
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
