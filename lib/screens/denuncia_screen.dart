import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/localidade.dart';
import 'package:vector_tracker_app/models/municipio.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class DenunciaScreen extends StatefulWidget {
  final Denuncia? denuncia;
  const DenunciaScreen({super.key, this.denuncia});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isSaving = false;
  bool _addressFilled = false;

  String? _selectedCidadeId;
  String? _selectedLocalidadeId;

  final _descricaoController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DenunciaService>().fetchMunicipios();
    });
    if (widget.denuncia != null) {
      _fillFields(widget.denuncia!);
    }
  }

  void _fillFields(Denuncia denuncia) {
    _descricaoController.text = denuncia.descricao ?? '';
    _ruaController.text = denuncia.rua ?? '';
    _bairroController.text = denuncia.bairro ?? '';
    _selectedCidadeId = denuncia.cidade;
    _selectedLocalidadeId = denuncia.localidade_id;
    _numeroController.text = denuncia.numero ?? '';
    _complementoController.text = denuncia.complemento ?? '';
    _latitude = denuncia.latitude;
    _longitude = denuncia.longitude;
    if ((denuncia.rua ?? '').isNotEmpty) {
      _addressFilled = true;
    }
    if (_selectedCidadeId != null) {
      context.read<DenunciaService>().fetchLocalidades(_selectedCidadeId!);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
        context: context, builder: (context) => const ImageSourceSheet());
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null) {
        setState(() => _pickedImage = pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isSaving = true);
    try {
      final position = await LocationUtil.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Serviço de Localização Desativado'),
              content: const Text('Para obter o endereço automaticamente, por favor, ative o serviço de localização do seu celular.'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                TextButton(onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                }, child: const Text('Abrir Configurações')),
              ],
            ),
          );
        }
        return;
      }

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        setState(() {
          _ruaController.text = p.street ?? '';
          _bairroController.text = p.subLocality ?? '';
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressFilled = true;
          _selectedCidadeId = null;
          _selectedLocalidadeId = null;
          context.read<DenunciaService>().clearLocalidades();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço preenchido! Por favor, selecione a cidade e localidade na lista.'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null && widget.denuncia?.foto_url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, adicione uma foto.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final denunciaService = context.read<DenunciaService>();
      final id = widget.denuncia?.id ?? const Uuid().v4();

      final novaDenuncia = Denuncia(
        id: id,
        descricao: _descricaoController.text,
        latitude: _latitude,
        longitude: _longitude,
        rua: _ruaController.text,
        bairro: _bairroController.text,
        cidade: _selectedCidadeId,
        localidade_id: _selectedLocalidadeId,
        numero: _numeroController.text,
        complemento: _complementoController.text,
        foto_url: _pickedImage?.path,
        createdAt: DateTime.now(),
        status: 'Pendente',
      );

      await denunciaService.saveDenuncia(novaDenuncia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia enviada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar denúncia: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onMunicipioChanged(String? newCidadeId) {
    if (newCidadeId == null) return;
    setState(() {
      _selectedCidadeId = newCidadeId;
      _selectedLocalidadeId = null; // Limpa a seleção de localidade
    });
    context.read<DenunciaService>().fetchLocalidades(newCidadeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GradientAppBar(title: 'Registrar Denúncia'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildImageCard(),
              const SizedBox(height: 16),
              _buildDescriptionCard(),
              const SizedBox(height: 16),
              _buildAddressCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSaving ? null : _submitForm,
            child: _isSaving
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                : const Text('Enviar Denúncia', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto da Ocorrência', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                  width: double.infinity, height: 200,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: _buildImageContent()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text('Adicionar Foto'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_pickedImage != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover));
    } else if (widget.denuncia?.foto_url != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: SmartImage(imageSource: widget.denuncia!.foto_url!));
    } else {
      return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50));
    }
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descrição (Opcional)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                  hintText: 'Ex: Encontrei um inseto parecido com um barbeiro na parede do meu quarto...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final denunciaService = context.watch<DenunciaService>();

    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endereço da Denúncia', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Obter Localização e Endereço'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            if (_addressFilled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12), width: double.infinity,
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                child: const Text('Endereço preenchido! Por favor, selecione a cidade e a localidade na lista.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue)),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCidadeId,
              decoration: const InputDecoration(labelText: 'Cidade*', border: OutlineInputBorder()),
              isExpanded: true,
              hint: denunciaService.isMunicipiosLoading ? const Text('Carregando cidades...') : const Text('Selecione a cidade'),
              items: denunciaService.municipios.map((Municipio municipio) {
                return DropdownMenuItem<String>(
                  value: municipio.id,
                  child: Text(municipio.nome),
                );
              }).toList(),
              onChanged: _onMunicipioChanged,
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedLocalidadeId,
              decoration: const InputDecoration(labelText: 'Localidade*', border: OutlineInputBorder()),
              isExpanded: true,
              hint: denunciaService.isLocalidadesLoading ? const Text('Carregando...') : const Text('Selecione a localidade'),
              items: denunciaService.localidades.map((Localidade localidade) {
                return DropdownMenuItem<String>(
                  value: localidade.id,
                  child: Text(localidade.nome),
                );
              }).toList(),
              onChanged: _selectedCidadeId == null ? null : (String? newValue) {
                setState(() {
                  _selectedLocalidadeId = newValue;
                });
              },
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(labelText: 'Número da Casa/Apto*', border: OutlineInputBorder()),
              validator: (value) => (value ?? '').isEmpty ? 'O número é obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _complementoController,
              decoration: const InputDecoration(labelText: 'Complemento (Opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar foto com a Câmera'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Escolher da Galeria'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
