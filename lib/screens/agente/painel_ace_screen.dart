// Cole este código em: lib/screens/agente/painel_ace_screen.dart

import 'package:flutter/material.dart';

// Modelo de Dados para representar cada relato
class RelatoModel {
  final String nome;
  final String horario;
  final String localizacao;

  RelatoModel({required this.nome, required this.horario, required this.localizacao});
}

// CORREÇÃO: Classe renomeada para PainelAceScreen
class PainelAceScreen extends StatefulWidget {
  const PainelAceScreen({super.key});

  @override
  State<PainelAceScreen> createState() => _PainelAceScreenState();
}

class _PainelAceScreenState extends State<PainelAceScreen> {
  final List<RelatoModel> _relatosPendentes = [
    RelatoModel(nome: 'Maria da Silva', horario: 'Há 2 horas', localizacao: 'Piauí'),
    RelatoModel(nome: 'João Pereira', horario: 'Há 5 horas', localizacao: 'Piauí'),
    RelatoModel(nome: 'Ana Costa', horario: 'Há 1 dia', localizacao: 'Piauí'),
    RelatoModel(nome: 'Carlos Souza', horario: 'Há 2 dias', localizacao: 'Piauí'),
  ];

  void _processarRelato(int index) {
    setState(() {
      _relatosPendentes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Título do AppBar atualizado para "Painel ACE"
    return Scaffold(
      appBar: _buildGradientAppBar(title: 'Painel ACE', hasBackArrow: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Text(
              'Relatos Pendentes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _relatosPendentes.length,
              itemBuilder: (context, index) {
                final relato = _relatosPendentes[index];
                return _buildRelatoCard(relato, index);
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRelatoCard(RelatoModel relato, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(relato.nome, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(relato.horario, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(relato.localizacao, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _processarRelato(index),
                  child: Text('Validar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2F80ED)),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _processarRelato(index),
                  child: Text('Rejeitar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircularButton(icon: Icons.map, label: 'Mapa de Calor'),
          _buildCircularButton(icon: Icons.description, label: 'Relatórios'),
        ],
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required String label}) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          child: Icon(icon, size: 32),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
            backgroundColor: Color(0xFF2F80ED),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

AppBar _buildGradientAppBar({required String title, bool hasBackArrow = false, List<Widget>? actions}) {
  return AppBar(
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF39B5A5), Color(0xFF2F80ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    iconTheme: IconThemeData(color: Colors.white),
    actions: actions,
    automaticallyImplyLeading: hasBackArrow,
    elevation: 4,
  );
}