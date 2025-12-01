import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/screens/image_viewer_screen.dart';

class PendenciasListScreen extends StatefulWidget {
  const PendenciasListScreen({super.key});

  @override
  State<PendenciasListScreen> createState() => _PendenciasListScreenState();
}

class _PendenciasListScreenState extends State<PendenciasListScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPendencias();
    });
  }

  Future<void> _loadPendencias() async {
    final agente = await Provider.of<AgenteRepository>(context, listen: false).getCurrentAgent();
    final localidadeIds = agente?.localidades.map((loc) => loc.id).toList();
    final municipioId = agente?.municipioId;
    
    if(mounted){
       await Provider.of<DenunciaService>(context, listen: false).fetchItems(
         localidadeIds: localidadeIds,
         municipioId: municipioId
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DenunciaService>(
      builder: (context, denunciaService, child) {
        
        final pendencias = denunciaService.items
            .where((d) {
               final status = (d['status'] as String?)?.toLowerCase();
               return status != 'atendida' && status != 'recusada';
            })
            .map((item) => Denuncia.fromMap(item))
            .toList();

        return Scaffold(
          appBar: const GradientAppBar(title: 'Pendências do Município'),
          body: RefreshIndicator(
            onRefresh: _loadPendencias,
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
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesTriagemScreen(denuncia: denuncia),
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

// --- TELA DE TRIAGEM AJUSTADA (Versão Final: Contain + Fundo Branco + SafeArea + Dados Completos + Zoom Corrigido) ---
class DetalhesTriagemScreen extends StatelessWidget {
  final Denuncia denuncia;

  const DetalhesTriagemScreen({super.key, required this.denuncia});

  void _recusarDenuncia(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Denúncia?'),
        content: const Text('Ao descartar, você confirma que a foto NÃO É de um barbeiro ou que a denúncia é inválida.\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              
              await Provider.of<DenunciaService>(context, listen: false)
                  .updateDenunciaStatus(denuncia.id, 'recusada');
                  
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Denúncia descartada.')));
            },
            child: const Text('Sim, Descartar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _atenderDenuncia(BuildContext context) {
    Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => RegistroOcorrenciaAgenteScreen(
           denunciaOrigem: denuncia,
         ),
       ),
    ).then((realizouAtendimento) {
      if (realizouAtendimento == true) {
        Navigator.pop(context);
      }
    });
  }
  
  void _abrirZoom(BuildContext context) {
    if (denuncia.foto_url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // CORREÇÃO AQUI: Usando .single
          builder: (context) => ImageViewerScreen.single(imageUrl: denuncia.foto_url!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: const GradientAppBar(title: 'Análise da Denúncia'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOTO NO TOPO
                  Container(
                    width: double.infinity,
                    height: 350, // Altura boa para ver bem
                    color: Colors.white, // Fundo BRANCO (faixas brancas)
                    child: Stack(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () => _abrirZoom(context),
                            child: denuncia.foto_url != null
                                ? Hero(
                                    tag: denuncia.foto_url!,
                                    // AQUI ESTÁ O SEGREDO: contain
                                    // Vai mostrar a foto inteira sem cortar nada
                                    child: SmartImage(imageSource: denuncia.foto_url!, fit: BoxFit.contain),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Sem foto disponível', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                          ),
                        ),
                        // Indicador de zoom (ícone de lupa) CLICÁVEL
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _abrirZoom(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black12, // Levemente escuro só pra ver o ícone no branco
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in, color: Colors.black54, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),

                  // DADOS ABAIXO DA FOTO
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Endereço:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(
                          '${denuncia.rua ?? 'Rua não informada'}, ${denuncia.numero ?? 'S/N'}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        
                        // BAIRRO (Sempre mostra)
                        Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Bairro: ${denuncia.bairro ?? 'Não informado'}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),

                        // COMPLEMENTO (Sempre mostra, por extenso)
                        Row(
                          children: [
                            const Icon(Icons.home_work_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded( // Expanded para textos longos não quebrarem layout
                              child: Text(
                                'Complemento: ${denuncia.complemento != null && denuncia.complemento!.isNotEmpty ? denuncia.complemento : 'Não informado'}',
                                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text('Relato do Morador:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!)
                          ),
                          child: Text(
                            denuncia.descricao ?? 'Nenhuma descrição fornecida.',
                            style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // BARRA DE AÇÃO (COM SAFE AREA)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              top: false, // Só protege embaixo (barra de navegação)
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _recusarDenuncia(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('DESCARTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _atenderDenuncia(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('ATENDER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Verde sólido para ação positiva
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
