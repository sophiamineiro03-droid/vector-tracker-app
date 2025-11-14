import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final agente = await Provider.of<AgenteRepository>(context, listen: false).getCurrentAgent();
      final localidadeIds = agente?.localidades.map((loc) => loc.id).toList();
      if(mounted){
         Provider.of<DenunciaService>(context, listen: false).fetchItems(localidadeIds: localidadeIds);
      }
    });
  }

  Future<void> _handleRefresh() async{
    final agente = await Provider.of<AgenteRepository>(context, listen: false).getCurrentAgent();
    final localidadeIds = agente?.localidades.map((loc) => loc.id).toList();
     if(mounted){
       Provider.of<DenunciaService>(context, listen: false).fetchItems(localidadeIds: localidadeIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    // O Consumer agora só escuta as mudanças, não causa buscas.
    return Consumer<DenunciaService>(
      builder: (context, denunciaService, child) {
        
        // CORRIGIDO: A verificação de status agora ignora maiúsculas/minúsculas.
        final pendencias = denunciaService.items
            .where((d) => (d['status'] as String?)?.toLowerCase() != 'atendida')
            .map((item) => Denuncia.fromMap(item))
            .toList();

        return Scaffold(
          appBar: const GradientAppBar(title: 'Pendências da Localidade'),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
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
