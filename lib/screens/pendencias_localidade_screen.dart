import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class PendenciasLocalidadeScreen extends StatelessWidget {
  const PendenciasLocalidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final denunciaService = Provider.of<DenunciaService>(context);

    final pendencias = denunciaService.items
        .where((d) => d['status'] != 'Atendida')
        .map((item) => Denuncia(
              id: item['id'],
              descricao: item['descricao'],
              latitude: item['latitude'],
              longitude: item['longitude'],
              rua: item['rua'],
              bairro: item['bairro'],
              cidade: item['cidade'],
              estado: item['estado'],
              numero: item['numero'].toString(),
              status: item['status'],
              foto_url: item['foto_url'],
              createdAt: DateTime.tryParse(item['created_at'] ?? ''),
            ))
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
                        child: SmartImage(imageSource: denuncia.foto_url, fit: BoxFit.cover),
                      ),
                      title: Text(denuncia.rua ?? 'Endereço não informado'),
                      subtitle: Text('Registrado em: ${DateFormat('dd/MM/yyyy').format(denuncia.createdAt!)}'),
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
