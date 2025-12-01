import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/core/app_logger.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';

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
    // 0. PRÉ-CARREGAMENTO DE DADOS GERAIS (Fire and Forget)
    // Tenta baixar municípios em background enquanto o logo aparece
    WidgetsBinding.instance.addPostFrameCallback((_) {
       try {
         Provider.of<DenunciaService>(context, listen: false).fetchMunicipios();
       } catch (e) {
         AppLogger.warning('Erro ao tentar pré-carregar municípios na Splash', e);
       }
    });

    // 1. OUVINTE DE AUTENTICAÇÃO (Prioridade Máxima)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        AppLogger.info('Splash Event: ${data.event}');

        if (_redirected) return;

        if (data.event == AuthChangeEvent.passwordRecovery) {
          _cancelTimer();
          _goToScreen('/update_password');
        }
      },
      onError: (error) {
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

    if (session != null) {
      // Temos uma sessão válida (pode ser cacheada)
      final userId = session.user.id;
      
      try {
        // Tenta verificar online (caminho ideal)
        final maybeAgent = await Supabase.instance.client
            .from('agentes')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 5)); // Timeout para não travar muito se net ruim
        
        if (maybeAgent != null) {
          _goToScreen('/agent_home');
          // Salva flag localmente para a próxima vez offline (opcional, mas o cache do agente já serve)
        } else {
          _goToScreen('/community_home');
        }
      } catch (e) {
        AppLogger.warning('Sem conexão ou erro ao verificar perfil online. Tentando modo offline...', e);
        
        // FALLBACK OFFLINE: Verifica se tem dados de agente salvos no cache
        if (Hive.isBoxOpen('agente_cache') && Hive.box('agente_cache').isNotEmpty) {
            // Se tem cache de agente, assumimos que é agente
            AppLogger.info('Cache de agente encontrado. Entrando como Agente (Offline).');
            _goToScreen('/agent_home');
        } else {
            // Se não tem cache de agente, mas tem sessão, assumimos Comunidade
            // (ou é um agente que nunca logou e limpou cache, aí infelizmente vai pra comunidade, mas é o melhor chute)
            AppLogger.info('Sem cache de agente. Entrando como Comunidade (Offline).');
            _goToScreen('/community_home');
        }
      }
    } else {
      // Sem sessão, vai para login
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
    _cancelTimer(); 
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
          child: Image.asset('assets/logo_agora_vai.png'), // Mantive o asset original encontrado no arquivo
        ),
      ),
    );
  }
}
