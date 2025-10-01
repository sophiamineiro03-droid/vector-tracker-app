import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class EducacaoScreen extends StatelessWidget {
  const EducacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Seção Educativa'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(
            context,
            title: 'O Vetor: O Barbeiro',
            imageUrl: 'assets/barbeiro.jpg',
            text:
                'O barbeiro é o inseto transmissor da Doença de Chagas. Ele geralmente vive em frestas de casas de pau-a-pique, ninhos de pássaros e tocas de animais. Possui hábitos noturnos e se alimenta de sangue.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Principais Sintomas',
            imageUrl: 'assets/chagas_sintomas.jpeg',
            text:
                'Na fase aguda, os sintomas comuns são febre, mal-estar, inchaço nos olhos (sinal de Romañá) e aumento do fígado e baço. Na fase crônica, a doença pode causar graves problemas cardíacos e digestivos.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Como se Prevenir?',
            imageUrl: 'assets/prevencao.webp',
            text:
                'Mantenha a casa limpa, tape buracos e frestas nas paredes e no chão. Use telas em portas e janelas. Evite acúmulo de entulhos no quintal. Se encontrar um barbeiro, não o esmague. Capture-o com cuidado e leve ao posto de saúde.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required String imageUrl,
      required String text}) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                height: 180,
                child: Center(child: Icon(Icons.error, color: Colors.red)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}