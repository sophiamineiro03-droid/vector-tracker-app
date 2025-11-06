import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';

// ARQUIVO RESTAURADO CONFORME A INSTRUÇÃO FINALÍSSIMA
// A interface original do painel foi restaurada, e apenas a navegação foi implementada.
class PainelAceScreen extends StatelessWidget {
  const PainelAceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ocorrenciaService = context.watch<OcorrenciaSiocchagasService>();
    final denunciaService = context.watch<DenunciaService>();

    // Busca os dados em segundo plano para manter os contadores atualizados.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      denunciaService.fetchItems();
    });

    final pendenciasCount = denunciaService.items.where((d) => d['status'] != 'Atendida').length;
    final sincronizarCount = ocorrenciaService.pendentesSincronizacao.length;
    final meuTrabalhoCount = ocorrenciaService.meuTrabalho.length;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Painel do Agente'),
      // O corpo contém apenas a grade de 6 botões, como no seu design original.
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildDashboardCard(
              icon: Icons.notifications_active_outlined,
              title: 'Pendências da Localidade',
              subtitle: '$pendenciasCount denúncias aguardando',
              onTap: () => Navigator.pushNamed(context, '/pendencias_localidade'),
            ),
            _buildDashboardCard(
              icon: Icons.add_location_alt_outlined, 
              title: 'Novo Registro Proativo',
              subtitle: 'Iniciar uma nova visita de campo',
              onTap: () => Navigator.pushNamed(context, '/novo_registro_proativo'),
            ),
            _buildDashboardCard(
              icon: Icons.fact_check_outlined,
              title: 'Meu Trabalho',
              subtitle: '$meuTrabalhoCount registros concluídos',
              onTap: () => Navigator.pushNamed(context, '/meu_trabalho'),
            ),
            _buildDashboardCard(
              icon: Icons.map_outlined,
              title: 'Mapa da Área',
              subtitle: 'Visualizar pontos no mapa',
              onTap: () => Navigator.pushNamed(context, '/mapa_denuncias'),
            ),
            _buildDashboardCard(
              icon: Icons.sync,
              title: 'Sincronizar Dados',
              subtitle: '$sincronizarCount pendentes de envio',
              onTap: () => Navigator.pushNamed(context, '/sincronizar_dados'),
            ),
            _buildDashboardCard(
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

  // Widget para construir os cards para se assemelhar ao design original da imagem.
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: const Color(0xFF005b96)),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
