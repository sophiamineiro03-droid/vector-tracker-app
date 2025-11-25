import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _redirected = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeSplash();
  }

  void _initializeSplash() {
    // 1. OUVINTE DE AUTENTICAÇÃO (Prioridade Máxima)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        // Log para ajudar a entender o que está acontecendo
        AppLogger.info('Splash Event: ${data.event}');

        if (_redirected) return;

        if (data.event == AuthChangeEvent.passwordRecovery) {
          // BINGO! Link de senha detectado.
          _cancelTimer(); // Para o relógio de 3 segundos
          _goToScreen('/update_password');
        }
      },
      onError: (error) {
        // Se o link estiver quebrado ou expirado, avisa o usuário
        AppLogger.error('Erro no link de autenticação', error);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro no link: ${error.message ?? "Inválido ou expirado"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    // 2. TEMPORIZADOR VISUAL (3 Segundos)
    _timer = Timer(const Duration(seconds: 3), () {
      if (_redirected) return; 
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;
    
    final session = Supabase.instance.client.auth.currentSession;

    // Se tiver sessão, vai pra Home. Se não, Login.
    if (session != null) {
      _goToScreen('/agent_home');
    } else {
      _goToScreen('/login');
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _goToScreen(String routeName) {
    if (_redirected || !mounted) return;
    _redirected = true;
    _cancelTimer(); // Garante que o timer morra
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Image.asset('assets/logo_agora_vai.png'),
        ),
      ),
    );
  }
}
