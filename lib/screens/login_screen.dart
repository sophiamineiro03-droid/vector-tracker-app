import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para validar o formulário
  int _selectedTab = 1; // 0 para Comunidade, 1 para Agente
  bool _isLoading = false;
  bool _obscureText = true;
  bool _showForgotPassword = false; // Nova variável para controlar a exibição do botão

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Ouve eventos de autenticação, especificamente o de Recuperação de Senha
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
           // Se detectar que o usuário clicou num link de senha, redireciona para a tela de troca
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

  // Lógica para enviar o email de recuperação
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite seu e-mail acima para recuperar a senha.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail de recuperação enviado! Verifique sua caixa de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar e-mail: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro inesperado. Tente novamente.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Lógica de login atualizada para usar Supabase
  Future<void> _handleEnter() async {
    // A lógica para a aba "Comunidade" permanece a mesma, sem login.
    if (_selectedTab == 0) {
      Navigator.pushReplacementNamed(context, '/community_home');
      return;
    }

    // Valida o formulário para o Agente. Se os campos estiverem vazios, mostra o erro.
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

      // Se o código chegou aqui, o login foi um sucesso.
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/agent_home');
      }

    } on AuthException catch (error) {
      // Se o erro for de credenciais inválidas, mostra o botão "Esqueci a Senha"
      if (error.message.contains('Invalid login credentials') || error.message.contains('invalid_grant')) {
        setState(() {
          _showForgotPassword = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message == 'Invalid login credentials' ? 'E-mail ou senha incorretos.' : error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      // Captura outros erros (ex: falta de conexão com a internet)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocorreu um erro inesperado. Tente novamente.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Garante que o indicador de "carregando" pare, independente do resultado.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;

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
                    // O Form é usado para agrupar e validar os campos de texto
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
                          
                          // Mostra o botão "Esqueci a Senha" apenas se o login falhar
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
                          
                          if (_selectedTab == 1) ...[
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/agent_signup');
                              },
                              child: const Text(
                                'Não tem conta? Cadastre-se',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
          // Só permite mudar de aba se não estiver carregando
          if (!_isLoading) {
            setState(() => _selectedTab = index);
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
