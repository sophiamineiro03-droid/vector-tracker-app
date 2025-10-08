import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/screens/visit_details_screen.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class PainelAceScreen extends StatelessWidget {
  const PainelAceScreen({super.key});

  Future<void> _navigateToVisit(BuildContext context, DenunciaService service, Map<String, dynamic> denuncia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VisitDetailsScreen(denuncia: denuncia)),
    );
    service.fetchDenuncias(); // Recarrega os dados ao voltar
  }

  Future<void> _navigateToNewOccurrence(BuildContext context, DenunciaService service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VisitDetailsScreen(denuncia: {})),
    );
    service.fetchDenuncias(); // Recarrega os dados ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DenunciaService()..fetchDenuncias(),
      child: Scaffold(
        appBar: const GradientAppBar(title: 'Lista de Visitas'),
        body: Consumer<DenunciaService>(
          builder: (context, denunciaService, child) {
            if (denunciaService.isLoading && denunciaService.denuncias.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final denuncias = denunciaService.denuncias;
            if (denuncias.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => denunciaService.fetchDenuncias(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(child: Text('Nenhuma ocorrência encontrada.\nPuxe para baixo para atualizar.')),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => denunciaService.fetchDenuncias(),
              child: ListView.separated(
                padding: const EdgeInsets.all(12.0),
                itemCount: denuncias.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final denuncia = denuncias[index];
                  return CardOcorrencia(
                    denuncia: denuncia,
                    onTap: () => _navigateToVisit(context, denunciaService, denuncia),
                    isPending: denuncia['is_pending'] ?? false,
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: Consumer<DenunciaService>(
          builder: (context, service, _) => FloatingActionButton(
            onPressed: () => _navigateToNewOccurrence(context, service),
            tooltip: 'Registrar Nova Ocorrência',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// O Widget CardOcorrencia continua o mesmo, sem alterações necessárias.
class CardOcorrencia extends StatelessWidget {
  final Map<String, dynamic> denuncia;
  final VoidCallback onTap;
  final bool isPending;

  const CardOcorrencia({super.key, required this.denuncia, required this.onTap, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    final endereco = _construirEndereco();
    final data = _formatarData(denuncia['visited_at'] ?? denuncia['created_at']);
    final status = denuncia['status'] ?? 'Pendente';

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
              _buildStatusIcon(status),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(endereco, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(data, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isPending) ...[
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

  String _construirEndereco() {
    final parts = [denuncia['rua'], denuncia['numero'], denuncia['bairro']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    return parts.isEmpty ? (denuncia['descricao'] == 'Ocorrência registrada em campo pelo agente.' ? "Nova Ocorrência" : "Endereço não informado") : parts;
  }

  String _formatarData(String? dataString) {
    if (dataString == null) return 'Data não disponível';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dataString));
    } catch (e) {
      return 'Data inválida';
    }
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status.toLowerCase()) {
      case 'realizada':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'fechado':
      case 'recusada':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      default: // Pendente
        icon = Icons.pending_rounded;
        color = Colors.orange;
    }
    return Icon(icon, color: color, size: 32);
  }
}
