import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class PainelAceScreen extends StatefulWidget {
  const PainelAceScreen({super.key});

  @override
  State<PainelAceScreen> createState() => _PainelAceScreenState();
}

class _PainelAceScreenState extends State<PainelAceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentService>().getMeuTrabalho();
    });
  }

  Future<void> _navigateToForm(BuildContext context, [Ocorrencia? ocorrencia]) async {
    final agentService = context.read<AgentService>();
    
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroOcorrenciaAgenteScreen(
          ocorrencia: ocorrencia,
        ),
      ),
    );

    if (result == true && mounted) {
      agentService.getMeuTrabalho();
      agentService.loadAgentData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Meu Trabalho', // Título alterado
        centerTitle: true, // Título centralizado
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          if (agentService.isOcorrenciasLoading && agentService.minhasOcorrencias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final ocorrencias = agentService.minhasOcorrencias;
          
          if (ocorrencias.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => agentService.getMeuTrabalho(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: Text('Nenhuma visita ou ocorrência encontrada.\nPuxe para baixo para atualizar.')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => agentService.getMeuTrabalho(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: ocorrencias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ocorrencia = ocorrencias[index];
                return CardOcorrencia(
                  ocorrencia: ocorrencia,
                  onTap: () => _navigateToForm(context, ocorrencia),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        tooltip: 'Registrar Nova Ocorrência',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CardOcorrencia extends StatelessWidget {
  final Ocorrencia ocorrencia;
  final VoidCallback onTap;

  const CardOcorrencia({super.key, required this.ocorrencia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPendingSync = ocorrencia.status == 'pendente';

    final title = [ocorrencia.localidade, ocorrencia.endereco].where((s) => s != null && s.trim().isNotEmpty).join(', ');
    final date = _formatarData(ocorrencia.data_atividade);

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
              _buildStatusIcon(isPendingSync),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.isEmpty ? "Ocorrência de Campo" : title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isPendingSync) ...[
                const SizedBox(width: 8),
                const Tooltip(message: 'Pendente de sincronização', child: Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.orange)),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Data não disponível';
    return DateFormat('dd/MM/yyyy').format(data);
  }

  Widget _buildStatusIcon(bool isPendingSync) {
    return isPendingSync
      ? Icon(Icons.cloud_upload_rounded, color: Colors.orange[600], size: 32)
      : Icon(Icons.description_rounded, color: Colors.indigo[400], size: 32);
  }
}
