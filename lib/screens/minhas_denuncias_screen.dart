import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class MinhasDenunciasScreen extends StatelessWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Minhas Denúncias'),
      body: Consumer<DenunciaService>(
        builder: (context, denunciaService, child) {
          if (denunciaService.isLoading && denunciaService.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final minhasDenuncias = denunciaService.items
              .where((item) => item['is_ocorrencia'] != true)
              .toList();

          if (minhasDenuncias.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Text(
                  'Nenhuma denúncia registrada por você.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => denunciaService.fetchItems(showLoading: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: minhasDenuncias.length,
              itemBuilder: (context, index) {
                final denuncia = minhasDenuncias[index];
                return DenunciaCard(denuncia: denuncia);
              },
            ),
          );
        },
      ),
    );
  }
}

class DenunciaCard extends StatelessWidget {
  final Map<String, dynamic> denuncia;

  const DenunciaCard({super.key, required this.denuncia});

  String _formatarData(String? dataString) {
    if (dataString == null) return 'Data não informada';
    try {
      final data = DateTime.parse(dataString);
      return DateFormat("dd/MM/yyyy 'às' HH:mm").format(data);
    } catch (e) {
      return 'Data inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = denuncia['status']?.toString().toLowerCase() ?? 'pendente';
    final imagePath = denuncia['image_path'] as String?;
    final imageUrl = denuncia['image_url'] as String?;

    Widget imageWidget;
    if (imagePath != null) {
      imageWidget = Image.file(File(imagePath), fit: BoxFit.cover);
    } else if (imageUrl != null) {
      imageWidget = Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      imageWidget = const SizedBox.shrink(); // Não mostra nada se não houver imagem
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DenunciaScreen(denuncia: denuncia),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null || imageUrl != null)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: imageWidget,
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrado em: ${_formatarData(denuncia['created_at'])}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(status),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String label;
    IconData icon;

    switch (status) {
      case 'realizada':
        chipColor = Colors.green;
        label = 'VISITA REALIZADA';
        icon = Icons.check_circle_outline;
        break;
      case 'recusada':
      case 'fechado':
        chipColor = Colors.red;
        label = 'NÃO ATENDIDA';
        icon = Icons.cancel_outlined;
        break;
      case 'pendente':
      default:
        chipColor = Colors.orange;
        label = 'AGUARDANDO VISITA';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
