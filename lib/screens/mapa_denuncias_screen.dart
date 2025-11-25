import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster, ClusterManager;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

// Classe unificada para itens do mapa
class MapItem with ClusterItem {
  final Denuncia? denuncia;
  final Ocorrencia? ocorrencia;

  MapItem.fromDenuncia(this.denuncia) : ocorrencia = null;
  MapItem.fromOcorrencia(this.ocorrencia) : denuncia = null;

  bool get isOcorrencia => ocorrencia != null;

  double get hue {
    if (isOcorrencia) {
      if (ocorrencia!.denuncia_id != null) {
        return BitmapDescriptor.hueGreen; // Atendida (Verde)
      } else {
        return BitmapDescriptor.hueBlue; // Proativo (Azul)
      }
    } else {
      if ((denuncia!.status?.toLowerCase() ?? '') == 'atendida') {
         return BitmapDescriptor.hueGreen;
      }
      return BitmapDescriptor.hueOrange;
    }
  }

  @override
  LatLng get location {
    if (isOcorrencia) {
      return LatLng(ocorrencia!.latitude ?? 0, ocorrencia!.longitude ?? 0);
    } else {
      return LatLng(denuncia!.latitude ?? 0, denuncia!.longitude ?? 0);
    }
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
  
  // Posição inicial fixa no Piauí
  CameraPosition _initialPosition = const CameraPosition(target: LatLng(-7.5, -43.0), zoom: 6.5);

  @override
  void initState() {
    super.initState();
    _clusterManager = _initClusterManager();
    _loadData();
  }

  Future<void> _loadData() async {
    final context = this.context;
    final agenteRepo = Provider.of<AgenteRepository>(context, listen: false);
    final agente = await agenteRepo.getCurrentAgent();
    final localidadeIds = agente?.localidades.map((l) => l.id).toList();

    if (!mounted) return;
    
    final agentService = Provider.of<AgentOcorrenciaService>(context, listen: false);
    await agentService.fetchOcorrencias();
    
    final denunciaService = Provider.of<DenunciaService>(context, listen: false);
    await denunciaService.fetchItems(localidadeIds: localidadeIds);

    _updateMapItems();
  }

  void _updateMapItems() {
     if (!mounted) return;
     final agentService = Provider.of<AgentOcorrenciaService>(context, listen: false);
     final denunciaService = Provider.of<DenunciaService>(context, listen: false);

     final List<MapItem> items = [];

     final pendentes = denunciaService.items
         .map((d) => Denuncia.fromMap(d))
         .where((d) => (d.status?.toLowerCase() != 'atendida') && d.latitude != null && d.longitude != null)
         .map((d) => MapItem.fromDenuncia(d));
     items.addAll(pendentes);

     final realizados = agentService.ocorrencias
         .where((o) => o.latitude != null && o.longitude != null)
         .map((o) => MapItem.fromOcorrencia(o));
     items.addAll(realizados);

     _clusterManager.setItems(items);
  }
  
  ClusterManager _initClusterManager() {
    return ClusterManager<MapItem>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
      // Níveis de zoom
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 18.0, 20.0], 
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<Marker> Function(Cluster<MapItem>) get _markerBuilder => (cluster) async {
    if (!cluster.isMultiple) {
      final item = cluster.items.first;
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        onTap: () {
          if (item.isOcorrencia) {
            _showOcorrenciaDetails(context, item.ocorrencia!);
          } else {
            _showDenunciaDetails(context, item.denuncia!);
          }
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(item.hue),
      );
    }

    final int size = cluster.count;
    final icon = await _getMarkerBitmap(150, text: size.toString());

    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: icon,
      onTap: () async {
        final controller = await _controller.future;
        final bounds = _boundsFromCluster(cluster);
        
        final double latDiff = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
        final double lngDiff = (bounds.northeast.longitude - bounds.southwest.longitude).abs();

        // AJUSTE: Tolerância muito baixa (0.00001 ~ 1 metro).
        // O mapa só vai mostrar a lista se os pontos estiverem EXATAMENTE no mesmo lugar.
        // Caso contrário, ele vai tentar dar zoom máximo para separar os pins (mostrar o máximo de pins possível).
        if (latDiff < 0.00001 && lngDiff < 0.00001) {
           _showClusterItemsList(context, cluster.items);
        } else {
           controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40.0));
        }
      },
    );
  };

  void _showClusterItemsList(BuildContext context, Iterable<MapItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
             return Container(
               decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
               ),
               padding: const EdgeInsets.only(top: 16),
               child: Column(
                 children: [
                   Text(
                     '${items.length} Registros neste local exato', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   const Divider(),
                   Expanded(
                     child: ListView.separated(
                       controller: scrollController,
                       padding: const EdgeInsets.all(16),
                       itemCount: items.length,
                       separatorBuilder: (_, __) => const Divider(),
                       itemBuilder: (context, index) {
                          final item = items.elementAt(index);
                          if (item.isOcorrencia) {
                             final oc = item.ocorrencia!;
                             final isProativo = oc.denuncia_id == null;
                             return ListTile(
                               leading: Icon(Icons.assignment_turned_in, color: isProativo ? Colors.blue : Colors.green),
                               title: Text(isProativo ? 'Registro Proativo' : 'Denúncia Atendida'),
                               subtitle: Text(DateFormat('dd/MM/yyyy').format(oc.data_atividade ?? DateTime.now())),
                               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                               onTap: () {
                                 Navigator.pop(context); // Fecha a lista
                                 _showOcorrenciaDetails(context, oc);
                               },
                             );
                          } else {
                             final den = item.denuncia!;
                             return ListTile(
                               leading: const Icon(Icons.location_on, color: Colors.orange),
                               title: const Text('Denúncia Pendente'),
                               subtitle: Text(DateFormat('dd/MM/yyyy').format(den.createdAt ?? DateTime.now())),
                               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                               onTap: () {
                                  Navigator.pop(context); // Fecha a lista
                                  _showDenunciaDetails(context, den);
                               },
                             );
                          }
                       },
                     ),
                   ),
                 ],
               ),
             );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Mapa Geral'),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
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
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                     _legendItem(Colors.orange, 'Pendente'),
                     _legendItem(Colors.green, 'Atendida'),
                     _legendItem(Colors.blue, 'Proativo'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- DETALHES DA DENÚNCIA ---
  void _showDenunciaDetails(BuildContext context, Denuncia denuncia) {
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
                          'Denúncia Pendente',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registrado em: $formattedDate',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
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

  // --- DETALHES DA OCORRÊNCIA ---
  void _showOcorrenciaDetails(BuildContext context, Ocorrencia ocorrencia) {
     final isProativo = ocorrencia.denuncia_id == null;
     final color = isProativo ? Colors.blue : Colors.green;
     final title = isProativo ? 'Registro Proativo' : 'Denúncia Atendida';
     
     final formattedDate = ocorrencia.data_atividade != null
        ? DateFormat('dd/MM/yyyy').format(ocorrencia.data_atividade!)
        : 'Data indisponível';
        
     final firstImage = ocorrencia.fotos_urls?.isNotEmpty == true ? ocorrencia.fotos_urls!.first : null;

     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      child: firstImage != null
                          ? SmartImage(imageSource: firstImage, fit: BoxFit.cover)
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
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Realizado em: $formattedDate',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Divider(height: 32),
                        _buildInfoRow(context, Icons.location_on_outlined, 'Endereço', ocorrencia.endereco ?? 'Não informado'),
                        if (ocorrencia.numero != null)
                           _buildInfoRow(context, Icons.home, 'Número', ocorrencia.numero!),
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

  LatLngBounds _boundsFromCluster(Cluster<MapItem> cluster) {
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
