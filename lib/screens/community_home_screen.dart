import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Portal da Comunidade'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // <<< ERRO CORRIGIDO
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
              icon: const Icon(Icons.list_alt),
              label: const Text('Minhas Denúncias'),
              onPressed: () {
                Navigator.pushNamed(context, '/minhas_denuncias');
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
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Mapa de Risco'),
              onPressed: null, // null para desabilitar o botão
            ),
          ],
        ),
      ),
    );
  }
}
