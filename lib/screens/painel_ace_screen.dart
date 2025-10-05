import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/screens/visit_details_screen.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class PainelAceScreen extends StatefulWidget {
  const PainelAceScreen({super.key});

  @override
  State<PainelAceScreen> createState() => _PainelAceScreenState();
}

class _PainelAceScreenState extends State<PainelAceScreen> {
  late Future<List<Map<String, dynamic>>> _denunciasFuture;

  @override
  void initState() {
    super.initState();
    _denunciasFuture = _fetchDenuncias();
  }

  Future<List<Map<String, dynamic>>> _fetchDenuncias() async {
    try {
      final response = await supabase.from('denuncias').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Falha ao carregar ocorrências: $error');
    }
  }

  Future<void> _navigateToVisit(Map<String, dynamic> denuncia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // CORREÇÃO: Passando os dados da denúncia para a tela de detalhes
        builder: (context) => VisitDetailsScreen(denuncia: denuncia),
      ),
    );
    setState(() {
      _denunciasFuture = _fetchDenuncias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Lista de Visitas'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _denunciasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final denuncias = snapshot.data;
          if (denuncias == null || denuncias.isEmpty) {
            return const Center(child: Text('Nenhuma ocorrência encontrada.'));
          }

          return RefreshIndicator(
            onRefresh: _fetchDenuncias,
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: denuncias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final denuncia = denuncias[index];
                return CardOcorrencia(
                  denuncia: denuncia,
                  onTap: () => _navigateToVisit(denuncia),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CardOcorrencia extends StatelessWidget {
  final Map<String, dynamic> denuncia;
  final VoidCallback onTap;

  const CardOcorrencia({super.key, required this.denuncia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final endereco = _construirEndereco();
    final data = _formatarData(denuncia['created_at']);
    final status = denuncia['status'] ?? 'Pendente';

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildStatusIcon(status),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(endereco, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(data, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _construirEndereco() {
    final parts = [denuncia['rua'], denuncia['numero'], denuncia['bairro']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    return parts.isEmpty ? "Endereço não informado" : parts;
  }

  String _formatarData(String dataString) => DateFormat('dd/MM/yyyy').format(DateTime.parse(dataString));

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status.toLowerCase()) {
      case 'validado':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'rejeitado':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      case 'realizada':
        icon = Icons.location_on_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.pending_rounded;
        color = Colors.orange;
    }
    return Icon(icon, color: color, size: 32);
  }
}
