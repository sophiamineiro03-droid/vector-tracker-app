import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';

// NOVA CLASSE, CONFORME A INSTRUÇÃO DE CORREÇÃO FINALÍSSIMA
class MeuTrabalhoListScreen extends StatelessWidget {
  const MeuTrabalhoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final concluidas = context.watch<OcorrenciaSiocchagasService>().meuTrabalho;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Meu Trabalho (Concluído)'),
      body: concluidas.isEmpty
          ? const Center(
              child: Text(
                'Nenhum registro sincronizado encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: concluidas.length,
              itemBuilder: (context, index) {
                final ocorrencia = concluidas[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done, color: Colors.green),
                    title: Text(
                      ocorrencia.endereco ?? 'Endereço não preenchido',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Atividade de ${ocorrencia.tipo_atividade ?? ''} em ${ocorrencia.data_atividade != null ? DateFormat('dd/MM/yyyy').format(ocorrencia.data_atividade!) : 'Data indisponível'}'),
                    // Esta lista é apenas para consulta, sem ação de clique.
                    onTap: null, 
                  ),
                );
              },
            ),
    );
  }
}
