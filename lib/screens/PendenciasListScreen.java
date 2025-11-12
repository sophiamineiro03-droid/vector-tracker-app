import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';// Importa o repositório do agente para sabermos quem está logado
import 'package:vector_tracker_app/repositories/agente_repository.dart'; 
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';

class PendenciasListScreen extends StatefulWidget {
  const PendenciasListScreen({super.key});

  @override
  State<PendenciasListScreen> createState() => _PendenciasListScreenState();
}

class _PendenciasListScreenState extends State<PendenciasListScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Garante que os dados do agente sejam carregados primeiro
      Provider.of<AgenteRepository>(context, listen: false).getCurrentAgent().then((_) {
        // Só depois de saber quem é o agente, busca as denúncias
        Provider.of<DenunciaService>(context, listen: false).fetchItems();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Agora a tela "escuta" as mudanças tanto no serviço de denúncias
    // quanto no repositório do agente.
    final denunciaService = context.watch<DenunciaService>();
    final agentRepository = context.watch<AgenteRepository>();
    final agent = agentRepository.currentAgent;

    // Se o agente ainda não foi carregado, mostra uma tela de "carregando".
    // Isso evita erros na primeira vez que o app abre.
    if (agent == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Minhas Pendências'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // 1. Cria um conjunto com os IDs das localidades do agente.
    //    Usar um "Set" é muito mais rápido para fazer a verificação.
    final agentLocalidadeIds = agent.localidades.map((l) => l.id).toSet();
    
    // 2. A MÁGICA: O filtro agora é DUPLO.
    final pendencias = denunciaService.items
        .map((item) => Denuncia.fromMap(item)) // Primeiro, converte para o objeto Denuncia
        .where((denuncia) {
          final isPendente = denuncia.status != 'Atendida';
          // A condição CRÍTICA: A localidade da denúncia PERTENCE ao agente?
          final belongsToAgent = agentLocalidadeIds.contains(denuncia.localidade_id);
          
          return isPendente && belongsToAgent; // Só mostra se as duas condições forem verdadeiras
        })
        .toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Minhas Pendências'),
      body: RefreshIndicator(
        onRefresh: () => denunciaService.fetchItems(),
        child: denunciaService.isLoading && pendencias.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : (pendencias.isEmpty
                // Mensagem mais clara para o agente
                ? const Center(child: Text('Nenhuma pendência para suas localidades.'))
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
                    // Melhoria: Mostra o nome da localidade, que é mais útil.
                    title: Text(denuncia.localidadeNome ?? 'Localidade não informada'),
                    subtitle: Text('Endereço: ${denuncia.rua ?? "Não informado"}, ${denuncia.numero ?? ""}'),
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
  }
}