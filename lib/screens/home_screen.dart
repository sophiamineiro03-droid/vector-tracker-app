import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Vector Tracker'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Registrar Ocorrência'),
              onPressed: () {
                Navigator.pushNamed(context, '/denuncia');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('Seção Educativa'),
              onPressed: () {
                Navigator.pushNamed(context, '/educacao');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.shield),
              label: const Text('Painel do Agente'),
              onPressed: () {
                Navigator.pushNamed(context, '/painel_agente');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Mapa de Calor'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tela de Mapa ainda não implementada.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}