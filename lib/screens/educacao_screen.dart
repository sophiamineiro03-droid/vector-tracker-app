import 'package:flutter/material.dart';
import 'package:vector_tracker_app/screens/image_viewer_screen.dart'; // Importa a nova tela
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class EducacaoScreen extends StatelessWidget {
  const EducacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Seção Educativa'),
      backgroundColor: Colors.grey[100],
      // --- CORREÇÃO 1: Adiciona SafeArea para espaçamento automático ---
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 16.0),
          children: [
            _buildStandardInfoCard(
              context,
              title: 'O Vetor: O Barbeiro',
              imageUrl: 'assets/barbeiro.jpg',
              text:
                  'O barbeiro é o inseto transmissor da Doença de Chagas. Ele geralmente vive em frestas de casas de pau-a-pique, ninhos de pássaros e tocas de animais. Possui hábitos noturnos e se alimenta de sangue.',
            ),
            const SizedBox(height: 16),
            _buildStandardInfoCard(
              context,
              title: 'Principais Sintomas',
              imageUrl: 'assets/chagas_sintomas.jpeg',
              text:
                  'Na fase aguda, os sintomas comuns são febre, mal-estar, inchaço nos olhos (sinal de Romañá) e aumento do fígado e baço. Na fase crônica, a doença pode causar graves problemas cardíacos e digestivos.',
            ),
            const SizedBox(height: 16),
            _buildFullContentImageCard(
              context,
              title: 'Como se Prevenir?',
              imageUrl: 'assets/prevencao.webp',
              text:
                  'Mantenha a casa limpa, tape buracos e frestas nas paredes e no chão. Use telas em portas e janelas. Evite acúmulo de entulhos no quintal. Se encontrar um barbeiro, não o esmague. Capture-o com cuidado e leve ao posto de saúde.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardInfoCard(BuildContext context, {required String title, required String imageUrl, required String text}) {
    return Card(
      elevation: 3.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
            child: Image.asset(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(Icons.error_outline, color: Colors.grey, size: 48)))),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5, color: Colors.black.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullContentImageCard(BuildContext context, {required String title, required String imageUrl, required String text}) {
    return Card(
      elevation: 3.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CORREÇÃO 2: Imagem interativa que abre em tela cheia ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
                  fullscreenDialog: true,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
              child: Image.asset(imageUrl, width: double.infinity, errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(Icons.error_outline, color: Colors.grey, size: 48)))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5, color: Colors.black.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
