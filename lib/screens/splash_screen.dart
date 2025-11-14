
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:vector_tracker_app/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Após 3 segundos, navega para a tela de login
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Usamos um Container para controlar o tamanho da imagem
        child: Container(
          // Define a largura da imagem como 60% da largura da tela
          width: MediaQuery.of(context).size.width * 0.6,
          child: Image.asset('assets/logo_agora_vai.png'),
        ),
      ),
    );
  }
}
