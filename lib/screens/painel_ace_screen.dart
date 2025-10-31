import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class PainelAceScreen extends StatefulWidget {
  const PainelAceScreen({super.key});

  @override
  State<PainelAceScreen> createState() => _PainelAceScreenState();
}

class _PainelAceScreenState extends State<PainelAceScreen> {
  // A chamada inicial de fetchItems() foi removida daqui, pois agora está no construtor do serviço.

  Future<void> _navigateToForm(BuildContext context, DenunciaService service, Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistroOcorrenciaAgenteScreen(item: item)),
    );

    if (result != null && result is Map<String, dynamic>) {
      // A atualização da lista agora é tratada pelo DenunciaService globalmente
      // Não é mais necessário chamar o updateItemInList daqui.
      service.forceRefresh(); // Apenas força uma atualização para garantir consistência
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Lista de Visitas'),
      body: Consumer<DenunciaService>(
        builder: (context, denunciaService, child) {
          if (denunciaService.isLoading && denunciaService.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = denunciaService.items;
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => denunciaService.fetchItems(),
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
            onRefresh: () => denunciaService.fetchItems(showLoading: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return CardOcorrencia(
                  item: item,
                  onTap: () => _navigateToForm(context, denunciaService, item),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<DenunciaService>(
        builder: (context, service, _) => FloatingActionButton(
          onPressed: () => _navigateToForm(context, service, {}),
          tooltip: 'Registrar Nova Ocorrência',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class CardOcorrencia extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const CardOcorrencia({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOcorrencia = item['is_ocorrencia'] == true;
    final isPendingSync = item['is_pending'] == true;

    final title = _construirTitulo();
    final dateStr = isOcorrencia ? item['data_atividade'] : item['created_at'];
    final date = _formatarData(dateStr);
    
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
              _buildStatusIcon(isOcorrencia, item['status']?.toString().toLowerCase() ?? 'pendente'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
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

  String _construirTitulo() {
    final isOcorrencia = item['is_ocorrencia'] == true;
    if (isOcorrencia) {
      final parts = [item['localidade'], item['endereco']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
      return parts.isEmpty ? "Ocorrência de Campo" : parts;
    } else {
      final parts = [item['rua'], item['numero'], item['bairro']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
      return parts.isEmpty ? "Denúncia da Comunidade" : parts;
    }
  }

  String _formatarData(String? dataString) {
    if (dataString == null || dataString.isEmpty) return 'Data não disponível';
    DateTime? data;
    try {
      data = DateTime.parse(dataString);
    } catch (e) {
      try {
        data = DateFormat('dd/MM/yyyy').parse(dataString);
      } catch (e2) {
        return 'Data inválida';
      }
    }
    return DateFormat('dd/MM/yyyy').format(data);
  }

  Widget _buildStatusIcon(bool isOcorrencia, String status) {
    if (isOcorrencia || status == 'realizada') {
      return Icon(Icons.check_circle_rounded, color: Colors.green, size: 32);
    }

    switch (status) {
      case 'fechado':
      case 'recusada':
        return Icon(Icons.cancel_rounded, color: Colors.red, size: 32);
      case 'pendente':
      default:
        return Icon(Icons.pending_rounded, color: Colors.orange, size: 32);
    }
  }
}
