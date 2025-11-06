import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

// CORREÇÃO FINALÍSSIMA: Usando o painel original do usuário (AgentHomeScreen) 
// e apenas implementando a navegação correta e os contadores atualizados.
class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usando os providers novos para obter os contadores para os cards
    final ocorrenciaService = context.watch<OcorrenciaSiocchagasService>();
    final denunciaService = context.watch<DenunciaService>();

    // Busca os dados em segundo plano para manter os contadores atualizados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      denunciaService.fetchItems();
    });

    final pendenciasCount = denunciaService.items.where((d) => d['status'] != 'Atendida').length;
    final sincronizarCount = ocorrenciaService.pendentesSincronizacao.length;
    final meuTrabalhoCount = ocorrenciaService.meuTrabalho.length;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: GradientAppBar(title: 'Painel do Agente'),
      ),
      body: Padding(
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
              onTap: () => Navigator.pushNamed(context, '/pendencias_localidade'),
            ),
            _DashboardCard(
              icon: Icons.add_location_alt_outlined,
              title: 'Novo Registro Proativo',
              subtitle: 'Iniciar uma nova visita de campo',
              onTap: () => Navigator.pushNamed(context, '/novo_registro_proativo'),
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
              onTap: () => Navigator.pushNamed(context, '/sincronizar_dados'),
            ),
             _DashboardCard(
              icon: Icons.person_outline,
              title: 'Perfil do Agente',
              subtitle: 'Sua conta e configurações',
              onTap: () { 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tela de Perfil a ser implementada.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget interno do card, mantido exatamente como no seu código original.
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
