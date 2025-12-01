import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 
  int _selectedTab = 1; // Mantive igual ao seu (1 = Agente)
  bool _isLoading = false;
  bool _obscureText = true;
  bool _showForgotPassword = false; 

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
           Navigator.pushNamed(context, '/update_password');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFloatingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showFloatingSnackBar('Por favor, digite seu e-mail acima para recuperar a senha.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        _showFloatingSnackBar('E-mail de recuperação enviado! Verifique sua caixa de entrada.', Colors.green);
      }
    } on AuthException catch (error) {
      if (mounted) {
         // Verifica se é erro de rede dentro do AuthException
         final msg = error.message.toLowerCase();
         if (msg.contains('socketexception') || msg.contains('host lookup') || msg.contains('network') || msg.contains('clientexception')) {
            _showFloatingSnackBar('Não foi possível conectar. Verifique sua internet.', Colors.orange.shade800);
         } else {
            _showFloatingSnackBar('Erro ao enviar e-mail: ${error.message}', Colors.red.shade700);
         }
      }
    } on SocketException {
      if (mounted) {
        _showFloatingSnackBar('Sem conexão com a internet. Verifique seu sinal.', Colors.orange.shade800);
      }
    } catch (error) {
      if (mounted) {
        _showFloatingSnackBar('Erro inesperado. Tente novamente.', Colors.red.shade700);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEnter() async {
    
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final supabase = Supabase.instance.client;

      // Envia as credenciais para o Supabase
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Se logou com sucesso:
      if (mounted) {
        if (_selectedTab == 1) {
          Navigator.pushReplacementNamed(context, '/agent_home');
        } else {
          // Se for comunidade logado
          Navigator.pushReplacementNamed(context, '/community_home');
        }
      }

    } on AuthException catch (error) {
      // 1. Tratamento de erro de Credenciais
      if (error.message.contains('Invalid login credentials') || error.message.contains('invalid_grant')) {
        setState(() {
          _showForgotPassword = true;
        });
        if (mounted) {
          _showFloatingSnackBar('E-mail ou senha incorretos.', Colors.red.shade700);
        }
        return;
      }

      // 2. Tratamento de erro de REDE DENTRO do AuthException
      final msg = error.message.toLowerCase();
      if (msg.contains('socketexception') || msg.contains('host lookup') || msg.contains('network') || msg.contains('clientexception')) {
         if (mounted) {
            _showFloatingSnackBar('Não foi possível conectar. Verifique sua internet.', Colors.orange.shade800);
         }
         return;
      }

      // 3. Outros erros de Auth
      if (mounted) {
        _showFloatingSnackBar(error.message, Colors.red.shade700);
      }

    } on SocketException {
      // CAPTURA FALHA DE REDE DIRETA
      if (mounted) {
        _showFloatingSnackBar('Não foi possível conectar. Verifique sua internet.', Colors.orange.shade800);
      }
    } catch (error) {
      // Captura outros erros de rede que podem vir encapsulados em Exception genérica
      final msg = error.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('host lookup') || msg.contains('network') || msg.contains('clientexception')) {
         if (mounted) {
          _showFloatingSnackBar('Erro de conexão. Verifique sua internet.', Colors.orange.shade800);
        }
      } else {
        if (mounted) {
          _showFloatingSnackBar('Ocorreu um erro inesperado. Tente novamente.', Colors.red.shade700);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGuestEnter() {
    Navigator.pushReplacementNamed(context, '/community_home');
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final isCommunity = _selectedTab == 0; // Verifica se é aba Comunidade

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39A2AE), Color(0xFF2979FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: Colors.white,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset('assets/logo.png', height: 100),
                          const SizedBox(height: 24.0),
                          _buildTabSelector(context, accentColor),
                          const SizedBox(height: 24.0),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite seu e-mail';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite sua senha';
                              }
                              return null;
                            },
                          ),
                          
                          if (_showForgotPassword) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _sendPasswordResetEmail,
                                child: const Text('Esqueci minha senha', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24.0),
                          
                          // Botão ENTRAR (Agora faz Login Real para ambos)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            ),
                            onPressed: _isLoading ? null : _handleEnter,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),

                          // === BOTÕES EXTRAS PARA COMUNIDADE ===
                          if (isCommunity) ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup_comunidade'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              ),
                              child: const Text('Não tem conta? Cadastre-se'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                                onPressed: _handleGuestEnter,
                                child: const Text('Entrar sem Login (Visitante)', 
                                style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline))
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          _buildTabItem(context, 'Comunidade', 0, accentColor),
          _buildTabItem(context, 'Agente', 1, accentColor),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index, Color accentColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_isLoading) {
            setState(() {
               _selectedTab = index;
               _showForgotPassword = false; 
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
