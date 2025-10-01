import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importa TODAS as suas telas da pasta 'screens'
import 'package:vector_tracker_app/screens/login_screen.dart';
import 'package:vector_tracker_app/screens/home_screen.dart';
import 'package:vector_tracker_app/screens/painel_ace_screen.dart';
import 'package:vector_tracker_app/screens/educacao_screen.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Tracker',
      debugShowCheckedModeBanner: false,

      // NOVO TEMA BASEADO NA LOGO
      theme: ThemeData(
        // Definindo a paleta de cores primária como azul
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          // O verde da logo como cor secundária/acento
          secondary: Colors.green, 
        ),

        // Usando a fonte Poppins
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        // Mantendo o design do Material 3
        useMaterial3: true,

        // Estilo padrão para ElevatedButtons para combinar com o novo tema
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // <<-- COR DO BOTÃO ATUALIZADA
            foregroundColor: Colors.white, // Cor do texto do botão
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),

      // Define a rota inicial do app
      initialRoute: '/login',

      // Mapeia os "nomes" das rotas para as telas correspondentes
      routes: {
        '/login': (context) => LoginScreen(), // <<-- "CONST" REMOVIDO
        '/home': (context) => const HomeScreen(),
        '/painel_agente': (context) => const PainelAceScreen(),
        '/educacao': (context) => const EducacaoScreen(),
        '/denuncia': (context) => const DenunciaScreen(),
      },
    );
  }
}