import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/services/agent_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

// Função auxiliar para formatar nomes de enums para a UI
String formatEnumName(String name) {
  switch (name) {
    case 'pesquisa': return 'Pesquisa';
    case 'borrifacao': return 'Borrifação';
    case 'atendimentoPIT': return 'Atendimento ao PIT';
    case 'reconhecida': return 'Reconhecida (já foi pesquisada)';
    case 'nova': return 'Nova (primeira pesquisa)';
    case 'demolida': return 'Demolida';
    case 'semPendencias': return 'Sem pendências';
    case 'fechado': return 'Domicílio fechado';
    case 'recusa': return 'Recusa';
    case 'triatomineo': return 'Triatomíneo';
    case 'nenhum': return 'Nenhum';
    default: return name;
  }
}

class RegistroOcorrenciaAgenteScreen extends StatefulWidget {
  final Ocorrencia? ocorrencia;
  final Denuncia? denunciaOrigem;

  const RegistroOcorrenciaAgenteScreen({
    super.key,
    this.ocorrencia,
    this.denunciaOrigem,
  });

  @override
  _RegistroOcorrenciaAgenteScreenState createState() =>
      _RegistroOcorrenciaAgenteScreenState();
}

class _RegistroOcorrenciaAgenteScreenState
    extends State<RegistroOcorrenciaAgenteScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isNew;
  late bool _isViewMode;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  final List<String> _localImagePaths = [];
  final List<XFile> _newlyAddedImages = [];

  double? _currentLat;
  double? _currentLng;

  // Controllers
  final _dataAtividadeController = TextEditingController();
  final _numeroPITController = TextEditingController();
  final _municipioController = TextEditingController();
  final _codigoLocalidadeController = TextEditingController();
  final _categoriaLocalidadeController = TextEditingController();
  final _localidadeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _nomeMoradorController = TextEditingController();
  final _numBarbeirosIntraController = TextEditingController();
  final _numBarbeirosPeriController = TextEditingController();
  final _inseticidaController = TextEditingController();
  final _numCargasController = TextEditingController();
  final _codigoEtiquetaController = TextEditingController();
  final _agenteController = TextEditingController();

  TipoAtividade? _tipoAtividade = TipoAtividade.pesquisa;
  bool _realizarBorrifacaoNoPIT = false;
  SituacaoImovel? _situacaoImovel;
  Pendencia? _pendenciaPesquisa, _pendenciaBorrifacao;
  String? _tipoParede, _tipoTeto;
  bool? _melhoriaHabitacional;
  int? _numeroAnexo;
  CapturaStatus? _capturaIntraStatus, _capturaPeriStatus;
  final Map<String, bool> _vestigiosIntra = {'Ovos': false, 'Ninfas': false, 'Exúvias': false, 'Fezes': false, 'Nenhum': false};
  final Map<String, bool> _vestigiosPeri = {'Ovos': false, 'Ninfas': false, 'Exúvias': false, 'Fezes': false, 'Nenhum': false};

  @override
  void initState() {
    super.initState();
    _isNew = widget.ocorrencia == null;
    _isViewMode = !_isNew;

    final agent = context.read<AgentService>().currentAgent;
    _agenteController.text = agent?.nome ?? 'Agente Não Identificado';

    if (widget.ocorrencia != null) {
      _populateFromOcorrencia(widget.ocorrencia!);
    } else if (widget.denunciaOrigem != null) {
      _populateFromDenuncia(widget.denunciaOrigem!);
    } else {
      _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _municipioController.text = agent?.municipioNome ?? '';
      _localidadeController.text = agent?.localidade ?? '';
    }
  }
  
  void _populateFromOcorrencia(Ocorrencia oco) {
    if (oco.localImagePaths != null) _localImagePaths.addAll(oco.localImagePaths!);
    
    _dataAtividadeController.text = oco.data_atividade != null ? DateFormat('dd/MM/yyyy').format(oco.data_atividade!) : '';
    _currentLat = oco.latitude;
    _currentLng = oco.longitude;
    _numeroPITController.text = oco.numero_pit ?? '';
    _municipioController.text = oco.municipio_id ?? '';
    _localidadeController.text = oco.localidade ?? '';
    _enderecoController.text = oco.endereco ?? '';
    _numeroController.text = oco.numero ?? '';
    _complementoController.text = oco.complemento ?? '';
    _nomeMoradorController.text = oco.nome_morador ?? '';
    _numBarbeirosIntraController.text = oco.barbeiros_intradomicilio?.toString() ?? '0';
    _numBarbeirosPeriController.text = oco.barbeiros_peridomicilio?.toString() ?? '0';
    _inseticidaController.text = oco.inseticida ?? '';
    _numCargasController.text = oco.numero_cargas?.toString() ?? '0';
    _codigoEtiquetaController.text = oco.codigo_etiqueta ?? '';

    _tipoAtividade = oco.tipo_atividade;
    _situacaoImovel = oco.situacao_imovel;
    _pendenciaPesquisa = oco.pendencia_pesquisa;
    _pendenciaBorrifacao = oco.pendencia_borrifacao;
    _tipoParede = oco.tipo_parede;
    _tipoTeto = oco.tipo_teto;
    _melhoriaHabitacional = oco.melhoria_habitacional;
    _numeroAnexo = oco.numero_anexo;
  }

  void _populateFromDenuncia(Denuncia den) {
    final agent = context.read<AgentService>().currentAgent;
    _tipoAtividade = TipoAtividade.atendimentoPIT;
    _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _numeroPITController.text = den.id.toString(); // Using denuncia ID as PIT number context
    _municipioController.text = den.municipioId ?? agent?.municipioId ?? '';
    _localidadeController.text = den.bairro ?? agent?.localidade ?? '';
    _enderecoController.text = den.rua ?? '';
    _numeroController.text = den.numero ?? '';
    _complementoController.text = den.bairro ?? '';
    _currentLat = den.latitude;
    _currentLng = den.longitude;
  }

  @override
  void dispose() {
    _dataAtividadeController.dispose();
    _numeroPITController.dispose();
    _municipioController.dispose();
    _codigoLocalidadeController.dispose();
    _categoriaLocalidadeController.dispose();
    _localidadeController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _nomeMoradorController.dispose();
    _numBarbeirosIntraController.dispose();
    _numBarbeirosPeriController.dispose();
    _inseticidaController.dispose();
    _numCargasController.dispose();
    _codigoEtiquetaController.dispose();
    _agenteController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final agentService = context.read<AgentService>();
    final agent = agentService.currentAgent; // Será null no modo de teste, e isso está OK.

    // O bloqueio que verificava se o agente era nulo foi removido.

    final id = widget.ocorrencia?.id ?? const Uuid().v4();
    final dataAtividade = DateFormat('dd/MM/yyyy').tryParse(_dataAtividadeController.text) ?? DateTime.now();
    final allImagePaths = [..._localImagePaths, ..._newlyAddedImages.map((f) => f.path)];

    final ocorrencia = Ocorrencia(
      id: id,
      // Campos do agente agora são nulos se não houver agente (modo teste)
      agente_id: agent?.id,
      denuncia_id: widget.denunciaOrigem?.id,
      municipio_id: agent?.municipioId,
      setor_id: agent?.setorId,
      tipo_atividade: _tipoAtividade,
      data_atividade: dataAtividade,
      numero_pit: _numeroPITController.text,
      localidade: _localidadeController.text,
      endereco: _enderecoController.text,
      numero: _numeroController.text,
      complemento: _complementoController.text,
      pendencia_pesquisa: _pendenciaPesquisa,
      pendencia_borrifacao: _pendenciaBorrifacao,
      nome_morador: _nomeMoradorController.text,
      numero_anexo: _numeroAnexo,
      situacao_imovel: _situacaoImovel,
      tipo_parede: _tipoParede,
      tipo_teto: _tipoTeto,
      melhoria_habitacional: _melhoriaHabitacional,
      vestigios_intradomicilio: _vestigiosIntra['Nenhum']! ? 'Nenhum' : _vestigiosIntra.keys.where((k) => k != 'Nenhum' && _vestigiosIntra[k]!).join(', '),
      barbeiros_intradomicilio: int.tryParse(_numBarbeirosIntraController.text) ?? 0,
      vestigios_peridomicilio: _vestigiosPeri['Nenhum']! ? 'Nenhum' : _vestigiosPeri.keys.where((k) => k != 'Nenhum' && _vestigiosPeri[k]!).join(', '),
      barbeiros_peridomicilio: int.tryParse(_numBarbeirosPeriController.text) ?? 0,
      inseticida: _inseticidaController.text,
      numero_cargas: int.tryParse(_numCargasController.text) ?? 0,
      codigo_etiqueta: _codigoEtiquetaController.text,
      latitude: _currentLat,
      longitude: _currentLng,
      localImagePaths: allImagePaths,
      created_at: DateTime.now(),
    );

    try {
      if (_isNew) {
        await agentService.criarOcorrencia(ocorrencia);
      } else {
        await agentService.editarOcorrencia(ocorrencia);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isNew ? 'Ocorrência salva localmente!' : 'Alterações salvas!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  // --- UI Build ---
  
  @override
  Widget build(BuildContext context) {
    bool isBasedOnDenuncia = widget.denunciaOrigem != null;
    bool showSprayingSection = _tipoAtividade == TipoAtividade.borrifacao || (_tipoAtividade == TipoAtividade.atendimentoPIT && _realizarBorrifacaoNoPIT);

    return Scaffold(
      appBar: GradientAppBar(title: _isNew ? 'Nova Ocorrência' : (_isViewMode ? 'Detalhes da Visita' : 'Editar Visita')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.ocorrencia != null || !isBasedOnDenuncia) _buildPhotosSection(),
              if (isBasedOnDenuncia) _buildVisitDetailsHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle('1. Dados da Atividade'),
              _buildActivitySection(isViewOnly: _isViewMode, isBasedOnDenuncia: isBasedOnDenuncia),
              const SizedBox(height: 24),
              _buildSectionTitle('2. Dados do Endereço'),
              _buildAddressSection(isViewOnly: _isViewMode),
              const SizedBox(height: 24),
              _buildSectionTitle('3. Dados do Domicílio'),
              _buildHouseholdSection(showSprayingSection, isViewOnly: _isViewMode),
              const SizedBox(height: 24),
              _buildSectionTitle('4. Captura de Triatomíneo'),
              _buildCaptureSection(isViewOnly: _isViewMode),
              if (showSprayingSection) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('5. Borrifação'),
                _buildSprayingSection(isViewOnly: _isViewMode),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('6. Agente Responsável'),
              _buildAgentSection(),
              const SizedBox(height: 32),
              if (!_isViewMode)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveForm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(_isNew ? 'Salvar Registro' : 'Salvar Alterações', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isViewMode
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _isViewMode = false),
              label: const Text('Editar'),
              icon: const Icon(Icons.edit),
            )
          : null,
    );
  }

  // --- UI Section Widgets (RESTORED) ---

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)));

  Widget _buildPhotosSection() {
    final allImages = [..._localImagePaths, ..._newlyAddedImages.map((p) => p.path)];

    if (_isViewMode && allImages.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle("Fotos da Visita"),
            const SizedBox(height: 16),
            if (allImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final imageSource = allImages[index];
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: SmartImage(imageSource: imageSource)),
                      if (!_isViewMode)
                        IconButton(
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          icon: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 16)),
                          onPressed: () => setState(() {
                            _newlyAddedImages.removeWhere((img) => img.path == imageSource);
                            _localImagePaths.remove(imageSource);
                          }),
                        ),
                    ],
                  );
                },
              ),
            if (!_isViewMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(icon: const Icon(Icons.camera_alt_outlined), label: const Text('Adicionar Fotos'), onPressed: _showImageSourceDialog),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDetailsHeader() {
    final denuncia = widget.denunciaOrigem;
    if (denuncia == null) return const SizedBox.shrink();

    final endereco = [denuncia.rua, denuncia.numero, denuncia.bairro].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contexto da Denúncia Original'),
            const SizedBox(height: 16),
            const Text('Localização Informada:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endereco.isEmpty ? "Endereço não fornecido" : endereco))]),
            const Divider(height: 24),
            const Text('Descrição do Morador:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(denuncia.descricao ?? 'Nenhuma descrição fornecida.', style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection({required bool isViewOnly, required bool isBasedOnDenuncia}) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tipo de Atividade', style: TextStyle(fontWeight: FontWeight.bold)),
        ...TipoAtividade.values.map((tipo) => RadioListTile<TipoAtividade>(
            title: Text(formatEnumName(tipo.name)), 
            value: tipo, 
            groupValue: _tipoAtividade, 
            onChanged: isViewOnly || isBasedOnDenuncia ? null : (v) => setState(() => _tipoAtividade = v))),
        const Divider(),
        TextFormField(
          controller: _dataAtividadeController,
          decoration: const InputDecoration(labelText: 'Data da Atividade', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: isViewOnly ? null : _selectDate,
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
        if (_tipoAtividade == TipoAtividade.atendimentoPIT) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _numeroPITController,
            readOnly: isViewOnly || isBasedOnDenuncia,
            decoration: InputDecoration(labelText: 'Número do PIT', border: const OutlineInputBorder(), fillColor: isViewOnly || isBasedOnDenuncia ? Colors.black12 : null, filled: isViewOnly || isBasedOnDenuncia),
            keyboardType: TextInputType.number,
            validator: (v) => (_tipoAtividade == TipoAtividade.atendimentoPIT && (v == null || v.isEmpty)) ? 'Campo obrigatório' : null,
          ),
          SwitchListTile(
            title: const Text('Realizar borrifação nesta visita?'),
            value: _realizarBorrifacaoNoPIT,
            onChanged: isViewOnly ? null : (bool value) => setState(() => _realizarBorrifacaoNoPIT = value),
          ),
        ],
      ]))
    );
  }
  
  Widget _buildAddressSection({required bool isViewOnly}) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!isViewOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: OutlinedButton.icon(
              icon: _isGettingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
              label: const Text('Usar Minha Localização'),
              onPressed: _isGettingLocation ? null : _getCurrentLocationAndFillAddress,
            ),
          ),
        TextFormField(controller: _municipioController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Município', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _localidadeController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: '*Localidade', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _enderecoController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextFormField(controller: _numeroController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextFormField(controller: _complementoController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Complemento', border: OutlineInputBorder())),
      ]))
    );
  }

  Widget _buildHouseholdSection(bool showSprayingPendency, {required bool isViewOnly}) {
    final paredes = ["Alvenaria com reboco", "Alvenaria sem reboco", "Barro com reboco", "Barro sem reboco", "Outros"];
    final tetos = ["Telha", "Palha", "Madeira", "Nenhum"];
    
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pendência', style: TextStyle(fontWeight: FontWeight.bold)),
        ...Pendencia.values.map((p) => RadioListTile<Pendencia>(
            title: Text(formatEnumName(p.name)), value: p,
            groupValue: showSprayingPendency ? _pendenciaBorrifacao : _pendenciaPesquisa,
            onChanged: isViewOnly ? null : (v) => setState(() => showSprayingPendency ? _pendenciaBorrifacao = v : _pendenciaPesquisa = v),
        )),
        const Divider(height: 24),
        TextFormField(controller: _nomeMoradorController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Nome do Morador', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        const Text('Número Anexo', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 4.0, children: List<Widget>.generate(6, (int index) {
          return ChoiceChip(label: Text(index.toString()), selected: _numeroAnexo == index, onSelected: isViewOnly ? null : (bool selected) => setState(() => _numeroAnexo = selected ? index : null));
        })),
        const Divider(height: 24),
        const Text('Situação do Imóvel', style: TextStyle(fontWeight: FontWeight.bold)),
        ...SituacaoImovel.values.map((s) => RadioListTile<SituacaoImovel>(title: Text(formatEnumName(s.name)), value: s, groupValue: _situacaoImovel, onChanged: isViewOnly ? null : (v) => setState(() => _situacaoImovel = v))),
        const Divider(height: 24),
        DropdownButtonFormField<String>(value: _tipoParede, decoration: const InputDecoration(labelText: 'Tipo de Parede', border: OutlineInputBorder()), items: paredes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _tipoParede = v)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _tipoTeto, decoration: const InputDecoration(labelText: 'Tipo de Teto', border: OutlineInputBorder()), items: tetos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _tipoTeto = v)),
        const Divider(height: 24),
        const Text('Melhoria Habitacional', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
            Expanded(child: RadioListTile<bool?>(title: const Text('Sim'), value: true, groupValue: _melhoriaHabitacional, onChanged: isViewOnly ? null : (v) => setState(() => _melhoriaHabitacional = v))),
            Expanded(child: RadioListTile<bool?>(title: const Text('Não'), value: false, groupValue: _melhoriaHabitacional, onChanged: isViewOnly ? null : (v) => setState(() => _melhoriaHabitacional = v))),
        ]),
      ]))
    );
  }

  Widget _buildCaptureSection({required bool isViewOnly}) {
    bool intraDisabled = _capturaIntraStatus == CapturaStatus.nenhum;
    bool periDisabled = _capturaPeriStatus == CapturaStatus.nenhum;

    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Captura Intradomicílio', style: TextStyle(fontWeight: FontWeight.bold)),
        ...CapturaStatus.values.map((s) => RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(s.name)), value: s, groupValue: _capturaIntraStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaIntraStatus = v))),
        AbsorbPointer(absorbing: isViewOnly || intraDisabled, child: Opacity(opacity: isViewOnly || intraDisabled ? 0.5 : 1.0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(controller: _numBarbeirosIntraController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Nº de Barbeiros Capturados'), keyboardType: TextInputType.number),
          const SizedBox(height: 8), const Text('Vestígios Encontrados:'),
          ..._vestigiosIntra.keys.map((key) => CheckboxListTile(title: Text(key), value: _vestigiosIntra[key], onChanged: isViewOnly ? null : (value) => _handleVestigiosChange(_vestigiosIntra, key, value!)))
        ]))),
        const Divider(height: 24),
        const Text('Captura Peridomicílio', style: TextStyle(fontWeight: FontWeight.bold)),
        ...CapturaStatus.values.map((s) => RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(s.name)), value: s, groupValue: _capturaPeriStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaPeriStatus = v))),
        AbsorbPointer(absorbing: isViewOnly || periDisabled, child: Opacity(opacity: isViewOnly || periDisabled ? 0.5 : 1.0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(controller: _numBarbeirosPeriController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Nº de Barbeiros Capturados'), keyboardType: TextInputType.number),
          const SizedBox(height: 8), const Text('Vestígios Encontrados:'),
          ..._vestigiosPeri.keys.map((key) => CheckboxListTile(title: Text(key), value: _vestigiosPeri[key], onChanged: isViewOnly ? null : (value) => _handleVestigiosChange(_vestigiosPeri, key, value!)))
        ]))),
      ]))
    );
  }

  Widget _buildSprayingSection({required bool isViewOnly}) {
    final inseticidas = ["Alfacipermetrina", "Deltametrina"];
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(value: _inseticidaController.text.isEmpty ? null : _inseticidaController.text, decoration: const InputDecoration(labelText: 'Inseticida', border: OutlineInputBorder()), items: inseticidas.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _inseticidaController.text = v!)),
        const SizedBox(height: 16),
        TextFormField(controller: _numCargasController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Número de Cargas', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        TextFormField(controller: _codigoEtiquetaController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Código da Etiqueta', border: OutlineInputBorder())),
      ]))
    );
  }
  
  Widget _buildAgentSection() {
     return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: 
        TextFormField(
          controller: _agenteController,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Agente de Endemias', border: OutlineInputBorder(), fillColor: Colors.black12, filled: true),
        ),
      )
    );
  }

  // --- Helper Methods (RESTORED) ---
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() => _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(picked));
    }
  }

  Future<void> _getCurrentLocationAndFillAddress() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationUtil.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _municipioController.text = place.subAdministrativeArea ?? '';
          _localidadeController.text = place.subLocality ?? place.locality ?? '';
          _enderecoController.text = place.street ?? '';
          _numeroController.text = place.subThoroughfare ?? '';
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço preenchido!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return SafeArea(child: Wrap(children: <Widget>[
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); }),
          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Câmera'), onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); }),
      ]));
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1024);
        setState(() => _newlyAddedImages.addAll(pickedFiles));
      } else {
        final pickedFile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
        if (pickedFile != null) setState(() => _newlyAddedImages.add(pickedFile));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagens: $e'), backgroundColor: Colors.red));
    }
  }

  void _handleVestigiosChange(Map<String, bool> vestigios, String key, bool value) {
    setState(() {
      if (key == 'Nenhum' && value) {
        vestigios.updateAll((k, v) => false);
        vestigios['Nenhum'] = true;
      } else {
        vestigios[key] = value;
        if (value) vestigios['Nenhum'] = false;
      }
    });
  }
}
