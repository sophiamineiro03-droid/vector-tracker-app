import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class MeuTrabalhoListScreen extends StatefulWidget {
  const MeuTrabalhoListScreen({super.key});

  @override
  State<MeuTrabalhoListScreen> createState() => _MeuTrabalhoListScreenState();
}

class _MeuTrabalhoListScreenState extends State<MeuTrabalhoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgentOcorrenciaService>(context, listen: false).fetchOcorrencias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentOcorrenciaService>(
      builder: (context, agentService, child) {
        // Ordena a lista do mais recente para o mais antigo
        final ocorrenciasDoAgente = List<Ocorrencia>.from(agentService.ocorrencias);
        ocorrenciasDoAgente.sort((a, b) {
           final dateA = a.data_atividade ?? a.created_at ?? DateTime(2000);
           final dateB = b.data_atividade ?? b.created_at ?? DateTime(2000);
           return dateB.compareTo(dateA); // Decrescente
        });

        return Scaffold(
          appBar: const GradientAppBar(title: 'Meu Histórico de Trabalho'),
          body: SafeArea(
            child: agentService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ocorrenciasDoAgente.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum registro de trabalho encontrado para seu usuário.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: ocorrenciasDoAgente.length,
              itemBuilder: (context, index) {
                final ocorrencia = ocorrenciasDoAgente[index];
                return _buildOcorrenciaCard(context, ocorrencia);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOcorrenciaCard(BuildContext context, Ocorrencia ocorrencia) {
    final endereco =
        '${ocorrencia.endereco ?? 'Endereço não informado'}, ${ocorrencia.numero ?? 'S/N'}';
    final data = ocorrencia.data_atividade != null
        ? DateFormat('dd/MM/yyyy').format(ocorrencia.data_atividade!)
        : 'Data indisponível';

    // LÓGICA MELHORADA DE SELEÇÃO DE IMAGEM
    String? displayImage;

    // 1. Tenta encontrar um arquivo LOCAL real primeiro (prioridade máxima offline)
    if (ocorrencia.localImagePaths != null && ocorrencia.localImagePaths!.isNotEmpty) {
      try {
        displayImage = ocorrencia.localImagePaths!.firstWhere(
          (path) => !path.startsWith('http'), 
          orElse: () => '' // Retorna vazio se não achar, para tratar abaixo
        );
        if (displayImage!.isEmpty) displayImage = null;
      } catch (e) {
        displayImage = null;
      }
    }

    // 2. Se não achou arquivo local, usa o primeiro path disponível (mesmo que seja URL, ex: foto da denúncia)
    if (displayImage == null && ocorrencia.localImagePaths != null && ocorrencia.localImagePaths!.isNotEmpty) {
       displayImage = ocorrencia.localImagePaths!.first;
    }

    // 3. Se ainda não tem, tenta urls confirmadas do servidor
    if (displayImage == null && ocorrencia.fotos_urls != null && ocorrencia.fotos_urls!.isNotEmpty) {
      displayImage = ocorrencia.fotos_urls!.first;
    }

    final isFromDenuncia = ocorrencia.denuncia_id != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: displayImage != null
              ? SmartImage(imageSource: displayImage, fit: BoxFit.cover)
              : Icon(
            Icons.assignment_turned_in,
            color: isFromDenuncia ? Colors.green : Colors.blue,
            size: 40,
          ),
        ),
        title: Text(
          endereco,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Atividade em $data'),
        trailing: Tooltip(
          message: isFromDenuncia ? 'Atendimento à Denúncia' : 'Registro Proativo',
          child: Icon(
            Icons.assignment_turned_in,
            color: isFromDenuncia ? Colors.green : Colors.blue,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistroOcorrenciaAgenteScreen(
                ocorrencia: ocorrencia, isViewOnly: false),
          ),
        ),
      ),
    );
  }
}
