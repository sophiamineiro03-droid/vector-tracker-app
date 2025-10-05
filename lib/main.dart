import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa TODAS as suas telas da pasta 'screens'
import 'package:vector_tracker_app/screens/login_screen.dart';
// A HomeScreen antiga foi removida e substituída pelas duas novas telas abaixo
import 'package:vector_tracker_app/screens/community_home_screen.dart';
import 'package:vector_tracker_app/screens/agent_home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';

// A importação da tela antiga foi removida, pois não é mais necessária.

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wcxiziyrjiqvhmxvpfga.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjeGl6aXlyamlxdmhteHZwZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyOTg2NDksImV4cCI6MjA3NDg3NDY0OX0.EGNXOT3IhSVLR41q5xE2JGx-gPahQpwkwsitH1wJVLY',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Tracker',
      debugShowCheckedModeBanner: false,

      // --- TEMA ATUALIZADO PARA O PADRÃO MODERNO (Material 3) ---
      theme: ThemeData(
        // Usa uma cor "semente" para gerar uma paleta de cores harmoniosa
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

        // Mantém a fonte Poppins que já usávamos
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        useMaterial3: true,

        // Ajusta o estilo do botão para se alinhar com o novo esquema de cores
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Cor principal do botão
            foregroundColor: Colors.white, // Cor do texto e ícones do botão
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),

      // A tela inicial continua sendo a LoginScreen
      home: const LoginScreen(),

      // --- ROTAS ATUALIZADAS ---
      routes: {
        '/login': (context) => const LoginScreen(),
        // As duas novas telas principais
        '/community_home': (context) => const CommunityHomeScreen(),
        '/agent_home': (context) => const AgentHomeScreen(),
        // Rotas para as telas de funcionalidades
        '/painel_agente': (context) => const PainelAceScreen(),
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
        // A rota para a nova tela não é necessária aqui, pois usaremos navegação dinâmica
      },
    );
  }
}
