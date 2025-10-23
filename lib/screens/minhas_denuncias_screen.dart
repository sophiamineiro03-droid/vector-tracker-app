import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class MinhasDenunciasScreen extends StatefulWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  State<MinhasDenunciasScreen> createState() => _MinhasDenunciasScreenState();
}

class _MinhasDenunciasScreenState extends State<MinhasDenunciasScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CORRIGIDO: Chamada sem UID
      Provider.of<DenunciaService>(context, listen: false).fetchItems();
    });
  }

  Future<void> _navigateToDenuncia(BuildContext context, Map<String, dynamic> denuncia) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DenunciaScreen(denuncia: denuncia)),
    );
    if (result == true && mounted) {
       Provider.of<DenunciaService>(context, listen: false).fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final denunciaService = Provider.of<DenunciaService>(context);

    // CORRIGIDO: Filtro sem UID
    final denuncias = denunciaService.items.where((item) {
      return item['is_ocorrencia'] != true;
    }).toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Minhas Denúncias'),
      body: RefreshIndicator(
        // CORRIGIDO: Chamada de atualização sem UID
        onRefresh: () => denunciaService.fetchItems(),
        child: denunciaService.isLoading && denuncias.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : denuncias.isEmpty
                ? ListView( // Permite o RefreshIndicator em lista vazia
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text('Nenhuma denúncia encontrada.\nArraste para baixo para atualizar.')))],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: denuncias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final denuncia = denuncias[index];
                      return _CardDenuncia(
                        denuncia: denuncia,
                        onTap: () => _navigateToDenuncia(context, denuncia),
                      );
                    },
                  ),
      ),
    );
  }
}

class _CardDenuncia extends StatelessWidget {
  final Map<String, dynamic> denuncia;
  final VoidCallback onTap;

  const _CardDenuncia({required this.denuncia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final endereco = [denuncia['rua'], denuncia['bairro']].where((s) => s != null && s.toString().isNotEmpty).join(', ');
    final data = denuncia['created_at'];
    final imageSource = denuncia['image_path'] ?? denuncia['image_url'];

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 72, height: 72,
            child: SmartImage(imageSource: imageSource, fit: BoxFit.cover),
          ),
        ),
        title: Text(endereco.isEmpty ? 'Denúncia em ${denuncia['cidade'] ?? 'local'}' : endereco, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(data)) : 'Sem data'),
        trailing: _buildStatusIcon(denuncia),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusIcon(Map<String, dynamic> item) {
    final bool isPending = item['is_pending'] == true;
    final String status = item['status']?.toString().toLowerCase() ?? 'pendente';
    if (isPending) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 28),
          SizedBox(height: 2),
          Text('Pendente', style: TextStyle(fontSize: 10, color: Colors.orange)),
        ],
      );
    }
    switch (status) {
      case 'realizada':
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(height: 2),
            Text('Recebida', style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        );
      default:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_outlined, color: Colors.blue, size: 28),
            SizedBox(height: 2),
            Text('Enviada', style: TextStyle(fontSize: 10, color: Colors.blue)),
          ],
        );
    }
  }
}
