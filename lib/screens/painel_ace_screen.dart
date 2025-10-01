import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class PainelAceScreen extends StatelessWidget {
  const PainelAceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Painel do Agente'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // Card de Exemplo 1 - Pendente
          CardOcorrencia(
            endereco: 'Rua das Flores, 123, Bairro Centro',
            data: '27/09/2025',
            status: 'Pendente',
            statusColor: Colors.orange,
          ),
          SizedBox(height: 12),
          // Card de Exemplo 2 - Validado
          CardOcorrencia(
            endereco: 'Avenida Principal, 456, Bairro Norte',
            data: '26/09/2025',
            status: 'Validado',
            statusColor: Colors.green,
          ),
          SizedBox(height: 12),
          // Card de Exemplo 3 - Rejeitado
          CardOcorrencia(
            endereco: 'Praça da Matriz, 789, Bairro Sul',
            data: '25/09/2025',
            status: 'Rejeitado',
            statusColor: Colors.red,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para criar os cards de ocorrência (um componente reutilizável)
class CardOcorrencia extends StatelessWidget {
  final String endereco;
  final String data;
  final String status;
  final Color statusColor;

  const CardOcorrencia({
    super.key,
    required this.endereco,
    required this.data,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              endereco,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('Data: $data'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}