import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

// NOVA CLASSE, CRIADA CONFORME A INSTRUÇÃO DE CORREÇÃO FINALÍSSIMA
class PendenciasListScreen extends StatelessWidget {
  const PendenciasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final denunciaService = context.watch<DenunciaService>();

    // Garante que os dados sejam carregados ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      denunciaService.fetchItems();
    });

    final pendencias = denunciaService.items
        .where((d) => d['status'] != 'Atendida')
        .map((item) => Denuncia.fromMap(item))
        .toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Pendências da Localidade'),
      body: RefreshIndicator(
        onRefresh: () => denunciaService.fetchItems(),
        child: pendencias.isEmpty
            ? const Center(child: Text('Nenhuma pendência no momento.'))
            : ListView.builder(
          itemCount: pendencias.length,
          itemBuilder: (context, index) {
            final denuncia = pendencias[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: denuncia.foto_url != null
                      ? SmartImage(imageSource: denuncia.foto_url!, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                ),
                title: Text(denuncia.rua ?? 'Endereço não informado'),
                subtitle: Text('Registrado em: ${denuncia.createdAt != null ? DateFormat('dd/MM/yyyy').format(denuncia.createdAt!) : 'Data indisponível'}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/atendimento_denuncia',
                    arguments: denuncia,
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