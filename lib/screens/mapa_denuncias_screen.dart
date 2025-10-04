import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class MapaDenunciasScreen extends StatefulWidget {
  const MapaDenunciasScreen({super.key});

  @override
  State<MapaDenunciasScreen> createState() => _MapaDenunciasScreenState();
}

class _MapaDenunciasScreenState extends State<MapaDenunciasScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _allDenuncias = [];
  List<Marker> _visibleMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDenuncias();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _filterDenuncias);
  }

  void _showDenunciaDetails(Map<String, dynamic> denuncia) {
    final imageUrl = denuncia['image_url'];
    final endereco = [denuncia['rua'], denuncia['numero'], denuncia['bairro'], denuncia['cidade'], denuncia['estado']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => SingleChildScrollView(child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [if (imageUrl != null) ...[ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())), errorBuilder: (context, error, stack) => Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))))), const SizedBox(height: 16)], const Text("Detalhes da Ocorrência", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 16), Text(endereco.isEmpty ? "Endereço não informado" : endereco), const Divider(height: 24), const Text("Descrição:", style: TextStyle(fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(denuncia['descricao'] ?? 'Nenhuma descrição fornecida.')]))));
  }

  Future<void> _fetchDenuncias() async {
    try {
      final response = await supabase.from('denuncias').select();
      _allDenuncias = List<Map<String, dynamic>>.from(response);
      _buildMarkers(_allDenuncias);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar denúncias: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterDenuncias() {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty ? _allDenuncias : _allDenuncias.where((d) => (d['rua']?.toString().toLowerCase() ?? '').contains(query) || (d['bairro']?.toString().toLowerCase() ?? '').contains(query) || (d['cidade']?.toString().toLowerCase() ?? '').contains(query) || (d['estado']?.toString().toLowerCase() ?? '').contains(query) || (d['descricao']?.toString().toLowerCase() ?? '').contains(query)).toList();
    _buildMarkers(filtered);
  }

  void _buildMarkers(List<Map<String, dynamic>> denuncias) {
    final List<Marker> loadedMarkers = [];
    final List<LatLng> points = [];
    for (final denuncia in denuncias) {
      final lat = denuncia['latitude'];
      final lon = denuncia['longitude'];
      if (lat != null && lon != null) {
        points.add(LatLng(lat, lon));
        loadedMarkers.add(Marker(point: LatLng(lat, lon), width: 40, height: 40, child: GestureDetector(onTap: () => _showDenunciaDetails(denuncia), child: const Icon(Icons.location_pin, color: Colors.red, size: 40))));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && points.isNotEmpty) {
        if (points.length > 1) {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        } else {
          _mapController.move(points.first, 15.0);
        }
      }
    });

    setState(() {
      _visibleMarkers = loadedMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Mapa de Ocorrências'),
      body: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), child: TextField(controller: _searchController, decoration: InputDecoration(labelText: 'Buscar por rua, bairro, cidade...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())))), Expanded(child: _buildMap())]));
  }

  Widget _buildMap() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_allDenuncias.isEmpty) return const Center(child: Text("Nenhuma ocorrência encontrada."));

    return Stack(alignment: Alignment.center, children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCameraFit: CameraFit.bounds(bounds: LatLngBounds(const LatLng(-2.7, -45.9), const LatLng(-10.9, -40.3)), padding: const EdgeInsets.all(20))),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            retinaMode: true,
            userAgentPackageName: 'com.example.vector_tracker_app',
            // OTIMIZAÇÃO: Adiciona um tratamento de erro para falhas de rede.
            // Se um 'tile' do mapa falhar ao carregar, o app não vai mais travar
            // ou mostrar uma tela de erro. Apenas um espaço vazio aparecerá no lugar.
            errorTileCallback: (tile, error, stack) {
              // Apenas loga o erro no console de debug, sem interromper o app.
              debugPrint('Falha ao carregar tile do mapa: ${tile.coords}, erro: $error');
            },
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(50, 50),
              markers: _visibleMarkers,
              polygonOptions: const PolygonOptions(borderColor: Colors.transparent, color: Colors.transparent, borderStrokeWidth: 0),
              builder: (context, markers) {
                return SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(4, -4),
                        child: const Icon(Icons.location_pin, color: Colors.black38, size: 40),
                      ),
                      const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      SizedBox(
                        width: 40,
                        height: 30,
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      if (_visibleMarkers.isEmpty && _searchController.text.isNotEmpty) Positioned(top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)), child: const Text('Nenhum resultado para a sua busca.', style: TextStyle(color: Colors.white))))
    ]);
  }
}
