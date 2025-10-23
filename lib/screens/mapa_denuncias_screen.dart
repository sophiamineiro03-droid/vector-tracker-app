import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster, ClusterManager;
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class Place with ClusterItem {
  final Map<String, dynamic> denuncia;

  Place({required this.denuncia});

  @override
  LatLng get location {
    final lat = _parseDouble(denuncia['latitude']);
    final lon = _parseDouble(denuncia['longitude']);
    return LatLng(lat ?? 0.0, lon ?? 0.0);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class MapaDenunciasScreen extends StatefulWidget {
  const MapaDenunciasScreen({super.key});

  @override
  State<MapaDenunciasScreen> createState() => _MapaDenunciasScreenState();
}

class _MapaDenunciasScreenState extends State<MapaDenunciasScreen> {
  late ClusterManager _clusterManager;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  late DenunciaService _denunciaService;

  @override
  void initState() {
    super.initState();
    _clusterManager = _initClusterManager();
    // Garante que a busca de dados ocorra após a construção da primeira frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _denunciaService = Provider.of<DenunciaService>(context, listen: false);
      _denunciaService.addListener(_updateDenunciasOnMap);
      _denunciaService.fetchItems();
    });
  }

  // O didChangeDependencies não é mais necessário para a busca inicial

  void _updateDenunciasOnMap() {
    if (mounted) {
      final denuncias = _denunciaService.items.where((item) => 
        item['is_ocorrencia'] != true && 
        Place._parseDouble(item['latitude']) != null && 
        Place._parseDouble(item['longitude']) != null
      ).toList();

      final places = _getPlaces(denuncias);
      if (places.isNotEmpty) {
        _clusterManager.setItems(places);
      }
    }
  }

  ClusterManager _initClusterManager() {
    return ClusterManager<Place>([], _updateMarkers, markerBuilder: _markerBuilder);
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  @override
  void dispose() {
    _denunciaService.removeListener(_updateDenunciasOnMap);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Mapa de Denúncias'),
      body: Consumer<DenunciaService>(
        builder: (context, denunciaService, child) {
          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: const CameraPosition(
                    target: LatLng(-14.235, -51.9253), zoom: 4.0),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  _clusterManager.setMapId(controller.mapId);
                },
                onCameraMove: _clusterManager.onCameraMove,
                onCameraIdle: _clusterManager.updateMap,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              if (denunciaService.isLoading && denunciaService.items.isEmpty)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  List<Place> _getPlaces(List<Map<String, dynamic>> denuncias) {
    return denuncias.map((d) => Place(denuncia: d)).toList();
  }

  LatLngBounds _boundsFromCluster(Cluster<Place> cluster) {
    final locations = cluster.items.map((p) => p.location).toList();
    double minLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLat = locations.first.latitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }


  Future<Marker> Function(Cluster<Place>) get _markerBuilder => (cluster) async {
    if (!cluster.isMultiple) {
      final place = cluster.items.first;
      final isPending = place.denuncia['is_pending'] ?? false;
      final status = place.denuncia['status']?.toString().toLowerCase() ?? 'pendente';

      double markerColorHue;
      if (isPending) {
        markerColorHue = BitmapDescriptor.hueOrange;
      } else if (status == 'realizada') {
        markerColorHue = BitmapDescriptor.hueGreen;
      } else if (status == 'fechado' || status == 'recusada') {
        markerColorHue = BitmapDescriptor.hueRed;
      } else {
        markerColorHue = BitmapDescriptor.hueAzure;
      }

      return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () => _showDenunciaDetails(context, place.denuncia),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColorHue));
    }

    final int size = cluster.count;
    final icon = await _getMarkerBitmap(125, text: size.toString());

    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: icon,
      onTap: () async {
        final controller = await _controller.future;
        final bounds = _boundsFromCluster(cluster);
        if (bounds.northeast == bounds.southwest) {
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: cluster.location, zoom: 18.0),
          ));
        } else {
          controller.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 60.0));
        }
      },
    );
  };

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {required String text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.red.withOpacity(0.85);
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.4, paint1);

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: TextStyle(
          fontSize: size / 3, color: Colors.white, fontWeight: FontWeight.bold),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _showDenunciaDetails(BuildContext context, Map<String, dynamic> denuncia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final imagePath = denuncia['image_path'] as String?;
        final imageUrl = denuncia['agent_image_url'] ?? denuncia['image_url'] as String?;
        final endereco = [
          denuncia['rua'],
          denuncia['numero'],
          denuncia['bairro']
        ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
        final descricao = denuncia['descricao'] ?? 'Nenhuma descrição fornecida.';
        final status = (denuncia['status'] as String?)?.toUpperCase() ?? 'PENDENTE';
        final isPending = denuncia['is_pending'] ?? false;

        Widget imageWidget;
        if (imagePath != null) {
          imageWidget = Image.file(File(imagePath),
              height: 200, width: double.infinity, fit: BoxFit.cover);
        } else if (imageUrl != null) {
          imageWidget = Image.network(imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (ctx, err, stack) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 48))));
        } else {
          imageWidget = Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48)));
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  Text('Detalhes da Denúncia',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12), child: imageWidget),
                  const SizedBox(height: 20),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        isPending ? 'PENDENTE DE SINCRONIZAÇÃO' : status,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPending
                                ? Colors.orange.shade800
                                : Colors.blue.shade800)),
                  ),
                  const Divider(height: 24),
                  const Text('Localização', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(endereco.isEmpty ? 'Endereço não informado' : endereco,
                      style: const TextStyle(fontSize: 16)),
                  const Divider(height: 24),
                  const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(descricao,
                      style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
