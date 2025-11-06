import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster, ClusterManager;
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class Place with ClusterItem {
  final Map<String, dynamic> item;

  Place({required this.item});

  @override
  LatLng get location {
    final lat = _parseDouble(item['latitude']);
    final lon = _parseDouble(item['longitude']);
    return LatLng(lat ?? 0.0, lon ?? 0.0);
  }

  bool get isMock => item['is_mock'] == true;

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _denunciaService = Provider.of<DenunciaService>(context, listen: false);
      _denunciaService.addListener(_updateItemsOnMap);
      _updateItemsOnMap();
    });
  }

  List<Map<String, dynamic>> _getMockItems() {
    final random = Random();
    final mockLocations = [
      {'lat': -5.09, 'lng': -42.81, 'is_ocorrencia': true},
      {'lat': -2.90, 'lng': -41.77, 'is_ocorrencia': true},
      {'lat': -7.07, 'lng': -41.46, 'is_ocorrencia': true},
      {'lat': -6.76, 'lng': -43.02, 'is_ocorrencia': false},
      {'lat': -7.22, 'lng': -44.55, 'is_ocorrencia': false},
      {'lat': -9.07, 'lng': -44.35, 'is_ocorrencia': false},
      {'lat': -8.28, 'lng': -43.68, 'is_ocorrencia': false},
    ];

    return mockLocations.map((loc) {
      final lat = (loc['lat'] as double) + (random.nextDouble() - 0.5) * 0.05;
      final lng = (loc['lng'] as double) + (random.nextDouble() - 0.5) * 0.05;
      return {
        'id': 'mock_${loc['lat']}', 
        'latitude': lat,
        'longitude': lng,
        'is_ocorrencia': loc['is_ocorrencia'],
        'is_mock': true, // Flag para identificar que é um pin falso
      };
    }).toList();
  }

  void _updateItemsOnMap() {
    if (mounted) {
      final realItems = _denunciaService.items.where((item) => 
        Place._parseDouble(item['latitude']) != null && 
        Place._parseDouble(item['longitude']) != null
      ).toList();

      final allItems = [...realItems, ..._getMockItems()];

      final places = _getPlaces(allItems);
      _clusterManager.setItems(places);
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
    _denunciaService.removeListener(_updateItemsOnMap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Mapa de Ocorrências'),
      body: Consumer<DenunciaService>(
        builder: (context, denunciaService, child) {
          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: const CameraPosition(
                    target: LatLng(-7.0, -43.0), zoom: 6.0),
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

  List<Place> _getPlaces(List<Map<String, dynamic>> items) {
    return items.map((i) => Place(item: i)).toList();
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
      final isOcorrencia = place.item['is_ocorrencia'] == true;

      final markerColor = isOcorrencia
        ? BitmapDescriptor.hueGreen 
        : BitmapDescriptor.hueAzure;

      return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            if (!place.isMock) {
              _showItemDetails(context, place.item);
            }
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor));
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
    final Paint paint1 = Paint()..color = Colors.blue.withOpacity(0.85);
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

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isOcorrencia = item['is_ocorrencia'] == true;
        final modalTitle = isOcorrencia ? 'Detalhes da Ocorrência' : 'Detalhes da Denúncia';

        final imagePath = item['image_path'] as String?;
        final imageUrl = item['agent_image_url'] ?? item['image_url'] as String?;
        
        String endereco;
        if (isOcorrencia) {
          endereco = [ item['endereco'], item['numero'], item['localidade'] ]
              .where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
        } else {
          endereco = [ item['rua'], item['numero'], item['bairro'] ]
              .where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
        }

        final descricao = item['descricao'] ?? (isOcorrencia ? 'Ocorrência registrada pelo agente.' : 'Nenhuma descrição fornecida.');
        final status = (item['status'] as String?)?.toUpperCase() ?? 'PENDENTE';
        
        Widget imageWidget;
        if (imagePath != null) {
          imageWidget = Image.file(File(imagePath), fit: BoxFit.cover);
        } else if (imageUrl != null) {
          imageWidget = Image.network(imageUrl, fit: BoxFit.cover);
        } else {
          imageWidget = Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48)));
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
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  Text(modalTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 200, width: double.infinity, child: imageWidget)),
                  const SizedBox(height: 20),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: (isOcorrencia || status == 'REALIZADA') ? Colors.green.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: (isOcorrencia || status == 'REALIZADA') ? Colors.green.shade800 : Colors.blue.shade800)),
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
}
