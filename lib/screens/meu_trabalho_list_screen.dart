import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
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
        final ocorrenciasDoAgente = agentService.ocorrencias;

        return Scaffold(
          appBar: const GradientAppBar(title: 'Meu Histórico de Trabalho'),
          body: agentService.isLoading
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
            padding: const EdgeInsets.all(8),
            itemCount: ocorrenciasDoAgente.length,
            itemBuilder: (context, index) {
              final ocorrencia = ocorrenciasDoAgente[index];
              return _buildOcorrenciaCard(context, ocorrencia);
            },
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

    final atividades =
        ocorrencia.tipo_atividade?.map((e) => e.displayName).join(', ') ??
            'Não especificada';

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
            isFromDenuncia ? Icons.warning_amber_rounded : Icons.history,
            color: isFromDenuncia ? Colors.orangeAccent : Colors.blueGrey,
            size: 40,
          ),
        ),
        title: Text(
          endereco,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Atividade de $atividades em $data'),
        // --- ÍCONE EXTRA PARA CLAREZA ---
        trailing: Tooltip(
          message: isFromDenuncia ? 'Atendimento à Denúncia' : 'Registro Proativo',
          child: Icon(
            isFromDenuncia ? Icons.warning_amber_rounded : Icons.assignment_ind_outlined,
            color: isFromDenuncia ? Colors.orangeAccent : Colors.blueGrey[300],
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
