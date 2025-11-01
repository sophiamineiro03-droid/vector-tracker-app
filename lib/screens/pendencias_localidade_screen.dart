import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';

class PendenciasLocalidadeScreen extends StatefulWidget {
  const PendenciasLocalidadeScreen({super.key});

  @override
  State<PendenciasLocalidadeScreen> createState() => _PendenciasLocalidadeScreenState();
}

class _PendenciasLocalidadeScreenState extends State<PendenciasLocalidadeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentService>().getPendencias();
    });
  }

  Future<void> _navigateToDenuncia(Denuncia denuncia) async {
    final agentService = context.read<AgentService>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroOcorrenciaAgenteScreen(denunciaOrigem: denuncia),
      ),
    );

    if (result == true && mounted) {
      agentService.getPendencias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Pendências da Localidade', // Título restaurado
        centerTitle: true, // Título centralizado
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          if (agentService.isPendenciasLoading && agentService.pendencias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendencias = agentService.pendencias;

          if (pendencias.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => agentService.getPendencias(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Text(
                        'Nenhuma pendência encontrada para sua localidade.\nPuxe para baixo para atualizar.', // Texto restaurado
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => agentService.getPendencias(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: pendencias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final denuncia = pendencias[index];
                return CardDenuncia(
                  denuncia: denuncia,
                  onTap: () => _navigateToDenuncia(denuncia),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CardDenuncia extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;

  const CardDenuncia({super.key, required this.denuncia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final endereco = [denuncia.rua, denuncia.numero, denuncia.bairro]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
    final data = denuncia.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(denuncia.createdAt!)
        : 'Data desconhecida';

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endereco.isEmpty ? 'Denúncia sem endereço' : endereco,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('Registrada em: $data', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
