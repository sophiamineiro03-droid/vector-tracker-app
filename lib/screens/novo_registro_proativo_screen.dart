import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/models/ocorrencia_siocchagas.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/services/ocorrencia_siocchagas_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class NovoRegistroProativoScreen extends StatefulWidget {
  const NovoRegistroProativoScreen({super.key});

  @override
  _NovoRegistroProativoScreenState createState() => _NovoRegistroProativoScreenState();
}

class _NovoRegistroProativoScreenState extends State<NovoRegistroProativoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAddressLoading = false;

  // Model instance to hold form data
  late OcorrenciaSiocchagas _ocorrencia;

  // Controllers for text fields
  final _dataAtividadeController = TextEditingController();
  final _numeroPitController = TextEditingController();
  final _codigoLocalidadeController = TextEditingController();
  final _categoriaLocalidadeController = TextEditingController();
  final _localidadeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _nomeMoradorController = TextEditingController();
  final _numBarbeirosIntraController = TextEditingController(text: '0');
  final _numBarbeirosPeriController = TextEditingController(text: '0');
  final _codigoEtiquetaController = TextEditingController();

  // Photo paths
  final List<String?> _photoPaths = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    final agent = context.read<AgentService>().currentAgent;
    _ocorrencia = OcorrenciaSiocchagas(
      agente_id: agent?.id,
      municipio: agent?.municipioNome,
      data_atividade: DateTime.now(),
    );
    _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(_ocorrencia.data_atividade!);
  }

  @override
  void dispose() {
    _dataAtividadeController.dispose();
    _numeroPitController.dispose();
    _codigoLocalidadeController.dispose();
    _categoriaLocalidadeController.dispose();
    _localidadeController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _nomeMoradorController.dispose();
    _numBarbeirosIntraController.dispose();
    _numBarbeirosPeriController.dispose();
    _codigoEtiquetaController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isAddressLoading = true);
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
          _ocorrencia.gps_latitude = position.latitude;
          _ocorrencia.gps_longitude = position.longitude;
          _localidadeController.text = p.subLocality ?? '';
          _enderecoController.text = p.street ?? '';
          _numeroController.text = p.subThoroughfare ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localização e endereço preenchidos!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAddressLoading = false);
    }
  }

  Future<void> _pickImage(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () => Navigator.of(ctx).pop(ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Câmera'), onTap: () => Navigator.of(ctx).pop(ImageSource.camera)),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null) {
        setState(() {
          _photoPaths[index] = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.red));
      return;
    }
    
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    // Populate the model from controllers and state variables
    _ocorrencia.numero_pit = _numeroPitController.text;
    _ocorrencia.codigo_localidade = _codigoLocalidadeController.text;
    _ocorrencia.categoria_localidade = _categoriaLocalidadeController.text;
    _ocorrencia.localidade = _localidadeController.text;
    _ocorrencia.endereco = _enderecoController.text;
    _ocorrencia.numero = _numeroController.text;
    _ocorrencia.complemento = _complementoController.text;
    _ocorrencia.nome_morador = _nomeMoradorController.text;
    _ocorrencia.num_barbeiros_intradomicilio = int.tryParse(_numBarbeirosIntraController.text);
    _ocorrencia.num_barbeiros_peridomicilio = int.tryParse(_numBarbeirosPeriController.text);
    _ocorrencia.codigo_etiqueta = _codigoEtiquetaController.text;
    _ocorrencia.foto_url_1 = _photoPaths[0];
    _ocorrencia.foto_url_2 = _photoPaths[1];
    _ocorrencia.foto_url_3 = _photoPaths[2];
    _ocorrencia.foto_url_4 = _photoPaths[3];

    try {
      await Provider.of<OcorrenciaSiocchagasService>(context, listen: false).saveOcorrencia(_ocorrencia);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro salvo localmente com sucesso!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Novo Registro Proativo'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLocationBlock(),
              const SizedBox(height: 24),
              _buildActivityBlock(),
              const SizedBox(height: 24),
              _buildHouseholdBlock(),
              const SizedBox(height: 24),
              _buildCaptureBlock(),
              const SizedBox(height: 24),
              _buildSprayingBlock(),
              const SizedBox(height: 24),
              _buildPendencyBlock(),
              const SizedBox(height: 24),
              _buildMediaBlock(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveForm,
                child: _isLoading ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)) : const Text('Salvar Registro Local'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));

  Widget _buildLocationBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Localização e Endereço'),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _isAddressLoading ? null : _getCurrentLocation, icon: _isAddressLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location), label: const Text('Obter Localização e Endereço')),
      if (_ocorrencia.gps_latitude != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Lat: ${_ocorrencia.gps_latitude}, Lon: ${_ocorrencia.gps_longitude}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      const SizedBox(height: 16),
      TextFormField(initialValue: _ocorrencia.municipio, decoration: const InputDecoration(labelText: 'Município'), readOnly: true),
      const SizedBox(height: 12), TextFormField(controller: _localidadeController, decoration: const InputDecoration(labelText: 'Localidade')),
      const SizedBox(height: 12), TextFormField(controller: _enderecoController, decoration: const InputDecoration(labelText: 'Endereço')),
      const SizedBox(height: 12), TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número')),
      const SizedBox(height: 12), TextFormField(controller: _complementoController, decoration: const InputDecoration(labelText: 'Complemento')),
    ])));
  }

  Widget _buildActivityBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Dados da Atividade'),
      const SizedBox(height: 16),
       TextFormField(
          controller: _dataAtividadeController,
          decoration: const InputDecoration(labelText: 'Data da Atividade', suffixIcon: Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(context: context, initialDate: _ocorrencia.data_atividade!, firstDate: DateTime(2000), lastDate: DateTime.now());
            if (pickedDate != null) {
              setState(() {
                _ocorrencia.data_atividade = pickedDate;
                _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
              });
            }
          },
        ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _ocorrencia.tipo_atividade,
        decoration: const InputDecoration(labelText: 'Tipo de Atividade'),
        items: ['Pesquisa', 'Borrifação', 'Atendimento ao PIT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.tipo_atividade = val),
        validator: (v) => v == null ? 'Campo obrigatório' : null,
      ),
      const SizedBox(height: 12), TextFormField(controller: _numeroPitController, decoration: const InputDecoration(labelText: 'Número do PIT')),
      const SizedBox(height: 12), TextFormField(controller: _codigoLocalidadeController, decoration: const InputDecoration(labelText: 'Código da Localidade')),
      const SizedBox(height: 12), TextFormField(controller: _categoriaLocalidadeController, decoration: const InputDecoration(labelText: 'Categoria da Localidade')),
    ])));
  }

  Widget _buildHouseholdBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Dados do Domicílio'),
      const SizedBox(height: 16), TextFormField(controller: _nomeMoradorController, decoration: const InputDecoration(labelText: 'Nome do Morador')),
      const SizedBox(height: 12), DropdownButtonFormField<int>(
        value: _ocorrencia.numero_anexo,
        decoration: const InputDecoration(labelText: 'Número Anexo'),
        items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.numero_anexo = val),
      ),
      const SizedBox(height: 12), DropdownButtonFormField<String>(
        value: _ocorrencia.situacao_imovel,
        decoration: const InputDecoration(labelText: 'Situação do Imóvel'),
        items: ['Reconhecida', 'Nova', 'Demolida'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.situacao_imovel = val),
      ),
      const SizedBox(height: 12), DropdownButtonFormField<String>(
        value: _ocorrencia.tipo_parede,
        decoration: const InputDecoration(labelText: 'Tipo de Parede'),
        items: ['Alvenaria', 'Barro', 'Madeira', 'Outro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.tipo_parede = val),
      ),
      const SizedBox(height: 12), DropdownButtonFormField<String>(
        value: _ocorrencia.tipo_teto,
        decoration: const InputDecoration(labelText: 'Tipo de Teto'),
        items: ['Telha', 'Palha', 'Madeira', 'Metálico', 'Outro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.tipo_teto = val),
      ),
      const SizedBox(height: 12), SwitchListTile(title: const Text('Melhoria Habitacional'), value: _ocorrencia.melhoria_habitacional ?? false, onChanged: (val) => setState(() => _ocorrencia.melhoria_habitacional = val)),
    ])));
  }

  Widget _buildCaptureBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Captura Triatomíneo'),
      const SizedBox(height: 16),
      Text('Intradomicílio', style: Theme.of(context).textTheme.titleMedium),
      DropdownButtonFormField<String>(value: _ocorrencia.triatomineo_intradomicilio, decoration: const InputDecoration(labelText: 'Triatomíneo'), items: ['Triatomíneo', 'Nenhum'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _ocorrencia.triatomineo_intradomicilio = val)),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: _ocorrencia.vestigios_intradomicilio, decoration: const InputDecoration(labelText: 'Vestígios'), items: ['Ovos', 'Nenhum'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _ocorrencia.vestigios_intradomicilio = val)),
      const SizedBox(height: 12), TextFormField(controller: _numBarbeirosIntraController, decoration: const InputDecoration(labelText: 'Nº de Barbeiros'), keyboardType: TextInputType.number),
      const Divider(height: 24),
      Text('Peridomicílio', style: Theme.of(context).textTheme.titleMedium),
      DropdownButtonFormField<String>(value: _ocorrencia.triatomineo_peridomicilio, decoration: const InputDecoration(labelText: 'Triatomíneo'), items: ['Triatomíneo', 'Nenhum'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _ocorrencia.triatomineo_peridomicilio = val)),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: _ocorrencia.vestigios_peridomicilio, decoration: const InputDecoration(labelText: 'Vestígios'), items: ['Ovos', 'Nenhum'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _ocorrencia.vestigios_peridomicilio = val)),
      const SizedBox(height: 12), TextFormField(controller: _numBarbeirosPeriController, decoration: const InputDecoration(labelText: 'Nº de Barbeiros'), keyboardType: TextInputType.number),
    ])));
  }

  Widget _buildSprayingBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Borrifação'),
      const SizedBox(height: 16), DropdownButtonFormField<String>(
        value: _ocorrencia.inseticida,
        decoration: const InputDecoration(labelText: 'Inseticida'),
        items: ['Alfacipermetrina', 'Deltametrina'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.inseticida = val),
      ),
      const SizedBox(height: 12), DropdownButtonFormField<int>(
        value: _ocorrencia.numero_cargas,
        decoration: const InputDecoration(labelText: 'Número de Cargas'),
        items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.numero_cargas = val),
      ),
      const SizedBox(height: 12), TextFormField(controller: _codigoEtiquetaController, decoration: const InputDecoration(labelText: 'Código da Etiqueta')),
    ])));
  }

  Widget _buildPendencyBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Pendências'),
      const SizedBox(height: 16), DropdownButtonFormField<String>(
        value: _ocorrencia.pendencia_pesquisa,
        decoration: const InputDecoration(labelText: 'Pendência Pesquisa'),
        items: ['Sem pendências', 'Domicílio fechado', 'Recusa'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.pendencia_pesquisa = val),
      ),
      const SizedBox(height: 12), DropdownButtonFormField<String>(
        value: _ocorrencia.pendencia_borrifacao,
        decoration: const InputDecoration(labelText: 'Pendência Borrifação'),
        items: ['Sem pendências', 'Domicílio fechado', 'Recusa'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _ocorrencia.pendencia_borrifacao = val),
      ),
    ])));
  }

  Widget _buildMediaBlock() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Mídia (Fotos)'),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 4 / 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemBuilder: (context, index) {
          if (_photoPaths[index] != null) {
            return Stack(alignment: Alignment.topRight, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_photoPaths[index]!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
              IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)), onPressed: () => setState(() => _photoPaths[index] = null)),
            ]);
          }
          return GestureDetector(
            onTap: () => _pickImage(index),
            child: Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 40)),
          );
        },
      ),
    ])));
  }
}
