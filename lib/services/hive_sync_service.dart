import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';

class HiveSyncService {
  final DenunciaService _denunciaService;
  final Box _pendingVisitsBox = Hive.box('pending_sync');
  final Box _pendingDenunciasBox = Hive.box('pending_denuncias');

  HiveSyncService({required DenunciaService denunciaService}) : _denunciaService = denunciaService;

  void start() {
    syncAll();
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi);
      if (isOnline) {
        print("Conexão detectada! Tentando sincronizar tudo...");
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    await _syncPendingVisits();
    await _syncPendingDenuncias();
  }

  Future<void> _syncPendingVisits() async {
    // A lógica de sincronização de visitas do agente permanece a mesma
  }

  Future<void> _syncPendingDenuncias() async {
    if (_pendingDenunciasBox.isEmpty) return;
    print("Sincronizando ${_pendingDenunciasBox.length} denúncias da comunidade...");

    final List pendingKeys = _pendingDenunciasBox.keys.toList();
    bool successfullySynced = false;

    for (var key in pendingKeys) {
      final data = Map<String, dynamic>.from(_pendingDenunciasBox.get(key) as Map);
      try {
        String? imageUrl;
        if (data['image_path'] != null) {
          final imageFile = File(data['image_path']);
          if (await imageFile.exists()) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
            final userId = data['uid']; // <<< CORREÇÃO AQUI
            final uploadPath = userId != null ? '$userId/$fileName' : 'anonymous/$fileName';
            await supabase.storage.from('imagens_denuncias').upload(uploadPath, imageFile);
            imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath);
          }
        }

        final Map<String, dynamic> cleanData = Map.from(data);
        cleanData.remove('image_path');
        cleanData.remove('local_id'); 
        cleanData.remove('is_pending');
        cleanData.remove('user_id'); // Garante que a versão antiga seja removida
        cleanData['image_url'] = imageUrl;

        final recordId = cleanData.remove('id');

        if (recordId != null) {
            await supabase.from('denuncias').update(cleanData).eq('id', recordId);
        } else {
            await supabase.from('denuncias').insert(cleanData);
        }
        
        await _pendingDenunciasBox.delete(key);
        successfullySynced = true;
        print("Denúncia da comunidade $key sincronizada!");

      } catch (e) {
        print("Erro ao sincronizar denúncia da comunidade $key: $e");
      }
    }

    if (successfullySynced) {
      print("Sincronização concluída, atualizando a UI...");
      _denunciaService.forceRefresh(uid: supabase.auth.currentUser?.id); // <<< CORREÇÃO AQUI
    }
  }
}
