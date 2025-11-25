import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/dashboard_card.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Carrega o agente para obter as localidades e filtrar as denúncias corretamente
      final agenteRepository = Provider.of<AgenteRepository>(context, listen: false);
      final agente = await agenteRepository.getCurrentAgent();
      final localidadeIds = agente?.localidades.map((loc) => loc.id).toList();

      if (mounted) {
        Provider.of<AgentOcorrenciaService>(context, listen: false).fetchOcorrencias();
        // Aplica o filtro de localidades também na tela inicial para que os números batam com a lista
        Provider.of<DenunciaService>(context, listen: false).fetchItems(localidadeIds: localidadeIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(title: 'Painel do Agente'),
      ),
      body: Consumer2<AgentOcorrenciaService, DenunciaService>(
        builder: (context, agentService, denunciaService, child) {
          final pendenciasCount = denunciaService.items
              .where((d) => (d['status'] as String?)?.toLowerCase() != 'atendida')
              .length;
          
          // Usa o getter específico para contagem de sincronização
          final sincronizarCount = agentService.pendingSyncCount;
          
          // Usa o tamanho da lista de histórico para "Meu Trabalho"
          final meuTrabalhoCount = agentService.ocorrencias.length;

          final isLoading = (agentService.isLoading && agentService.ocorrencias.isEmpty) ||
              (denunciaService.isLoading && denunciaService.items.isEmpty);

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              final agenteRepository = Provider.of<AgenteRepository>(context, listen: false);
              final agente = await agenteRepository.getCurrentAgent();
              final localidadeIds = agente?.localidades.map((loc) => loc.id).toList();
              
              if (context.mounted) {
                await agentService.fetchOcorrencias();
                await denunciaService.fetchItems(localidadeIds: localidadeIds);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  DashboardCard(
                    icon: Icons.notification_important_outlined,
                    title: 'Pendências da Localidade',
                    subtitle: '$pendenciasCount denúncias aguardando',
                    onTap: () =>
                        Navigator.pushNamed(context, '/pendencias_localidade'),
                  ),
                  DashboardCard(
                    icon: Icons.add_location_alt_outlined,
                    title: 'Novo Registro Proativo',
                    subtitle: 'Iniciar uma nova visita de campo',
                    onTap: () =>
                        Navigator.pushNamed(context, '/novo_registro_proativo'),
                  ),
                  DashboardCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Meu Trabalho',
                    subtitle: '$meuTrabalhoCount registros concluídos',
                    onTap: () => Navigator.pushNamed(context, '/meu_trabalho'),
                  ),
                  DashboardCard(
                    icon: Icons.map_outlined,
                    title: 'Mapa da Área',
                    subtitle: 'Visualizar pontos no mapa',
                    onTap: () => Navigator.pushNamed(context, '/mapa_denuncias'),
                  ),
                  DashboardCard(
                    icon: Icons.sync_rounded,
                    title: 'Sincronizar Dados',
                    subtitle: '$sincronizarCount pendentes de envio',
                    onTap: () =>
                        Navigator.pushNamed(context, '/sincronizar_dados'),
                  ),
                  DashboardCard(
                    icon: Icons.person_outline,
                    title: 'Perfil do Agente',
                    subtitle: 'Sua conta e configurações',
                    onTap: () {
                      Navigator.pushNamed(context, '/agent_profile');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
