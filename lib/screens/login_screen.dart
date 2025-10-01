import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Mantém o controle da aba selecionada (0 para Comunidade, 1 para Agente)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // Cores inspiradas na sua logo e design
    final Color primaryColor = Theme.of(context).colorScheme.primary; // Azul do tema
    final Color accentColor = Color(0xFF00695C); // Um verde escuro para o botão

    return Scaffold(
      body: Container(
        // Fundo com gradiente
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39A2AE), Color(0xFF2979FF)], // <<-- GRADIENTE ATUALIZADO
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
                child: _buildLoginForm(context, primaryColor, accentColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget principal do formulário
  Widget _buildLoginForm(
      BuildContext context, Color primaryColor, Color accentColor) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Image.asset('assets/logo.png', height: 120),
            const SizedBox(height: 24.0),

            // Seletor de Abas
            _buildTabSelector(context, accentColor),
            const SizedBox(height: 24.0),

            // Campo de Usuário
            _buildTextField(
                hint: 'Usuário', icon: Icons.person_outline, obscure: false),
            const SizedBox(height: 16.0),

            // Campo de Senha
            _buildTextField(
                hint: 'Senha', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 24.0),

            // Botão Entrar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () {
                // Navega para a home após o login
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Entrar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16.0),

            // Texto "Esqueceu sua senha?"
            Text(
              'Esqueceu sua senha?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para os campos de texto
  Widget _buildTextField(
      {required String hint, required IconData icon, required bool obscure}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  // Widget para o seletor de abas customizado
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

  // Item individual da aba
  Widget _buildTabItem(
      BuildContext context, String title, int index, Color accentColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}