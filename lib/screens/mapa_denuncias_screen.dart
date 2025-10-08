import 'dart:io'; // Importa a biblioteca para manipulação de arquivos
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class MapaDenunciasScreen extends StatelessWidget {
  const MapaDenunciasScreen({super.key});

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<Marker> _createMarkers(BuildContext context, List<Map<String, dynamic>> denuncias) {
    return denuncias.map((denuncia) {
      final lat = _parseDouble(denuncia['latitude']);
      final lon = _parseDouble(denuncia['longitude']);

      if (lat == null || lon == null) return null;

      final isPending = denuncia['is_pending'] ?? false;
      final status = denuncia['status']?.toString().toLowerCase() ?? 'pendente';

      Color markerColor;
      if (isPending) {
        markerColor = Colors.orange;
      } else if (status == 'realizada') {
        markerColor = Colors.green;
      } else if (status == 'fechado' || status == 'recusada') {
        markerColor = Colors.red;
      } else {
        markerColor = Colors.blue;
      }

      return Marker(
        width: 40.0, height: 40.0, point: LatLng(lat, lon),
        child: GestureDetector(
          onTap: () => _showDenunciaDetails(context, denuncia),
          child: Icon(Icons.location_pin, color: markerColor, size: 40.0),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showDenunciaDetails(BuildContext context, Map<String, dynamic> denuncia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- LÓGICA DE IMAGEM OFFLINE-FIRST ---
        final imagePath = denuncia['image_path'] as String?;
        final imageUrl = denuncia['agent_image_url'] ?? denuncia['image_url'] as String?;
        final endereco = [denuncia['rua'], denuncia['numero'], denuncia['bairro']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
        final descricao = denuncia['descricao'] ?? 'Nenhuma descrição fornecida.';
        final status = (denuncia['status'] as String?)?.toUpperCase() ?? 'PENDENTE';
        final isPending = denuncia['is_pending'] ?? false;

        Widget imageWidget;
        if (imagePath != null) {
          imageWidget = Image.file(File(imagePath), height: 200, width: double.infinity, fit: BoxFit.cover);
        } else if (imageUrl != null) {
          imageWidget = Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (ctx, err, stack) => Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48))),
          );
        } else {
          imageWidget = Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48)));
        }

        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.5, maxChildSize: 0.9, minChildSize: 0.3,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  Text('Detalhes da Ocorrência', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: imageWidget),
                  const SizedBox(height: 20),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isPending ? Colors.orange.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(isPending ? 'PENDENTE DE SINCRONIZAÇÃO' : status, style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.orange.shade800 : Colors.blue.shade800)),
                  ),
                  const Divider(height: 24),
                  const Text('Localização', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(endereco.isEmpty ? 'Endereço não informado' : endereco, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 24),
                  const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(descricao, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DenunciaService()..fetchDenuncias(),
      child: Scaffold(
        appBar: const GradientAppBar(title: 'Mapa de Ocorrências (OpenStreetMap)'),
        body: Consumer<DenunciaService>(
          builder: (context, denunciaService, child) {
            if (denunciaService.isLoading && denunciaService.denuncias.isEmpty) return const Center(child: CircularProgressIndicator());
            if (denunciaService.denuncias.isEmpty) return const Center(child: Text('Nenhuma ocorrência para exibir no mapa.'));

            final markers = _createMarkers(context, denunciaService.denuncias);

            MapOptions mapOptions;
            if (markers.length > 1) {
              final bounds = LatLngBounds.fromPoints(markers.map((m) => m.point).toList());
              mapOptions = MapOptions(bounds: bounds, boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50.0)), interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate));
            } else {
              final initialCenter = markers.isNotEmpty ? markers.first.point : const LatLng(-14.235, -51.9253);
              mapOptions = MapOptions(initialCenter: initialCenter, initialZoom: markers.isNotEmpty ? 15.0 : 4.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate));
            }

            return FlutterMap(
              options: mapOptions,
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.vector_tracker_app',
                ),
                if (markers.isNotEmpty)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      zoomToBoundsOnClick: true,
                      markers: markers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blue,
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
