import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';

// Importa TODAS as suas telas da pasta 'screens'
import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/community_home_screen.dart';
import 'package:vector_tracker_app/screens/agent_home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';
import 'package:vector_tracker_app/screens/minhas_denuncias_screen.dart';

// Manter o supabase client como uma variável global/pública é uma prática comum e aceitável.
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A inicialização do Supabase ainda é necessária para o login.
  await Supabase.initialize(
    url: 'https://wcxiziyrjiqvhmxvpfga.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjeGl6aXlyamlxdmhteHZwZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyOTg2NDksImV4cCI6MjA3NDg3NDY0OX0.EGNXOT3IhSVLR41q5xE2JGx-gPahQpwkwsitH1wJVLY',
  );

  // Inicialização do Hive para o armazenamento local.
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  await Hive.openBox('denuncias_cache');
  await Hive.openBox('ocorrencias_cache');

  runApp(
    ChangeNotifierProvider(
      create: (context) => DenunciaService(),
      child: const MyApp(),
    ),
  );
}

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
        '/painel_agente': (context) => const PainelAceScreen(),
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
        '/minhas_denuncias': (context) => const MinhasDenunciasScreen(),
      },
    );
  }
}
