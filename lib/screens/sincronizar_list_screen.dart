import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class SincronizarListScreen extends StatefulWidget {
  const SincronizarListScreen({super.key});

  @override
  State<SincronizarListScreen> createState() => _SincronizarListScreenState();
}

class _SincronizarListScreenState extends State<SincronizarListScreen> {
  @override
  void initState() {
    super.initState();
    // Garante que a lista de pendentes seja carregada ao entrar na tela
    Future.microtask(() {
      context.read<AgentOcorrenciaService>().fetchPendingOcorrencias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Sincronizar Dados'),
      body: Consumer<AgentOcorrenciaService>(
        builder: (context, agentService, child) {
          // A lista de pendentes agora vem da nova propriedade
          final pendentes = agentService.pendingOcorrencias;

          if (agentService.isLoading && pendentes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pendentes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Nenhum registro local para sincronizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => agentService.fetchPendingOcorrencias(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Verificar novamente'),
                    )
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            // A atualização agora busca apenas os itens pendentes
            onRefresh: () => agentService.fetchPendingOcorrencias(),
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
          // O botão agora aparece baseado na contagem da nova lista
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
                    content: Text(resultMessage),
                    backgroundColor: resultMessage.contains('sucesso') ? Colors.green : Colors.red,
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
