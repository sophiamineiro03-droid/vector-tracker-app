import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Para o modo de teste, a tela não depende mais de um agente carregado para ser exibida.
    // Os dados são consumidos, mas com valores padrão se não houver agente.

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(
          title: 'Painel do Agente', // Título genérico para o modo de teste
        ),
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          // A tela agora é exibida diretamente, usando os valores padrão do serviço.
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _DashboardCard(
                  icon: Icons.notification_important_outlined,
                  title: 'Pendências da Localidade',
                  subtitle: 'Denúncias aguardando visita',
                  onTap: () => Navigator.pushNamed(context, '/pendencias_localidade'),
                ),
                _DashboardCard(
                  icon: Icons.add_location_alt_outlined,
                  title: 'Novo Registro Proativo',
                  subtitle: 'Iniciar uma nova visita de campo',
                  onTap: () => Navigator.pushNamed(context, '/registro_ocorrencia'),
                ),
                _DashboardCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Meu Trabalho',
                  // O fallback (?? 0) garante que isso não quebre se não houver stats.
                  subtitle: '${agentService.stats['total_ocorrencias'] ?? 0} registros concluídos',
                  onTap: () => Navigator.pushNamed(context, '/painel_agente'),
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
                  subtitle: '${agentService.stats['pendentes_sync'] ?? 0} pendentes de envio',
                  trailing: _buildSyncStatus(agentService),
                  onTap: () => _performSync(context),
                ),
                 _DashboardCard(
                  icon: Icons.person_outline,
                  title: 'Perfil do Agente',
                  subtitle: 'Sua conta e configurações',
                  onTap: () { /* Navegação para /perfil_agente a ser implementada */ },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // O botão de refresh agora é a única forma de carregar os dados manualmente.
          context.read<AgentService>().loadAgentData();
        },
        tooltip: 'Atualizar dados',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSyncStatus(AgentService agentService) {
    // Esta lógica continua funcionando, pois depende do estado do serviço.
    if (agentService.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final pendingCount = agentService.stats['pendentes_sync'] ?? 0;
    if (pendingCount > 0) {
      return CircleAvatar(
        radius: 10,
        backgroundColor: Colors.orange,
        child: Text(
          '$pendingCount',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _performSync(BuildContext context) async {
    final agentService = context.read<AgentService>();
    final result = await agentService.performSync();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 32, color: colorScheme.primary),
                  if (trailing != null) trailing!,
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
