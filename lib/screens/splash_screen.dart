import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _initializeSplash();
  }

  void _initializeSplash() {
    // 1. Configura o ouvinte para detectar o link de senha imediatamente
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_redirected) return; // Se já saiu da tela, ignora
      
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _goToScreen('/update_password');
      }
    });

    // 2. Inicia o temporizador visual de 3 segundos (como era no original)
    Timer(const Duration(seconds: 3), () {
      if (_redirected) return; // Se o link já redirecionou, o timer não faz nada
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;
    
    // Verifica se já tem alguém logado
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Usuário logado -> Vai para a Home
      _goToScreen('/agent_home');
    } else {
      // Ninguém logado -> Vai para o Login
      _goToScreen('/login');
    }
  }

  void _goToScreen(String routeName) {
    if (_redirected || !mounted) return;
    _redirected = true;
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          // Define a largura da imagem como 60% da largura da tela (como no original)
          width: MediaQuery.of(context).size.width * 0.6,
          child: Image.asset('assets/logo_agora_vai.png'),
        ),
      ),
    );
  }
}
