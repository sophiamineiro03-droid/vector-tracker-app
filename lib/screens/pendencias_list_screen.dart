import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';

// CORRIGIDO: Convertido para StatefulWidget para evitar o loop de carregamento.
class PendenciasListScreen extends StatefulWidget {
  const PendenciasListScreen({super.key});

  @override
  State<PendenciasListScreen> createState() => _PendenciasListScreenState();
}

class _PendenciasListScreenState extends State<PendenciasListScreen> {
  
  // CORREÇÃO: A busca de dados agora acontece apenas uma vez.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DenunciaService>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    // O Consumer agora só escuta as mudanças, não causa buscas.
    return Consumer<DenunciaService>(
      builder: (context, denunciaService, child) {
        
        final pendencias = denunciaService.items
            .where((d) => d['status'] != 'Atendida')
            .map((item) => Denuncia.fromMap(item))
            .toList();

        return Scaffold(
          appBar: const GradientAppBar(title: 'Pendências da Localidade'),
          body: RefreshIndicator(
            // CORRIGIDO: O parâmetro 'force' foi removido.
            onRefresh: () => denunciaService.fetchItems(),
            child: denunciaService.isLoading && pendencias.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : (pendencias.isEmpty
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
                          // A navegação aqui agora leva para a tela correta, com o seu layout.
                          Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => RegistroOcorrenciaAgenteScreen(
                                 denunciaOrigem: denuncia,
                               ),
                             ),
                          );
                        },
                      ),
                    );
                  },
                )),
          ),
        );
      },
    );
  }
}
