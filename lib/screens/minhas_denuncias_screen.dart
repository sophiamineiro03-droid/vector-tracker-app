import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';
import 'denuncia_screen.dart';

// ARQUIVO CORRIGIDO PARA ENVIAR OBJETOS Denuncia EM VEZ DE MAPS
class MinhasDenunciasScreen extends StatelessWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final denunciaService = context.watch<DenunciaService>();

    // Pede para o serviço buscar os itens mais recentes ao construir a tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      denunciaService.fetchItems();
    });

    return Scaffold(
      appBar: const GradientAppBar(title: 'Minhas Denúncias'),
      body: RefreshIndicator(
        onRefresh: () => denunciaService.fetchItems(),
        child: ListView.builder(
          itemCount: denunciaService.items.length,
          itemBuilder: (context, index) {
            // Converte o Map do serviço para um objeto Denuncia
            final denunciaMap = denunciaService.items[index];
            final denuncia = Denuncia.fromMap(denunciaMap);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: denuncia.foto_url != null
                        ? SmartImage(imageSource: denuncia.foto_url!, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                  ),
                ),
                title: Text(denuncia.descricao ?? 'Sem descrição'),
                subtitle: Text('Registrado em: ${denuncia.createdAt != null ? DateFormat('dd/MM/yyyy').format(denuncia.createdAt!) : 'Data indisponível'}\\nStatus: ${denuncia.status}'),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // CORREÇÃO: Enviando um objeto Denuncia, como a tela agora espera.
                      builder: (context) => DenunciaScreen(denuncia: denuncia),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}