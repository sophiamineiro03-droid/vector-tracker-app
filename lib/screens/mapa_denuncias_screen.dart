import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide Cluster, ClusterManager;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class Place with ClusterItem {
  final Denuncia denuncia;

  Place({required this.denuncia});

  @override
  LatLng get location => LatLng(denuncia.latitude!, denuncia.longitude!);
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
      _denunciaService.fetchItems();
    });
  }

  @override
  void dispose() {
    _denunciaService.removeListener(_updateItemsOnMap);
    super.dispose();
  }

  void _updateItemsOnMap() {
    if (mounted) {
      final realItems = _denunciaService.items
          .map((item) => Denuncia.fromMap(item))
          .where((d) => d.latitude != null && d.longitude != null)
          .toList();

      final places = realItems.map((d) => Place(denuncia: d)).toList();
      _clusterManager.setItems(places);
      // A LÓGICA DA CÂMERA INTELIGENTE FOI REMOVIDA DAQUI
    }
  }

  ClusterManager _initClusterManager() {
    return ClusterManager<Place>([], _updateMarkers,
        markerBuilder: _markerBuilder);
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
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
                // A POSIÇÃO INICIAL CONTINUA SENDO O PIAUÍ
                initialCameraPosition: const CameraPosition(
                    target: LatLng(-7.5, -43.0), zoom: 6.5),
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

  Future<Marker> Function(Cluster<Place>) get _markerBuilder => (cluster) async {
        if (!cluster.isMultiple) {
          final place = cluster.items.first;
          return Marker(
            markerId: MarkerId(cluster.getId()),
            position: cluster.location,
            onTap: () {
              _showItemDetails(context, place.denuncia);
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );
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
            controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0));
          },
        );
      };

  void _showItemDetails(BuildContext context, Denuncia denuncia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String endereco = [denuncia.rua, denuncia.numero, denuncia.bairro]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');

        final formattedDate = denuncia.createdAt != null
            ? DateFormat('dd/MM/yyyy \'às\' HH:mm').format(denuncia.createdAt!)
            : 'Data indisponível';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          maxChildSize: 0.8,
          minChildSize: 0.2,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: denuncia.foto_url != null
                          ? SmartImage(imageSource: denuncia.foto_url!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Denúncia em ${denuncia.bairro ?? 'local não informado'}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registrado em: $formattedDate',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusChip(denuncia.status),
                        const Divider(height: 32),
                        if (endereco.isNotEmpty)
                          _buildInfoRow(context, Icons.location_on_outlined, 'Endereço', endereco),
                        _buildInfoRow(context, Icons.description_outlined, 'Descrição', denuncia.descricao ?? 'Nenhuma descrição fornecida.'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.black87, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String? status) {
    IconData iconData;
    String text;
    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case 'Pendente':
      case 'pendente_envio':
        iconData = Icons.watch_later_outlined;
        text = 'AGUARDANDO VISITA';
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade800;
        break;
      case 'atendida':
      case 'concluida':
        iconData = Icons.check_circle_outline;
        text = 'ATENDIDA';
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        break;
      default:
        iconData = Icons.help_outline;
        text = (status ?? 'desconhecido').toUpperCase();
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: foregroundColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {required String text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.blue.withOpacity(0.85);
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.4, paint1);

    TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);
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
}
