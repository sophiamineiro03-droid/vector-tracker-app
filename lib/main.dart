import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa TODAS as suas telas da pasta 'screens'
import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/screens/mapa_denuncias_screen.dart';

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

      // A tela inicial volta a ser a LoginScreen
      home: const LoginScreen(),

      // Mantém as rotas para navegação interna
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/painel_agente': (context) => const PainelAceScreen(),
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
        '/mapa_denuncias': (context) => const MapaDenunciasScreen(),
      },
    );
  }
}
