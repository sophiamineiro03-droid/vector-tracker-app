// Cole este código em: lib/screens/conscientizacao/chagas_detalhe_screen.dart

import 'package:flutter/material.dart';

class ChagasDetalheScreen extends StatelessWidget {
  const ChagasDetalheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doença de Chagas'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que é?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.coronavirus_outlined, // Ícone genérico para microorganismo
              title: 'Causada por um protozoário',
              subtitle: 'O Trypanosoma cruzi, um parasita tropical negligenciado.',
            ),
            _buildInfoItem(
              icon: Icons.bug_report_outlined,
              title: 'Transmitida pelo "barbeiro"',
              subtitle: 'A principal forma de contágio é pela picada e fezes do inseto.',
            ),
            _buildInfoItem(
              icon: Icons.favorite_border,
              title: 'Afeta órgãos vitais',
              subtitle: 'Pode causar problemas graves e crônicos no coração e no sistema digestivo.',
            ),
          ],
        ),
      ),
    );
  }

  // Widget reutilizável para os itens de informação
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 35, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}