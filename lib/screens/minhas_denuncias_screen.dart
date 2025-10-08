import 'dart:io'; // Importa a biblioteca para manipulação de arquivos
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/main.dart'; // Para supabase
import 'package:vector_tracker_app/screens/denuncia_screen.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class MinhasDenunciasScreen extends StatelessWidget {
  const MinhasDenunciasScreen({super.key});

  Future<void> _navigateToDenuncia(BuildContext context, DenunciaService service, Map<String, dynamic> denuncia) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DenunciaScreen(denuncia: denuncia)),
    );
    if (result == true) {
      final uid = supabase.auth.currentUser?.id;
      service.fetchDenuncias(uid: uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = supabase.auth.currentUser?.id;
    return ChangeNotifierProvider(
      create: (_) => DenunciaService()..fetchDenuncias(uid: uid),
      child: Scaffold(
        appBar: const GradientAppBar(title: 'Minhas Denúncias'),
        body: Consumer<DenunciaService>(
          builder: (context, denunciaService, child) {
            if (denunciaService.isLoading && denunciaService.denuncias.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final denuncias = denunciaService.denuncias;

            if (denuncias.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => denunciaService.fetchDenuncias(uid: uid),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(child: Text('Nenhuma denúncia encontrada.\nPuxe para baixo para atualizar.')),
                    )
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => denunciaService.fetchDenuncias(uid: uid),
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: denuncias.length,
                itemBuilder: (context, index) {
                  final denuncia = denuncias[index];
                  final isPending = denuncia['is_pending'] ?? false;
                  final endereco = [denuncia['rua'], denuncia['bairro']].where((s) => s != null && s.toString().isNotEmpty).join(', ');
                  final data = denuncia['created_at'];
                  
                  // --- LÓGICA DE IMAGEM OFFLINE-FIRST ---
                  final imagePath = denuncia['image_path'] as String?;
                  final imageUrl = denuncia['image_url'] as String?;

                  Widget imageThumbnail;
                  if (imagePath != null) {
                    // 1. Se houver um caminho de arquivo local, use Image.file
                    imageThumbnail = Image.file(File(imagePath), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                  } else if (imageUrl != null) {
                    // 2. Senão, tente carregar da internet com Image.network
                    imageThumbnail = Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                      loadingBuilder: (ctx, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    );
                  } else {
                    // 3. Se não houver nenhum, mostre um placeholder
                    imageThumbnail = const Icon(Icons.image_not_supported_outlined, color: Colors.grey);
                  }

                  return Card(
                    elevation: 2.0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      // --- WIDGET DA IMAGEM ---
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: imageThumbnail,
                        ),
                      ),
                      title: Text(endereco.isEmpty ? 'Denúncia em ${denuncia['cidade'] ?? 'local desconhecido'}' : endereco, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data)) : 'Data não disponível'),
                      // --- ÍCONE DE STATUS ---
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isPending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined, color: isPending ? Colors.orange : Colors.green, size: 28),
                          const SizedBox(height: 2),
                          Text(isPending ? 'Pendente' : 'Enviada', style: TextStyle(fontSize: 10, color: isPending ? Colors.orange : Colors.green))
                        ],
                      ),
                      onTap: () => _navigateToDenuncia(context, denunciaService, denuncia),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
