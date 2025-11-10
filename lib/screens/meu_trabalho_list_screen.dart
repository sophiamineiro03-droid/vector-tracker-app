import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
import 'package:vector_tracker_app/screens/registro_ocorrencia_agente_screen.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class MeuTrabalhoListScreen extends StatelessWidget {
  const MeuTrabalhoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentOcorrenciaService>(
      builder: (context, agentService, child) {
        final concluidas =
            agentService.ocorrencias.where((o) => o.sincronizado).toList();

        return Scaffold(
          appBar: const GradientAppBar(title: 'Meu Trabalho (Concluído)'),
          body: concluidas.isEmpty
              ? const Center(
                  child: Text('Nenhum registro sincronizado encontrado.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: concluidas.length,
                  itemBuilder: (context, index) {
                    final ocorrencia = concluidas[index];
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

    // --- CORREÇÃO APLICADA AQUI ---
    final atividades = ocorrencia.tipo_atividade?.map((e) => e.displayName).join(', ') ?? 'Não especificada';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.cloud_done, color: Colors.green),
        title: Text(
          endereco,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // E a variável é usada aqui
        subtitle: Text('Atividade de $atividades em $data'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                RegistroOcorrenciaAgenteScreen(ocorrencia: ocorrencia, isViewOnly: true),
          ),
        ),
      ),
    );
  }
}
