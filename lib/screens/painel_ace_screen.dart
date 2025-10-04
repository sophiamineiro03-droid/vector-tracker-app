import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vector_tracker_app/main.dart'; // Importa a instância do Supabase
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

// --- Tela Principal do Painel do Agente ---
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

  // Busca as denúncias no Supabase
  Future<List<Map<String, dynamic>>> _fetchDenuncias() async {
    try {
      final response = await supabase
          .from('denuncias')
          .select()
          .order('created_at', ascending: false); // Ordena pelas mais recentes
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Falha ao carregar ocorrências: $error');
    }
  }

  // Função para recarregar a lista de denúncias
  void _refreshDenuncias() {
    setState(() {
      _denunciasFuture = _fetchDenuncias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Painel do Agente'),
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Espaço extra no final
            itemCount: denuncias.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return CardOcorrencia(
                denuncia: denuncias[index],
                onStatusChanged: _refreshDenuncias, // Passa a função de callback
              );
            },
          );
        },
      ),
    );
  }
}

// --- Widget de Card de Ocorrência Interativo ---
class CardOcorrencia extends StatefulWidget {
  final Map<String, dynamic> denuncia;
  final VoidCallback onStatusChanged; // Callback para notificar a tela principal

  const CardOcorrencia({
    super.key,
    required this.denuncia,
    required this.onStatusChanged,
  });

  @override
  State<CardOcorrencia> createState() => _CardOcorrenciaState();
}

class _CardOcorrenciaState extends State<CardOcorrencia> {
  bool _isUpdating = false;

  // Função para atualizar o status no Supabase
  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await supabase
          .from('denuncias')
          .update({'status': newStatus})
          .eq('id', widget.denuncia['id']);

      // Notifica a tela principal para recarregar a lista
      widget.onStatusChanged();

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao atualizar status: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? originalImageUrl = widget.denuncia['image_url'];
    // OTIMIZAÇÃO: Cria uma URL para uma versão redimensionada da imagem
    final String? thumbnailUrl = originalImageUrl != null
        ? originalImageUrl.replaceFirst(
            '/object/public/',
            '/render/image/public/',
          ) + '?width=440&height=220&resize=cover'
        : null;

    final descricao = widget.denuncia['descricao'] ?? 'Nenhuma descrição fornecida.';
    final endereco = _construirEndereco();
    final data = _formatarData(widget.denuncia['created_at']);
    final status = widget.denuncia['status'] ?? 'Pendente';

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem - Agora usa a URL otimizada
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(heightFactor: 4, child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => Container(
                height: 220,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descrição
                const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(descricao, style: const TextStyle(fontSize: 15)),
                const Divider(height: 24),

                // Endereço
                const Text('Localização:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(endereco, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text('Registrado em: $data', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 20),

                // Ações do Agente
                _buildAgentActions(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Constrói os botões de ação ou o chip de status
  Widget _buildAgentActions(String status) {
    if (_isUpdating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status.toLowerCase() == 'pendente') {
      return Row(
        children: [
          Expanded(child: _buildActionButton('Rejeitar', Icons.close, Colors.red, () => _updateStatus('Rejeitado'))),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('Validar', Icons.check, Colors.green, () => _updateStatus('Validado'))),
        ],
      );
    }

    // Se já foi validado ou rejeitado, mostra um chip com o status
    return Center(
      child: Chip(
        label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _getStatusColor(status),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Widget para criar os botões de ação
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // Funções auxiliares
  String _formatarData(String dataString) => DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dataString));

  String _construirEndereco() {
    final parts = [widget.denuncia['rua'], widget.denuncia['numero'], widget.denuncia['bairro'], widget.denuncia['cidade'], widget.denuncia['estado']]
        .where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    return parts.isEmpty ? "Endereço não informado" : parts;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'validado': return Colors.green;
      case 'rejeitado': return Colors.red;
      default: return Colors.orange;
    }
  }
}
