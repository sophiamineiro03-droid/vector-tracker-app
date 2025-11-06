import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';

class SincronizarDadosScreen extends StatelessWidget {
  const SincronizarDadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pendentes = context.watch<OcorrenciaSiocchagasService>().pendentesSincronizacao;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Sincronizar Dados (Pendentes)'),
      body: pendentes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum registro local para sincronizar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: pendentes.length,
              itemBuilder: (context, index) {
                final ocorrencia = pendentes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.sync_problem, color: Colors.orange),
                    title: Text(
                      ocorrencia.endereco ?? 'Endereço não preenchido',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Pendente de Sincronização desde ${DateFormat('dd/MM/yyyy HH:mm').format(ocorrencia.data_atividade!)}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // A navegação para editar um registro existente precisa ser implementada.
                      // Por enquanto, vamos deixar um placeholder.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de edição a ser implementada.')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
