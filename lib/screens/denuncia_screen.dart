import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class DenunciaScreen extends StatefulWidget {
  const DenunciaScreen({super.key});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  // Controladores para todos os campos
  final _descriptionController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  Position? _currentPosition;
  String _locationMessage = "Clique no botão para obter a localização.";
  File? _image;
  bool _isLoading = false;
  bool _isAddressLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isAddressLoading = true;
      _locationMessage = "Verificando permissões...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationMessage = "Por favor, ative o serviço de localização (GPS).");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationMessage = "Você negou a permissão de localização.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationMessage = "Permissão negada permanentemente. Habilite nas configurações.");
        return;
      }

      setState(() => _locationMessage = "Obtendo coordenadas...");
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = "Coordenadas obtidas! Buscando endereço...";
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        _ruaController.text = p.street ?? '';
        _bairroController.text = p.subLocality ?? '';
        _cidadeController.text = p.locality ?? '';
        _estadoController.text = p.administrativeArea ?? '';
        setState(() => _locationMessage = "Endereço encontrado! Por favor, confirme e insira o número.");
      }
    } catch (e) {
      setState(() => _locationMessage = "Erro ao obter endereço: ${e.toString()}");
    } finally {
      setState(() => _isAddressLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitDenuncia() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obtenha a localização antes de enviar.')));
      return;
    }
    if (_numeroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, insira o número da residência.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        final imageFile = _image!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final imagePath = '/${DateTime.now().toIso8601String()}.$imageExtension';
        await supabase.storage.from('imagens_denuncias').upload(imagePath, imageFile);
        imageUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(imagePath);
      }

      await supabase.from('denuncias').insert({
        'descricao': _descriptionController.text,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'image_url': imageUrl,
        'rua': _ruaController.text,
        'bairro': _bairroController.text,
        'cidade': _cidadeController.text,
        'estado': _estadoController.text,
        'numero': _numeroController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denúncia enviada com sucesso!')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar denúncia: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      appBar: const GradientAppBar(title: 'Registrar Ocorrência'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- WIDGETS DA IMAGEM --- 
            Container(
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10.0)),
              child: _image != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(10.0), child: Image.file(_image!, fit: BoxFit.cover))
                  : const Center(child: Text('Nenhuma imagem selecionada.')),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Selecionar Foto da Galeria'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),

            // --- WIDGET DE DESCRIÇÃO ---
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // --- SEÇÃO DE LOCALIZAÇÃO COMPLETA ---
            const Text('Endereço da Ocorrência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Obter Localização Atual e Endereço'),
              onPressed: _getCurrentLocation,
            ),
            const SizedBox(height: 12),

            if (_isAddressLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
            
            if (_currentPosition != null)
              Column(
                children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_locationMessage, textAlign: TextAlign.center)),
                  const SizedBox(height: 12),
                  TextField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número da Casa/Apto* (Obrigatório)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder())),
                ],
              ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDenuncia,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Enviar Denúncia', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
