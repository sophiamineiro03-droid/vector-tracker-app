import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class DenunciaScreen extends StatefulWidget {
  final Map<String, dynamic>? denuncia;
  const DenunciaScreen({super.key, this.denuncia});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  Position? _currentPosition;
  String _locationMessage = "Toque no botão para obter a localização.";
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isAddressLoading = false;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.denuncia != null;
    if (_isEditing) {
      _populateFields(widget.denuncia!);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _descriptionController.text = data['descricao'] ?? '';
    _ruaController.text = data['rua'] ?? '';
    _numeroController.text = data['numero']?.toString() ?? '';
    _bairroController.text = data['bairro'] ?? '';
    _cidadeController.text = data['cidade'] ?? '';
    _estadoController.text = data['estado'] ?? '';
    if (data['latitude'] != null && data['longitude'] != null) {
      _currentPosition = Position(latitude: (data['latitude'] as num).toDouble(), longitude: (data['longitude'] as num).toDouble(), timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
      _locationMessage = "Endereço carregado.";
    }
    if (data['image_url'] != null) _existingImageUrl = data['image_url'];
    if (data['image_path'] != null) _imageFile = File(data['image_path']);
  }

  // --- LÓGICA DE LOCALIZAÇÃO MELHORADA ---
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isAddressLoading = true;
      _locationMessage = "Verificando serviço de localização...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('GPS Desativado'),
              content: const Text('Para obter a localização, por favor, ative o serviço de localização (GPS) do seu dispositivo.'),
              actions: <Widget>[
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                    child: const Text('Abrir Configurações'),
                    onPressed: () async {
                      await Geolocator.openLocationSettings();
                      Navigator.of(context).pop();
                    }),
              ],
            ),
          );
        }
        setState(() => _locationMessage = "Serviço de localização está desativado.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Você negou a permissão de localização.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Permissão de localização negada permanentemente. Habilite nas configurações do app.');

      setState(() => _locationMessage = "Obtendo coordenadas...");
      final position = await Geolocator.getCurrentPosition();
      setState(() { _currentPosition = position; _locationMessage = "Coordenadas obtidas! Buscando endereço..."; });

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        _ruaController.text = p.street ?? '';
        _bairroController.text = p.subLocality ?? '';
        _cidadeController.text = p.locality ?? '';
        _estadoController.text = p.administrativeArea ?? '';
        setState(() => _locationMessage = "Endereço preenchido! Confirme os dados e insira o número.");
      }
    } catch (e) {
      final errorMessage = e.toString();
      setState(() => _locationMessage = errorMessage);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } finally {
      setState(() => _isAddressLoading = false);
    }
  }

  // --- LÓGICA DE SELEÇÃO DE IMAGEM MELHORADA ---
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria de Fotos'), onTap: () => Navigator.of(context).pop(ImageSource.gallery)),
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Câmera'), onTap: () => Navigator.of(context).pop(ImageSource.camera)),
            ],
          ),
        );
      },
    ).then((source) {
      if (source != null) _pickImage(source);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null) setState(() { _imageFile = File(pickedFile.path); _existingImageUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submitDenuncia() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('É necessário obter a localização.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser?.id;

    final allData = {
      'id': _isEditing ? widget.denuncia!['id'] : null,
      'local_id': _isEditing ? widget.denuncia!['local_id'] : const Uuid().v4(),
      'uid': userId,
      'descricao': _descriptionController.text.trim(),
      'latitude': _currentPosition?.latitude ?? (widget.denuncia?['latitude'] as num?)?.toDouble(),
      'longitude': _currentPosition?.longitude ?? (widget.denuncia?['longitude'] as num?)?.toDouble(),
      'rua': _ruaController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'estado': _estadoController.text.trim(),
      'numero': int.tryParse(_numeroController.text.trim()),
      'created_at': widget.denuncia?['created_at'] ?? DateTime.now().toIso8601String(),
      'image_path': _imageFile?.path,
    };

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);

    try {
      if (isOnline) {
        String? imageUrl = _existingImageUrl;
        if (_imageFile != null) {
          final file = File(_imageFile!.path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final uploadPath = userId != null ? '$userId/$fileName' : 'anonymous/$fileName';
          await supabase.storage.from('imagens_denuncias').upload(uploadPath, file);
          imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(uploadPath);
        }

        final Map<String, dynamic> dbData = {
          'descricao': allData['descricao'],
          'latitude': allData['latitude'],
          'longitude': allData['longitude'],
          'rua': allData['rua'],
          'bairro': allData['bairro'],
          'cidade': allData['cidade'],
          'estado': allData['estado'],
          'numero': allData['numero'],
          'image_url': imageUrl,
        };

        if (_isEditing && allData['id'] != null) {
          await supabase.from('denuncias').update(dbData).eq('id', allData['id']);
        } else {
          await supabase.from('denuncias').insert(dbData);
        }
        if (allData['local_id'] != null) await Hive.box('pending_denuncias').delete(allData['local_id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denúncia enviada com sucesso!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } else {
        await _saveDenunciaLocally(allData);
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar denúncia: ${e.toString()}'), backgroundColor: Colors.red));
      await _saveDenunciaLocally(allData, showMessage: false);
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDenunciaLocally(Map<String, dynamic> data, {bool showMessage = true}) async {
    final Box pendingBox = Hive.box('pending_denuncias');
    final String localId = data['local_id'] as String;
    await pendingBox.put(localId, data);
    if (showMessage && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão. Salvo localmente para sincronizar depois.'), backgroundColor: Colors.orange));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: _isEditing ? 'Editar Denúncia' : 'Registrar Ocorrência'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPhotoCard(context),
                const SizedBox(height: 24),
                _buildDescriptionCard(context),
                const SizedBox(height: 24),
                _buildAddressCard(context),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitDenuncia,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(_isEditing ? 'Salvar Alterações' : 'Enviar Denúncia', style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _buildPhotoCard(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildSectionTitle(context, 'Foto da Ocorrência'),
          AspectRatio(aspectRatio: 16 / 10, child: Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: _imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, fit: BoxFit.cover)) : (_existingImageUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_existingImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey, size: 48))) : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48))))),
          const SizedBox(height: 12),
          OutlinedButton.icon(icon: const Icon(Icons.camera_alt_outlined), label: const Text('Adicionar Foto'), onPressed: _showImageSourceDialog),
        ]),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle(context, 'Descrição (Opcional)'),
          TextFormField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(hintText: 'Ex: Encontrei um inseto parecido com um barbeiro na parede do meu quarto...', border: OutlineInputBorder())),
        ]),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildSectionTitle(context, 'Endereço da Ocorrência'),
          const SizedBox(height: 8),
          ElevatedButton.icon(icon: const Icon(Icons.my_location), label: const Text('Obter Localização e Endereço'), onPressed: _isAddressLoading ? null : _getCurrentLocation),
          const SizedBox(height: 12),
          if (_isAddressLoading || _currentPosition != null || _isEditing) 
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_locationMessage, textAlign: TextAlign.center)),
          if (_isAddressLoading) const Padding(padding: EdgeInsets.only(top: 16.0), child: Center(child: CircularProgressIndicator())),
          if (_currentPosition != null || _isEditing) ...[
            const SizedBox(height: 16),
            TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número da Casa/Apto*', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'O número é obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
          ]
        ]),
      ),
    );
  }
}
