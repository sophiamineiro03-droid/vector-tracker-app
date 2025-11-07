import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

// Convertido para StatefulWidget para carregar os dados apenas uma vez.
class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Este código agora é executado apenas UMA VEZ quando a tela é criada.
    // Isso conserta o loop infinito.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CORREÇÃO: Usando o novo AgentOcorrenciaService
      Provider.of<AgentOcorrenciaService>(context, listen: false).fetchOcorrencias();
      Provider.of<DenunciaService>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(title: 'Painel do Agente'),
      ),
      // CORREÇÃO: O Consumer agora usa o novo AgentOcorrenciaService
      body: Consumer2<AgentOcorrenciaService, DenunciaService>(
        builder: (context, agentService, denunciaService, child) {
          final pendenciasCount = denunciaService.items
              .where((d) => d['status'] != 'Atendida')
              .length;
          // CORREÇÃO: Os contadores agora usam o 'ocorrencias' do novo serviço.
          final sincronizarCount = agentService.ocorrencias
              .where((o) => o.sincronizado == false)
              .length;
          final meuTrabalhoCount = agentService.ocorrencias
              .where((o) => o.sincronizado == true)
              .length;

          // A tela de loading agora reflete o estado real do carregamento inicial.
          final isLoading = (agentService.isLoading && agentService.ocorrencias.isEmpty) ||
              (denunciaService.isLoading && denunciaService.items.isEmpty);

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              // CORREÇÃO: O force: true foi removido daqui.
              await agentService.fetchOcorrencias();
              await denunciaService.fetchItems();
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _DashboardCard(
                    icon: Icons.notification_important_outlined,
                    title: 'Pendências da Localidade',
                    subtitle: '$pendenciasCount denúncias aguardando',
                    onTap: () =>
                        Navigator.pushNamed(context, '/pendencias_localidade'),
                  ),
                  _DashboardCard(
                    icon: Icons.add_location_alt_outlined,
                    title: 'Novo Registro Proativo',
                    subtitle: 'Iniciar uma nova visita de campo',
                    onTap: () =>
                        Navigator.pushNamed(context, '/novo_registro_proativo'),
                  ),
                  _DashboardCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Meu Trabalho',
                    subtitle: '$meuTrabalhoCount registros concluídos',
                    onTap: () => Navigator.pushNamed(context, '/meu_trabalho'),
                  ),
                  _DashboardCard(
                    icon: Icons.map_outlined,
                    title: 'Mapa da Área',
                    subtitle: 'Visualizar pontos no mapa',
                    onTap: () => Navigator.pushNamed(context, '/mapa_denuncias'),
                  ),
                  _DashboardCard(
                    icon: Icons.sync_rounded,
                    title: 'Sincronizar Dados',
                    subtitle: '$sincronizarCount pendentes de envio',
                    onTap: () =>
                        Navigator.pushNamed(context, '/sincronizar_dados'),
                  ),
                  _DashboardCard(
                    icon: Icons.person_outline,
                    title: 'Perfil do Agente',
                    subtitle: 'Sua conta e configurações',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tela de Perfil a ser implementada.')),
                      );
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

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
