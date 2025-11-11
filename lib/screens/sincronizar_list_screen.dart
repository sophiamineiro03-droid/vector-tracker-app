import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class SincronizarListScreen extends StatelessWidget {
  const SincronizarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Sincronizar Dados (Pendentes)'),
      body: Consumer<AgentOcorrenciaService>(
        builder: (context, agentService, child) {
          if (agentService.ocorrencias.isEmpty && !agentService.isLoading) {
            Future.microtask(() => agentService.fetchOcorrencias());
          }

          if (agentService.isLoading && agentService.ocorrencias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendentes = agentService.ocorrencias.where((o) => !o.sincronizado).toList();

          if (pendentes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum registro local para sincronizar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => agentService.forceRefresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: pendentes.length,
              itemBuilder: (context, index) {
                final ocorrencia = pendentes[index];
                final endereco = '${ocorrencia.endereco ?? 'Endereço não informado'}, ${ocorrencia.numero ?? 'S/N'}';
                final data = ocorrencia.created_at != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(ocorrencia.created_at!)
                    : 'Data indisponível';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.sync_problem, color: Colors.orange),
                    title: Text(
                      endereco,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Pendente desde $data'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RegistroOcorrenciaAgenteScreen(
                            ocorrencia: ocorrencia,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AgentOcorrenciaService>(
        builder: (context, agentService, child) {
          if (agentService.pendingSyncCount == 0) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              if (agentService.isSyncing) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando sincronização...')),
              );

              final resultMessage = await agentService.syncPendingOcorrencias();

              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultMessage), // Usa a mensagem de texto diretamente
                    backgroundColor: resultMessage.contains('sucesso') ? Colors.green : Colors.red, // Determina a cor pela mensagem
                  ),
                );
              }
            },
            label: agentService.isSyncing
                ? const Text('Sincronizando...')
                : const Text('Sincronizar Agora'),
            icon: agentService.isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync),
          );
        },
      ),
    );
  }
}
