import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

import 'denuncia_screen.dart';

class MinhasDenunciasScreen extends StatelessWidget {
  const MinhasDenunciasScreen({super.key});

  // --- WIDGET CRIADO PARA O CHIP DE STATUS ---
  Widget _buildStatusChip(String? status) {
    IconData iconData;
    String text;
    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case 'Pendente':
      case 'pendente_envio':
        iconData = Icons.watch_later_outlined;
        text = 'AGUARDANDO VISITA';
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade800;
        break;
      case 'atendida':
      case 'concluida':
        iconData = Icons.check_circle_outline;
        text = 'ATENDIDA';
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        break;
      default:
        iconData = Icons.help_outline;
        text = (status ?? 'desconhecido').toUpperCase();
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: foregroundColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final denunciaService = context.watch<DenunciaService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      denunciaService.fetchItems();
    });

    return Scaffold(
      appBar: const GradientAppBar(title: 'Minhas Denúncias'),
      body: RefreshIndicator(
        onRefresh: () => denunciaService.fetchItems(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: denunciaService.items.length,
          itemBuilder: (context, index) {
            final denunciaMap = denunciaService.items[index];
            final denuncia = Denuncia.fromMap(denunciaMap);

            final formattedDate = denuncia.createdAt != null
                ? DateFormat('dd/MM/yyyy \'às\' HH:mm').format(denuncia.createdAt!)
                : 'Data indisponível';

            return Card(
              clipBehavior: Clip.antiAlias, // Garante que a imagem respeite as bordas arredondadas
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DenunciaScreen(denuncia: denuncia),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- IMAGEM NO TOPO ---
                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: denuncia.foto_url != null
                          ? SmartImage(imageSource: denuncia.foto_url!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                            ),
                    ),
                    // --- INFORMAÇÕES ABAIXO ---
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registrado em: $formattedDate',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                _buildStatusChip(denuncia.status),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
