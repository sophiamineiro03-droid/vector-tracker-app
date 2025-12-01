import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/municipio.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';
import 'package:vector_tracker_app/core/app_logger.dart';

class DenunciaScreen extends StatefulWidget {
  final Denuncia? denuncia;
  final bool isViewOnly;

  const DenunciaScreen({
    super.key, 
    this.denuncia,
    this.isViewOnly = false,
  });

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isSaving = false;
  
  // Variáveis para controle da mensagem de localização
  String? _locationMessage;
  Color _locationMessageColor = Colors.black;

  String? _selectedCidadeId;

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
    _numeroController.text = denuncia.numero ?? '';
    _complementoController.text = denuncia.complemento ?? '';
    _latitude = denuncia.latitude;
    _longitude = denuncia.longitude;
    
    if ((denuncia.rua ?? '').isNotEmpty) {
      _locationMessage = 'Endereço carregado da denúncia salva.';
      _locationMessageColor = Colors.blue;
    }
  }

  Future<void> _pickImage() async {
    if (widget.isViewOnly) return; // Bloqueia se for apenas leitura

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

  String _normalize(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  Future<void> _getCurrentLocation() async {
    if (widget.isViewOnly) return;

    setState(() {
      _isSaving = true;
      _locationMessage = 'Obtendo GPS...';
      _locationMessageColor = Colors.grey;
    });
    
    try {
      final position = await LocationUtil.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          setState(() {
             _locationMessage = null; // Limpa msg de carregando
             _isSaving = false;
          });
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

      // Tenta obter endereço (Geocoding) - Pode falhar se offline
      List<Placemark> placemarks = [];
      try {
          placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
          AppLogger.warning('Erro ao buscar endereço (Geocoding), provavelmente offline.', e);
      }

      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        
        String? detectedCity = p.subAdministrativeArea ?? p.locality;
        String? foundCidadeId;
        String msgCidade = "";

        if (detectedCity != null) {
            final service = context.read<DenunciaService>();
            try {
                final municipioMatch = service.municipios.firstWhere(
                  (m) => _normalize(m.nome) == _normalize(detectedCity),
                );
                foundCidadeId = municipioMatch.id;
                msgCidade = "Município detectado: ${municipioMatch.nome}";
            } catch (e) {
                msgCidade = "Município atual ($detectedCity) não está cadastrado no sistema.";
            }
        }

        setState(() {
          _ruaController.text = p.street ?? '';
          _bairroController.text = p.subLocality ?? '';
          _latitude = position.latitude;
          _longitude = position.longitude;
          
          if (foundCidadeId != null) {
             _selectedCidadeId = foundCidadeId;
          }
          
          // MENSAGEM ATUALIZADA COM LEMBRETE DO NÚMERO
          _locationMessage = 'Localização e Endereço atualizados! Por favor, preencha o número da casa. $msgCidade';
          _locationMessageColor = foundCidadeId != null ? Colors.green : Colors.orange;
        });
        
      } else {
          // CASO OFFLINE: Pegou GPS mas não conseguiu traduzir para Rua
          setState(() {
             _latitude = position.latitude;
             _longitude = position.longitude;
             
             // MENSAGEM ATUALIZADA COM "Por favor, preencha."
             _locationMessage = 'Coordenadas GPS capturadas! Não foi possível carregar os dados do endereço sem internet. Por favor, preencha.';
             _locationMessageColor = Colors.orange.shade800;
          });
      }
    } catch (e) {
      setState(() {
         _locationMessage = 'Erro ao obter GPS: $e';
         _locationMessageColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForm() async {
    if (widget.isViewOnly) return; // Bloqueia envio

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

      final user = Supabase.instance.client.auth.currentUser;
      AppLogger.info('DEBUG: Usuário Logado no Form: ${user?.email} (ID: ${user?.id})');

      final novaDenuncia = Denuncia(
        id: id,
        userId: user?.id, 
        descricao: _descricaoController.text,
        latitude: _latitude,
        longitude: _longitude,
        rua: _ruaController.text,
        bairro: _bairroController.text,
        cidade: _selectedCidadeId,
        localidade_id: null,
        numero: _numeroController.text,
        complemento: _complementoController.text,
        foto_url: _pickedImage?.path,
        createdAt: DateTime.now(),
        status: 'Pendente',
      );

      await denunciaService.saveDenuncia(novaDenuncia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia salva!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GradientAppBar(title: widget.isViewOnly ? 'Detalhes da Denúncia' : 'Registrar Denúncia'),
      body: SafeArea(
        child: Form(
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
                
                // CORREÇÃO: Botão movido para dentro do scroll, no final
                if (!widget.isViewOnly) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isSaving ? null : _submitForm,
                    child: _isSaving
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                        : const Text('Enviar Denúncia', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 24), // Respiro final
                ],
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar REMOVIDO
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
            if (!widget.isViewOnly) ...[
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
            Text('Descrição', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              readOnly: widget.isViewOnly,
              decoration: InputDecoration(
                  hintText: widget.isViewOnly ? '' : 'Ex: Encontrei um inseto parecido com um barbeiro na parede do meu quarto...',
                  border: const OutlineInputBorder(),
                  fillColor: widget.isViewOnly ? Colors.grey[100] : null,
                  filled: widget.isViewOnly,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)),
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
            
            if (!widget.isViewOnly)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Obter Localização'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            
            if (_locationMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12), 
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _locationMessageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: _locationMessageColor.withOpacity(0.5))
                  ),
                  child: Text(
                    _locationMessage!, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: _locationMessageColor, fontWeight: FontWeight.bold)
                  ),
                ),
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCidadeId,
              decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
              isExpanded: true,
              hint: denunciaService.isMunicipiosLoading ? const Text('Carregando cidades...') : const Text('Selecione a cidade'),
              items: denunciaService.municipios.map((Municipio municipio) {
                return DropdownMenuItem<String>(
                  value: municipio.id,
                  child: Text(municipio.nome),
                );
              }).toList(),
              onChanged: widget.isViewOnly ? null : (newVal) {
                 setState(() => _selectedCidadeId = newVal);
              },
              validator: (value) => value == null ? 'Cidade obrigatória (Use o GPS ou selecione)' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _numeroController,
              readOnly: widget.isViewOnly,
              decoration: const InputDecoration(labelText: 'Número da Casa*', border: OutlineInputBorder()),
              validator: (value) => (value ?? '').isEmpty ? 'O número é obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _complementoController,
              readOnly: widget.isViewOnly,
              decoration: const InputDecoration(labelText: 'Complemento (Opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ruaController, 
              readOnly: widget.isViewOnly,
              decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder())
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bairroController, 
              readOnly: widget.isViewOnly,
              decoration: const InputDecoration(labelText: 'Bairro (Opcional)', border: OutlineInputBorder())
            ),
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
