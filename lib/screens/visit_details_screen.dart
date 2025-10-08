import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

enum StatusVisita { realizada, fechado, recusada }
enum ResultadoInspecao { confirmada, descartada, naoAvaliavel }
enum LocalCaptura { intradomicilio, peridomicilio }

class VisitDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> denuncia;
  const VisitDetailsScreen({super.key, required this.denuncia});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isNewOccurrence;
  bool _isSaving = false;
  XFile? _agentPhoto;

  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  double? _latitude;
  double? _longitude;

  StatusVisita? _statusVisita;
  ResultadoInspecao? _resultadoInspecao;
  bool _amostraColetada = false;
  String? _especieSuspeita;
  LocalCaptura? _localCaptura;
  final _quantidadeController = TextEditingController();
  String? _tipoMoradia;
  bool _notificarRiscos = false;
  final _riscosSociaisController = TextEditingController();
  final _riscosSanitariosController = TextEditingController();
  final _observacoesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isNewOccurrence = widget.denuncia.isEmpty || widget.denuncia['id'] == null;
    if (!_isNewOccurrence) {
      _populateFields(widget.denuncia);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _ruaController.text = data['rua'] ?? '';
    _numeroController.text = data['numero']?.toString() ?? '';
    _bairroController.text = data['bairro'] ?? '';
    _cidadeController.text = data['cidade'] ?? '';
    _estadoController.text = data['estado'] ?? '';
    _latitude = (data['latitude'] as num?)?.toDouble();
    _longitude = (data['longitude'] as num?)?.toDouble();
    if (data['status'] != null) _statusVisita = StatusVisita.values.asNameMap()[data['status']];
    if (data['visit_result'] != null) _resultadoInspecao = ResultadoInspecao.values.asNameMap()[data['visit_result']];
    _amostraColetada = data['sample_collected'] ?? false;
    _especieSuspeita = data['species_suspicion'];
    if (data['capture_location'] != null) _localCaptura = LocalCaptura.values.asNameMap()[data['capture_location']];
    _quantidadeController.text = data['vector_quantity']?.toString() ?? '';
    _tipoMoradia = data['dwelling_type'];
    _riscosSociaisController.text = data['social_risks'] ?? '';
    _riscosSanitariosController.text = data['sanitary_risks'] ?? '';
    _observacoesController.text = data['observations'] ?? '';
    _notificarRiscos = (_riscosSociaisController.text.isNotEmpty || _riscosSanitariosController.text.isNotEmpty);
  }

  @override
  void dispose() {
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _quantidadeController.dispose();
    _riscosSociaisController.dispose();
    _riscosSanitariosController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate() || _statusVisita == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O "Status da Visita" é obrigatório.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSaving = true);

    final Map<String, dynamic> data = {
      'id': _isNewOccurrence ? null : widget.denuncia['id'],
      'created_at': _isNewOccurrence ? DateTime.now().toIso8601String() : widget.denuncia['created_at'],
      'status': _statusVisita!.name,
      'visit_result': _resultadoInspecao?.name,
      'sample_collected': _amostraColetada,
      'species_suspicion': _especieSuspeita,
      'capture_location': _localCaptura?.name,
      'vector_quantity': int.tryParse(_quantidadeController.text),
      'dwelling_type': _tipoMoradia,
      'social_risks': _riscosSociaisController.text.trim(),
      'sanitary_risks': _riscosSanitariosController.text.trim(),
      'observations': _observacoesController.text.trim(),
      'visited_at': DateTime.now().toIso8601String(),
      'rua': _ruaController.text.trim(),
      'numero': _numeroController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'estado': _estadoController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      if (_isNewOccurrence) 'descricao': 'Ocorrência registrada em campo pelo agente.',
    };

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);

    try {
      if (isOnline) {
        String? agentPhotoUrl = _isNewOccurrence ? null : widget.denuncia['agent_image_url'];
        if (_agentPhoto != null) {
          final photoFile = File(_agentPhoto!.path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage.from('imagens_denuncias').upload(fileName, photoFile);
          agentPhotoUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(fileName);
        }
        data['agent_image_url'] = agentPhotoUrl;

        final Map<String, dynamic> cleanData = Map<String, dynamic>.from(data);
        cleanData.remove('created_at');

        if (cleanData['id'] == null) {
          cleanData.remove('id');
          await supabase.from('denuncias').insert(cleanData);
        } else {
          final recordId = cleanData.remove('id');
          await supabase.from('denuncias').update(cleanData).eq('id', recordId);
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso no servidor!'), backgroundColor: Colors.green));
      } else {
        await _saveLocally(data);
      }
    } catch (e) {
      print("Falha ao salvar online, salvando localmente. Erro: $e");
      await _saveLocally(data);
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveLocally(Map<String, dynamic> data) async {
    final Box pendingBox = Hive.box('pending_sync');
    final String uniqueId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final Map<String, dynamic> localData = Map<String, dynamic>.from(data);
    localData['unique_id'] = uniqueId;
    
    await pendingBox.put(uniqueId, localData);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem conexão. Salvo localmente para sincronizar depois.'), backgroundColor: Colors.amber),
      );
    }
  }

  // --- FUNÇÕES DE IMAGEM ATUALIZADAS ---

  // 1. Mostra um diálogo para o usuário escolher entre Câmera e Galeria
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria de Fotos'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. A função _pickImage agora aceita a fonte da imagem (câmera ou galeria)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source, // Usa a fonte escolhida pelo usuário
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        setState(() => _agentPhoto = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- FIM DAS FUNÇÕES DE IMAGEM ---

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviços de localização desativados.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada.')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada permanentemente.')));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e')));
    }
  }

 @override
  Widget build(BuildContext context) {
    final isCommunityDenuncia = widget.denuncia['descricao'] != 'Ocorrência registrada em campo pelo agente.' && !_isNewOccurrence;
    
    // --- CORREÇÃO: Envolvendo o Scaffold com SafeArea ---
    return SafeArea(
      child: Scaffold(
        appBar: GradientAppBar(title: _isNewOccurrence ? 'Nova Ocorrência' : 'Detalhes da Visita'),
        body: SingleChildScrollView(
          // --- CORREÇÃO: Padding ajustado para SafeArea ---
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 16), // Espaçamento que antes era do padding superior
              if (_isNewOccurrence) 
                _buildNewOccurrenceCard(context) 
              else if (isCommunityDenuncia) 
                _buildDenunciaContextCard(context) 
              else 
                _buildAgentOccurrenceContextCard(context),
              const SizedBox(height: 24),
              _buildVisitFormSection(context),
              const SizedBox(height: 24),
              _buildDomicilioSection(context),
              const SizedBox(height: 24),
              _buildDocumentationAndRisksSection(context),
              const SizedBox(height: 32),
              _buildFinalizationSection(context),
              const SizedBox(height: 16), // Espaçamento que antes era do padding inferior
            ]),
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(BuildContext context, String title) => Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));

  Widget _buildNewOccurrenceCard(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle(context, 'Local da Ocorrência'),
          const SizedBox(height: 16),
          TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua / Logradouro', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null)),
          ]),
          const Divider(height: 24),
          ElevatedButton.icon(icon: const Icon(Icons.my_location), label: const Text('Capturar GPS'), onPressed: _isSaving ? null : _getCurrentLocation, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87)),
          if (_latitude != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('GPS capturado: Lat: ${_latitude!.toStringAsFixed(5)}, Lon: ${_longitude!.toStringAsFixed(5)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  Widget _buildDenunciaContextCard(BuildContext context) {
    final denuncia = widget.denuncia;
    final imageUrl = denuncia['image_url'] as String?;
    final endereco = [denuncia['rua'], denuncia['numero'], denuncia['bairro']].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    return Card(
        elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle(context, 'Contexto da Denúncia'),
          const SizedBox(height: 16),
          if (imageUrl != null) Center(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 48, color: Colors.grey)))) else Center(child: Container(height: 200, width: double.infinity, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey))),
          const SizedBox(height: 16),
          Text('Localização:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endereco.isEmpty ? "Endereço não fornecido" : endereco))]),
          const Divider(height: 24),
          Text('Descrição do Morador:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(denuncia['descricao'] ?? 'Nenhuma descrição fornecida.', style: const TextStyle(color: Colors.black54)),
        ]))
    );
  }

  Widget _buildAgentOccurrenceContextCard(BuildContext context) {
    final endereco = [_ruaController.text, _numeroController.text, _bairroController.text].where((s) => s.isNotEmpty).join(', ');
    final agentImageUrl = widget.denuncia['agent_image_url'] as String?;
    return Card(
        elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle(context, 'Registro da Ocorrência'),
          const SizedBox(height: 16),
          Text('Localização:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endereco.isEmpty ? "Endereço não informado" : endereco))]),
          if (agentImageUrl != null) ...[
            const Divider(height: 24),
            Text('Foto Registrada:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(agentImageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Não foi possível carregar a imagem.')))),
          ]
        ]))
    );
  }

  Widget _buildVisitFormSection(BuildContext context) {
    final bool denunciaConfirmada = _resultadoInspecao == ResultadoInspecao.confirmada;
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(context, 'Formulário da Visita'),
        const SizedBox(height: 16),
        const Text('1. Status da Visita', style: TextStyle(fontWeight: FontWeight.bold)),
        ...StatusVisita.values.map((s) => RadioListTile<StatusVisita>(title: Text(s.name.replaceFirst(s.name[0], s.name[0].toUpperCase())), value: s, groupValue: _statusVisita, onChanged: (v) => setState(() => _statusVisita = v))),
        const Divider(height: 24),
        const Text('2. Resultado da Inspeção', style: TextStyle(fontWeight: FontWeight.bold)),
        ...ResultadoInspecao.values.map((r) => RadioListTile<ResultadoInspecao>(title: Text(r.name.replaceFirst(r.name[0], r.name[0].toUpperCase())), value: r, groupValue: _resultadoInspecao, onChanged: (v) => setState(() => _resultadoInspecao = v))),
        if (denunciaConfirmada) ...[
          const Divider(height: 24),
          const Text('3. Detalhes da Coleta', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(title: const Text('Amostra Coletada'), value: _amostraColetada, onChanged: (v) => setState(() => _amostraColetada = v)),
          if (_amostraColetada) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _especieSuspeita, decoration: const InputDecoration(labelText: 'Suspeita de Espécie', border: OutlineInputBorder()), items: ['Triatoma brasiliensis', 'Triatoma pseudomaculata', 'Triatoma sordida', 'Panstrongylus megistus', 'Rhodnius nasutus', 'Outra/Não identificada'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontStyle: FontStyle.italic)))).toList(), onChanged: (v) => setState(() => _especieSuspeita = v)),
            const SizedBox(height: 16),
            TextFormField(controller: _quantidadeController, decoration: const InputDecoration(labelText: 'Quantidade de Vetores', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            const Text('Local da Captura:'),
            ...LocalCaptura.values.map((l) => RadioListTile<LocalCaptura>(title: Text(l.name.replaceFirst(l.name[0], l.name[0].toUpperCase())), value: l, groupValue: _localCaptura, onChanged: (v) => setState(() => _localCaptura = v))),
          ],
        ],
      ]))
    );
  }

  Widget _buildDomicilioSection(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(context, 'Características do Domicílio'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(validator: (v) => v == null ? 'Campo obrigatório' : null, value: _tipoMoradia, decoration: const InputDecoration(labelText: 'Tipo de Moradia', border: OutlineInputBorder()), items: ['Alvenaria', 'Taipa', 'Madeira', 'Outro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _tipoMoradia = v)),
      ]))
    );
  }

  Widget _buildDocumentationAndRisksSection(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(context, 'Documentação e Riscos'),
        const SizedBox(height: 16),
        _buildAgentPhotoWidget(),
        const Divider(height: 24),
        SwitchListTile(title: const Text('Notificar Outros Riscos', style: TextStyle(fontWeight: FontWeight.w500)), value: _notificarRiscos, onChanged: (v) => setState(() => _notificarRiscos = v)),
        if (_notificarRiscos) ...[
          const SizedBox(height: 16),
          TextFormField(controller: _riscosSociaisController, decoration: const InputDecoration(labelText: 'Riscos Sociais', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _riscosSanitariosController, decoration: const InputDecoration(labelText: 'Riscos Sanitários', border: OutlineInputBorder())),
        ],
        const Divider(height: 24),
        TextFormField(controller: _observacoesController, decoration: const InputDecoration(labelText: 'Observações Gerais', border: OutlineInputBorder()), maxLines: 3),
      ]))
    );
  }

  Widget _buildAgentPhotoWidget() {
    final currentImageUrl = widget.denuncia['agent_image_url'] as String?;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Foto do Agente (opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (_agentPhoto == null && currentImageUrl == null)
        OutlinedButton.icon(
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Adicionar Foto'),
          // 3. O botão agora chama o diálogo em vez de abrir a câmera diretamente
          onPressed: _showImageSourceDialog, 
        )
      else
        Stack(alignment: Alignment.topRight, children: [
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _agentPhoto != null ? Image.file(File(_agentPhoto!.path), height: 200, width: double.infinity, fit: BoxFit.cover) : Image.network(currentImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Text('Erro ao carregar imagem')))),
          IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)), onPressed: () => setState(() { _agentPhoto = null; widget.denuncia['agent_image_url'] = null; })),
        ])
    ]);
  }

  Widget _buildFinalizationSection(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveVisit,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      child: _isSaving
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : const Text('Salvar Alterações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
