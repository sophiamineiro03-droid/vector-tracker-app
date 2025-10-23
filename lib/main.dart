import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/services/hive_sync_service.dart';

// Importa TODAS as suas telas da pasta 'screens'
import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/community_home_screen.dart';
import 'package:vector_tracker_app/screens/agent_home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/minhas_denuncias_screen.dart';

// MODIFICADO: Os serviços são criados aqui para serem passados para o app.
late final DenunciaService denunciaService;
late final HiveSyncService syncService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // As inicializações pesadas permanecem aqui
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
  
  // Os serviços são instanciados mas NÃO iniciados
  denunciaService = DenunciaService();
  syncService = HiveSyncService(denunciaService: denunciaService);
  denunciaService.setSyncService(syncService);

  runApp(
    ChangeNotifierProvider.value(
      value: denunciaService,
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

// MODIFICADO: Convertido para StatefulWidget para iniciar o serviço de sync após a UI carregar.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inicia o serviço de sincronização DEPOIS que a primeira tela for construída.
    // Isso evita o "engasgo" na inicialização.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncService.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Tracker App', // Alteração trivial para forçar recompilação
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
        '/agent_home': (context) => const AgentHomeScreen(),       // Menu do Agente
        '/painel_agente': (context) => const PainelAceScreen(),     // Lista de Visitas (Corrigido)
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
        '/minhas_denuncias': (context) => const MinhasDenunciasScreen(),
      },
    );
  }
}
