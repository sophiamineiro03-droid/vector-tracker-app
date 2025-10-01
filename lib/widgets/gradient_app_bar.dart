import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent, // O fundo da AppBar em si é transparente
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white), // Cor do ícone de "voltar"
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39A2AE), Color(0xFF2979FF)], // Gradiente de verde-azulado para azul
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}