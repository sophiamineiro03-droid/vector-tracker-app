// lib/screens/conscientizacao/conscientizacao_menu_screen.dart - CORRIGIDO

import 'package:flutter/material.dart';
import 'chagas_detalhe_screen.dart';

class ConscientizacaoMenuScreen extends StatelessWidget {
  const ConscientizacaoMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF39B5A5), Color(0xFF2F80ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Educação e Saúde'),
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(
            context: context,
            icon: Icons.help_outline,
            title: 'O que é a Doença de Chagas?',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChagasDetalheScreen())),
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.bug_report_outlined,
            title: 'Quem é o inseto barbeiro?',
            onTap: () { /* Adicionar navegação para a tela do vetor aqui */ },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.sick_outlined,
            title: 'Sintomas e diagnóstico',
            onTap: () { /* Adicionar navegação para a tela de sintomas aqui */ },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.health_and_safety_outlined,
            title: 'Como posso me prevenir?',
            // *** MUDANÇA AQUI ***: Corrigido de {} para () {}
            onTap: () { /* Navegar para a tela de prevenção */ },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.warning_amber_rounded,
            title: 'Encontrei um barbeiro! O que fazer?',
            onTap: () { /* Adicionar navegação para a tela de ação aqui */ },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.teal.shade700),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}