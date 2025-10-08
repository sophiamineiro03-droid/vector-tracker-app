import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Painel de Controle'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 colunas
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _DashboardCard(
              icon: Icons.map_outlined,
              title: 'Mapa de Trabalho',
              subtitle: 'Visualizar denúncias no mapa',
              onTap: () => Navigator.pushNamed(context, '/mapa_denuncias'),
            ),
            _DashboardCard(
              icon: Icons.view_list_outlined,
              title: 'Lista de Visitas',
              subtitle: 'Gerenciar ocorrências ativas',
              onTap: () => Navigator.pushNamed(context, '/painel_agente'),
            ),
            _DashboardCard(
              icon: Icons.bar_chart_rounded,
              title: 'Minha Produtividade',
              subtitle: 'Ver relatórios e gráficos',
              onTap: () { /* Navegação para a futura tela de produtividade */ },
            ),
            // --- CARD DE SINCRONIZAÇÃO CORRIGIDO ---
            _DashboardCard(
              icon: Icons.sync_rounded,
              title: 'Sincronizar Dados',
              subtitle: 'Ver itens pendentes de envio',
              // Ação removida para evitar crash, pois a rota '/sync' não existe
              onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tela de sincronização ainda não implementada.'))); },
            ),
            _DashboardCard(
              icon: Icons.person_outline,
              title: 'Perfil do Agente',
              subtitle: 'Sua conta e configurações',
              onTap: () { /* Navegação para a tela de perfil */ },
            ),
          ],
        ),
      ),
    );
  }
}

/// _DashboardCard: Um componente de card customizado e reutilizável para o painel.
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool enabled;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: enabled ? colorScheme.surface : colorScheme.surface.withOpacity(0.5),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: enabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: enabled ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
