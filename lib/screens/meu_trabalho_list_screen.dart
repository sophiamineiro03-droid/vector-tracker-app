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
      Provider.of<AgentOcorrenciaService>(context, listen: false).forceRefresh();
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
          // SafeArea garante que o conteúdo não fique embaixo das barras do sistema
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
              // Adiciona um padding extra na parte inferior para garantir que o último item não fique colado na borda
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

    final firstImage =
    ocorrencia.fotos_urls?.isNotEmpty == true ? ocorrencia.fotos_urls!.first : null;

    // --- LÓGICA DE DIFERENCIAÇÃO ---
    final isFromDenuncia = ocorrencia.denuncia_id != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: firstImage != null
              ? SmartImage(imageSource: firstImage, fit: BoxFit.cover)
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
        // --- ÍCONE EXTRA PARA CLAREZA ---
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
