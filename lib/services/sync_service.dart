import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vector_tracker_app/services/database_helper.dart';
import 'package:vector_tracker_app/main.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void start() {
    syncPendingVisits();
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi)) {
        print("Conexão detectada! Tentando sincronizar...");
        syncPendingVisits();
      }
    });
  }

  Future<void> syncPendingVisits() async {
    final pendingVisits = await _dbHelper.getPendingVisits();
    if (pendingVisits.isEmpty) {
      print("Nenhuma visita pendente para sincronizar.");
      return;
    }

    print("Sincronizando ${pendingVisits.length} visitas pendentes...");

    for (var visit in pendingVisits) {
      final uniqueId = visit['unique_id'] as String;
      Map<String, dynamic> data;
      try {
        data = jsonDecode(visit['data'] as String);
      } catch (e) {
        print("Erro ao decodificar dados da visita $uniqueId. Ignorando.");
        continue;
      }

      try {
        final Map<String, dynamic> cleanData = Map<String, dynamic>.from(data);
        cleanData.remove('created_at'); // NUNCA enviar created_at para o Supabase
        cleanData.remove('unique_id');
        cleanData.remove('is_pending');

        if (cleanData['id'] == null) {
          cleanData.remove('id');
          await supabase.from('denuncias').insert(cleanData);
        } else {
          final recordId = cleanData.remove('id');
          await supabase.from('denuncias').update(cleanData).eq('id', recordId);
        }

        await _dbHelper.deletePendingVisit(uniqueId);
        print("Visita $uniqueId sincronizada com sucesso!");
      } catch (e) {
        print("Erro ao sincronizar visita $uniqueId: $e");
      }
    }
  }
}
