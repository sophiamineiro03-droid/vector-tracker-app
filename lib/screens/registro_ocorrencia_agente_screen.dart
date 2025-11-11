import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_tracker_app/models/agente.dart';
import 'package:vector_tracker_app/models/denuncia.dart';
import 'package:vector_tracker_app/models/localidade_simples.dart';
import 'package:vector_tracker_app/models/ocorrencia.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/repositories/agente_repository.dart';
import 'package:vector_tracker_app/services/agent_ocorrencia_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

String formatEnumName(String name) {
  switch (name) {
    case 'pesquisa':
      return 'Pesquisa';
    case 'borrifacao':
      return 'Borrifação';
    case 'atendimentoPIT':
      return 'Atendimento ao PIT';
    case 'reconhecida':
      return 'Reconhecida (já foi pesquisada)';
    case 'nova':
      return 'Nova (primeira pesquisa)';
    case 'demolida':
      return 'Demolida';
    case 'semPendencias':
      return 'Sem pendências';
    case 'fechado':
      return 'Domicílio fechado';
    case 'recusa':
      return 'Recusa';
    case 'triatomineo':
      return 'Triatomíneo';
    case 'nenhum':
      return 'Nenhum';
    default:
      return name;
  }
}

class RegistroOcorrenciaAgenteScreen extends StatefulWidget {
  final Ocorrencia? ocorrencia;
  final Denuncia? denunciaOrigem;

  const RegistroOcorrenciaAgenteScreen({
    super.key,
    this.ocorrencia,
    this.denunciaOrigem,
    this.isViewOnly = false,
  });

  final bool isViewOnly;

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
  String? _openPanelKey = 'atividade';
  final List<String> _localImagePaths = [];
  final List<XFile> _newlyAddedImages = [];
  double? _currentLat;
  double? _currentLng;

  bool _isLoading = true;
  List<LocalidadeSimples> _localidadesAgente = [];
  String? _selectedLocalidadeId;

  final _dataAtividadeController = TextEditingController();
  final _numeroPITController = TextEditingController();
  final _municipioController = TextEditingController();
  final _codigoLocalidadeController = TextEditingController();
  final _categoriaLocalidadeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _nomeMoradorController = TextEditingController();
  final _numBarbeirosIntraController = TextEditingController(text: '0');
  final _numBarbeirosPeriController = TextEditingController(text: '0');
  final _inseticidaController = TextEditingController();
  final _numCargasController = TextEditingController(text: '0');
  final _codigoEtiquetaController = TextEditingController();
  final _agenteController = TextEditingController();

  final Set<TipoAtividade> _tiposAtividade = {TipoAtividade.pesquisa};
  SituacaoImovel? _situacaoImovel;
  Pendencia? _pendenciaPesquisa = Pendencia.semPendencias;
  Pendencia? _pendenciaBorrifacao = Pendencia.semPendencias;
  String? _tipoParede, _tipoTeto;
  bool? _melhoriaHabitacional;
  int? _numeroAnexo;
  CapturaStatus? _capturaIntraStatus = CapturaStatus.nenhum;
  CapturaStatus? _capturaPeriStatus = CapturaStatus.nenhum;
  final Map<String, bool> _vestigiosIntra = {'Ovos': false, 'Nenhum': true};
  final Map<String, bool> _vestigiosPeri = {'Ovos': false, 'Nenhum': true};

  @override
  void initState() {
    super.initState();
    _isNew = widget.ocorrencia == null;
    _isViewMode = widget.isViewOnly;
    _initializeFormData();
  }

  Future<void> _initializeFormData() async {
    if (!mounted) return;

    final agent = await context.read<AgenteRepository>().getCurrentAgent();
    if (agent != null && mounted) {
      setState(() {
        _agenteController.text = agent.nome;
        _municipioController.text = agent.municipioNome ?? '';
        _localidadesAgente = agent.localidades;
      });
    }

    if (widget.ocorrencia != null) {
      _populateFromOcorrencia(widget.ocorrencia!);
    } else if (widget.denunciaOrigem != null) {
      _populateFromDenuncia(widget.denunciaOrigem!);
    } else {
      _dataAtividadeController.text =
          DateFormat('dd/MM/yyyy').format(DateTime.now());
      if (_localidadesAgente.isNotEmpty) {
        _onLocalidadeChanged(_localidadesAgente.first.id);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLocalidadeChanged(String? newId) {
    if (newId == null) return;
    setState(() {
      _selectedLocalidadeId = newId;
      _codigoLocalidadeController.clear();
      _categoriaLocalidadeController.clear();
    });
  }

  void _populateFromOcorrencia(Ocorrencia oco) {
    if (oco.localImagePaths != null) {
      _localImagePaths.addAll(oco.localImagePaths!);
    }
    _dataAtividadeController.text = oco.data_atividade != null
        ? DateFormat('dd/MM/yyyy').format(oco.data_atividade!)
        : '';
    _currentLat = oco.latitude;
    _currentLng = oco.longitude;
    _numeroPITController.text = oco.numero_pit ?? '';
    _municipioController.text = oco.municipio_id_ui ?? '';

    if (oco.localidade_id != null) {
      _selectedLocalidadeId = oco.localidade_id;
    }
    _codigoLocalidadeController.text = oco.codigo_localidade ?? '';
    _categoriaLocalidadeController.text = oco.categoria_localidade ?? '';

    _enderecoController.text = oco.endereco ?? '';
    _numeroController.text = oco.numero ?? '';
    _complementoController.text = oco.complemento ?? '';
    _nomeMoradorController.text = oco.nome_morador ?? '';
    _numBarbeirosIntraController.text =
        oco.barbeiros_intradomicilio?.toString() ?? '0';
    _numBarbeirosPeriController.text =
        oco.barbeiros_peridomicilio?.toString() ?? '0';
    _inseticidaController.text = oco.inseticida ?? '';
    _numCargasController.text = oco.numero_cargas?.toString() ?? '0';
    _codigoEtiquetaController.text = oco.codigo_etiqueta ?? '';

    _tiposAtividade.clear();
    if (oco.tipo_atividade != null) {
      for (var tipo in oco.tipo_atividade!) {
        _tiposAtividade.add(tipo);
      }
    }

    _situacaoImovel = oco.situacao_imovel;
    _pendenciaPesquisa = oco.pendencia_pesquisa;
    _pendenciaBorrifacao = oco.pendencia_borrifacao;
    _tipoParede = oco.tipo_parede;
    _tipoTeto = oco.tipo_teto;
    _melhoriaHabitacional = oco.melhoria_habitacional;
    _numeroAnexo = oco.numero_anexo;
  }

  void _populateFromDenuncia(Denuncia den) {
    _tiposAtividade.clear();

    _dataAtividadeController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    _municipioController.text = den.cidade ?? '';
    _enderecoController.text = den.rua ?? '';
    _numeroController.text = den.numero ?? '';
    _complementoController.text = den.complemento ?? '';
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
    if (_isViewMode) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, corrija os erros em vermelho.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);

    final agentOcorrenciaService = context.read<AgentOcorrenciaService>();

    final dataAtividade =
        DateFormat('dd/MM/yyyy').tryParse(_dataAtividadeController.text) ??
            DateTime.now();

    final ocorrenciaToSave = Ocorrencia(
      id: widget.ocorrencia?.id ?? const Uuid().v4(),
      agente_id: context.read<AgenteRepository>().getCurrentAgent().toString(),
      denuncia_id: widget.denunciaOrigem?.id,
      localidade_id: _selectedLocalidadeId,
      tipo_atividade: _tiposAtividade.toList(),
      data_atividade: dataAtividade,
      numero_pit: _numeroPITController.text,
      codigo_localidade: _codigoLocalidadeController.text,
      categoria_localidade: _categoriaLocalidadeController.text,
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
      vestigios_intradomicilio: _vestigiosIntra['Nenhum']!
          ? 'Nenhum'
          : _vestigiosIntra.keys
              .where((k) => k != 'Nenhum' && _vestigiosIntra[k]!)
              .join(', '),
      barbeiros_intradomicilio:
          int.tryParse(_numBarbeirosIntraController.text) ?? 0,
      vestigios_peridomicilio: _vestigiosPeri['Nenhum']!
          ? 'Nenhum'
          : _vestigiosPeri.keys
              .where((k) => k != 'Nenhum' && _vestigiosPeri[k]!)
              .join(', '),
      barbeiros_peridomicilio:
          int.tryParse(_numBarbeirosPeriController.text) ?? 0,
      inseticida: _inseticidaController.text,
      numero_cargas: int.tryParse(_numCargasController.text) ?? 0,
      codigo_etiqueta: _codigoEtiquetaController.text,
      latitude: _currentLat,
      longitude: _currentLng,
      created_at: widget.ocorrencia?.created_at ?? DateTime.now(),
      localImagePaths: [
        ..._localImagePaths,
        ..._newlyAddedImages.map((f) => f.path)
      ],
      sincronizado: false,
      municipio_id_ui: _municipioController.text,
      setor_id_ui: widget.ocorrencia?.setor_id_ui,
    );

    try {
      await agentOcorrenciaService.saveOcorrencia(ocorrenciaToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _isNew ? 'Ocorrência salva com sucesso!' : 'Alterações salvas!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.denunciaOrigem != null
            ? 'Atender Denúncia'
            : (_isNew
                ? 'Novo Registro Proativo'
                : (_isViewMode ? 'Detalhes da Visita' : 'Editar Visita')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.denunciaOrigem != null) ...[
                              _buildDenunciaContextCard(widget.denunciaOrigem!),
                              const SizedBox(height: 24),
                            ],
                            TextFormField(
                              controller: _municipioController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Município',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.black12,
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Campo obrigatório'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildExpansionPanelList(context, titleStyle),
                          ],
                        ),
                      ),
                    ),
                    if (!_isViewMode) _buildSaveButton(theme),
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

  Widget _buildDenunciaContextCard(Denuncia denuncia) {
    final theme = Theme.of(context);
    String endereco =
        '${denuncia.rua ?? ''}, ${denuncia.numero ?? ''} - ${denuncia.bairro ?? ''}';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contexto da Denúncia',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (denuncia.foto_url != null && denuncia.foto_url!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SmartImage(
                  imageSource: denuncia.foto_url!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(context, Icons.description, 'Descrição',
                denuncia.descricao ?? 'Nenhuma descrição informada'),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.location_on, 'Endereço', endereco),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.home_work, 'Complemento',
                denuncia.complemento ?? 'Não informado'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionPanelList(BuildContext context, TextStyle? titleStyle) {
    final isViewOnly = _isViewMode;

    final List<_FormPanelItem> panelItems = [
      _FormPanelItem(
          key: 'atividade',
          header: '1. Dados da Atividade',
          body: _buildActivitySection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'domicilio',
          header: '2. Dados do Domicílio',
          body: _buildAddressSection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'detalhes_domicilio',
          header: '3. Detalhes do Domicílio',
          body: _buildHouseholdDetailsSection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'captura',
          header: '4. Captura de Triatomíneos',
          body: _buildCaptureSection(isViewOnly: isViewOnly)),
      if (_tiposAtividade.contains(TipoAtividade.borrifacao))
        _FormPanelItem(
            key: 'borrifacao',
            header: '5. Borrifação',
            body: _buildSprayingSection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'etiqueta',
          header: '6. Código de Etiqueta',
          body: _buildLabelCodeSection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'fotos',
          header: '7. Fotos',
          body: _buildImageSection(isViewOnly: isViewOnly)),
      _FormPanelItem(
          key: 'agente',
          header: '8. Agente Responsável',
          body: _buildAgentSection()),
    ];

    return ExpansionPanelList.radio(
      initialOpenPanelValue: _openPanelKey,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _openPanelKey = isExpanded ? null : panelItems[index].key;
        });
      },
      children: panelItems.map<ExpansionPanelRadio>((item) {
        return ExpansionPanelRadio(
          value: item.key,
          canTapOnHeader: true,
          headerBuilder: (context, isExpanded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(item.header, style: titleStyle),
            );
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: item.body,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySection({required bool isViewOnly}) {
    return _FormSection(
      children: [
        _buildFieldLabel(context, 'Tipo de Atividade*'),
        ...TipoAtividade.values.map((tipo) {
          return CheckboxListTile(
            title: Text(formatEnumName(tipo.name)),
            value: _tiposAtividade.contains(tipo),
            onChanged: isViewOnly
                ? null
                : (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _tiposAtividade.add(tipo);
                      } else {
                        _tiposAtividade.remove(tipo);
                      }
                    });
                  },
          );
        }).toList(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dataAtividadeController,
          decoration: const InputDecoration(
              labelText: 'Data da Atividade*',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: isViewOnly ? null : _selectDate,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
        if (_tiposAtividade.contains(TipoAtividade.atendimentoPIT)) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _numeroPITController,
            readOnly: isViewOnly,
            decoration: InputDecoration(
              labelText: 'Número do PIT*',
              border: const OutlineInputBorder(),
              fillColor: isViewOnly ? Colors.black12 : null,
              filled: isViewOnly,
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (_tiposAtividade.contains(TipoAtividade.atendimentoPIT) &&
                        (v == null || v.isEmpty))
                    ? 'Campo obrigatório'
                    : null,
          ),
        ],
      ],
    );
  }

  Widget _buildAddressSection({required bool isViewOnly}) {
    return _FormSection(
      children: [
        if (!isViewOnly) ...[
          OutlinedButton.icon(
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Usar Minha Localização'),
            onPressed:
                _isGettingLocation ? null : _getCurrentLocationAndFillAddress,
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedLocalidadeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Localidade*',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Selecione uma localidade'),
              items: _localidadesAgente.map((localidade) {
                return DropdownMenuItem(
                  value: localidade.id,
                  child: Text(localidade.nome),
                );
              }).toList(),
              onChanged: isViewOnly ? null : _onLocalidadeChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            TextFormField(
                controller: _codigoLocalidadeController,
                readOnly: isViewOnly,
                decoration: const InputDecoration(
                    labelText: 'Código da Localidade',
                    border: OutlineInputBorder())),
            TextFormField(
                controller: _categoriaLocalidadeController,
                readOnly: isViewOnly,
                decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder())),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
            controller: _enderecoController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Endereço (Rua, Avenida, etc)',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    controller: _numeroController,
                    readOnly: isViewOnly,
                    decoration: const InputDecoration(
                        labelText: 'Número', border: OutlineInputBorder()))),
            const SizedBox(width: 16),
            Expanded(
                child: TextFormField(
                    controller: _complementoController,
                    readOnly: isViewOnly,
                    decoration: const InputDecoration(
                        labelText: 'Complemento',
                        border: OutlineInputBorder()))),
          ],
        ),
      ],
    );
  }

  Widget _buildHouseholdDetailsSection({required bool isViewOnly}) {
    final paredes = [
      "Alvenaria c/ reboco",
      "Alvenaria s/ reboco",
      "Barro c/ reboco",
      "Barro s/ reboco",
      "Madeira",
      "Taipa",
      "Palha",
      "Outros"
    ];
    final tetos = ["Telha", "Palha", "Madeira", "Metálico", "Outros"];

    return _FormSection(
      children: [
        _buildPendencySection('Pendência da Pesquisa', _pendenciaPesquisa,
            (v) => setState(() => _pendenciaPesquisa = v), isViewOnly),
        const Divider(height: 32),
        _buildPendencySection('Pendência da Borrifação', _pendenciaBorrifacao,
            (v) => setState(() => _pendenciaBorrifacao = v), isViewOnly),
        const Divider(height: 32),
        TextFormField(
            controller: _nomeMoradorController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Nome do Morador', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        _buildFieldLabel(context, 'Número Anexo*'),
        Wrap(
            spacing: 8.0,
            children: List<Widget>.generate(6, (int index) {
              return ChoiceChip(
                  label: Text(index.toString()),
                  selected: _numeroAnexo == index,
                  onSelected: isViewOnly
                      ? null
                      : (bool selected) =>
                          setState(() => _numeroAnexo = selected ? index : null));
            })),
        const Divider(height: 32),
        _buildFieldLabel(context, 'Situação do Imóvel*'),
        ...SituacaoImovel.values.map((s) => RadioListTile<SituacaoImovel>(
            title: Text(formatEnumName(s.name)),
            value: s,
            groupValue: _situacaoImovel,
            onChanged:
                isViewOnly ? null : (v) => setState(() => _situacaoImovel = v))),
        const Divider(height: 32),
        DropdownButtonFormField<String>(
          value: _tipoParede,
          decoration: const InputDecoration(
              labelText: 'Tipo de Parede*', border: OutlineInputBorder()),
          items: paredes
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: isViewOnly ? null : (v) => setState(() => _tipoParede = v),
          validator: (v) => v == null ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoTeto,
          decoration: const InputDecoration(
              labelText: 'Tipo de Teto*', border: OutlineInputBorder()),
          items: tetos
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: isViewOnly ? null : (v) => setState(() => _tipoTeto = v),
          validator: (v) => v == null ? 'Campo obrigatório' : null,
        ),
        const Divider(height: 32),
        _buildFieldLabel(context, 'Melhoria Habitacional*'),
        Row(children: [
          Expanded(
              child: RadioListTile<bool?>(
                  title: const Text('Sim'),
                  value: true,
                  groupValue: _melhoriaHabitacional,
                  onChanged: isViewOnly
                      ? null
                      : (v) => setState(() => _melhoriaHabitacional = v))),
          Expanded(
              child: RadioListTile<bool?>(
                  title: const Text('Não'),
                  value: false,
                  groupValue: _melhoriaHabitacional,
                  onChanged: isViewOnly
                      ? null
                      : (v) => setState(() => _melhoriaHabitacional = v))),
        ]),
      ],
    );
  }

  Widget _buildPendencySection(String title, Pendencia? groupValue,
      ValueChanged<Pendencia?> onChanged, bool isViewOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, title),
        ...Pendencia.values.map((p) => RadioListTile<Pendencia>(
              title: Text(formatEnumName(p.name)),
              value: p,
              groupValue: groupValue,
              onChanged: isViewOnly ? null : onChanged,
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }

  Widget _buildCaptureSection({required bool isViewOnly}) {
    return _FormSection(
      children: [
        _buildCaptureSubSection(
          title: 'Captura Intradomicílio',
          status: _capturaIntraStatus,
          onStatusChanged: (v) {
            setState(() => _capturaIntraStatus = v);
            if (v == CapturaStatus.nenhum) {
              _numBarbeirosIntraController.text = '0';
            }
          },
          vestigios: _vestigiosIntra,
          numController: _numBarbeirosIntraController,
          isViewOnly: isViewOnly,
        ),
        const Divider(height: 32),
        _buildCaptureSubSection(
          title: 'Captura Peridomicílio',
          status: _capturaPeriStatus,
          onStatusChanged: (v) {
            setState(() => _capturaPeriStatus = v);
            if (v == CapturaStatus.nenhum) {
              _numBarbeirosPeriController.text = '0';
            }
          },
          vestigios: _vestigiosPeri,
          numController: _numBarbeirosPeriController,
          isViewOnly: isViewOnly,
        ),
      ],
    );
  }

  Widget _buildCaptureSubSection({
    required String title,
    required CapturaStatus? status,
    required ValueChanged<CapturaStatus?> onStatusChanged,
    required Map<String, bool> vestigios,
    required TextEditingController numController,
    required bool isViewOnly,
  }) {
    final isTriatomineo = status == CapturaStatus.triatomineo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, title),
        ...CapturaStatus.values.map((s) => RadioListTile<CapturaStatus>(
              title: Text(formatEnumName(s.name)),
              value: s,
              groupValue: status,
              onChanged: isViewOnly ? null : onStatusChanged,
            )),
        const SizedBox(height: 16),
        _buildFieldLabel(context, 'Vestígios Encontrados'),
        ...vestigios.keys.map((key) => CheckboxListTile(
              title: Text(key),
              value: vestigios[key],
              onChanged: isViewOnly
                  ? null
                  : (val) => _handleVestigiosChange(vestigios, key, val!),
            )),
        if (isTriatomineo) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: numController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
              labelText: 'Número de Barbeiros Capturados',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (isTriatomineo &&
                  (v == null || v.isEmpty || int.tryParse(v) == 0)) {
                return 'Informe a quantidade';
              }
              return null;
            },
          ),
        ]
      ],
    );
  }

  Widget _buildImageSection({required bool isViewOnly}) {
    final allImages = [
      ..._localImagePaths,
      ..._newlyAddedImages.map((f) => f.path)
    ];
    final canAddMore = allImages.length < 4;

    return _FormSection(
      children: [
        if (allImages.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text('Nenhuma foto adicionada.'),
          )),
        if (allImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final imagePath = allImages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartImage(imageSource: imagePath, fit: BoxFit.cover),
                  ),
                  if (!isViewOnly)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() {
                              if (_newlyAddedImages
                                  .any((x) => x.path == imagePath)) {
                                _newlyAddedImages
                                    .removeWhere((x) => x.path == imagePath);
                              } else {
                                _localImagePaths.remove(imagePath);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (!isViewOnly) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Adicionar Foto'),
              onPressed: canAddMore ? _showImageSourceDialog : null,
            ),
          ),
          if (!canAddMore)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text('Limite de 4 fotos atingido.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSprayingSection({required bool isViewOnly}) {
    return _FormSection(
      children: [
        TextFormField(
          controller: _inseticidaController,
          readOnly: isViewOnly,
          decoration: const InputDecoration(
              labelText: 'Inseticida*', border: OutlineInputBorder()),
          validator: (v) {
            if (_tiposAtividade.contains(TipoAtividade.borrifacao) &&
                (v == null || v.isEmpty)) {
              return 'Obrigatório para borrifação';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFieldLabel(context, "Número de Cargas*"),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(6, (int index) {
            return ChoiceChip(
              label: Text(index.toString()),
              selected: _numCargasController.text == index.toString(),
              onSelected: isViewOnly
                  ? null
                  : (bool selected) => setState(() => _numCargasController
                      .text = selected ? index.toString() : '0'),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLabelCodeSection({required bool isViewOnly}) {
    return _FormSection(
      children: [
        TextFormField(
          controller: _codigoEtiquetaController,
          readOnly: isViewOnly,
          decoration: const InputDecoration(
              labelText: 'Código de Etiqueta',
              border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildAgentSection() {
    return _FormSection(
      children: [
        _buildFieldLabel(context, 'Agente de Combate às Endemias'),
        TextFormField(
          controller: _agenteController,
          readOnly: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              fillColor: Colors.black12,
              filled: true),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateFormat('dd/MM/yyyy').tryParse(_dataAtividadeController.text) ??
              DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dataAtividadeController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
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
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _newlyAddedImages.add(pickedFile);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  Future<void> _getCurrentLocationAndFillAddress() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationUtil.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _enderecoController.text = p.street ?? _enderecoController.text;
            _numeroController.text =
                p.subThoroughfare ?? _numeroController.text;
            _municipioController.text =
                p.subAdministrativeArea ?? _municipioController.text;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço preenchido com a localização.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível obter a localização: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _handleVestigiosChange(
      Map<String, bool> vestigios, String key, bool value) {
    setState(() {
      if (key == 'Nenhum') {
        vestigios.updateAll((_, __) => false);
        vestigios['Nenhum'] = value;
      } else {
        vestigios[key] = value;
        if (value) {
          vestigios['Nenhum'] = false;
        } else if (vestigios.values.every((v) => !v)) {
          vestigios['Nenhum'] = true;
        }
      }
    });
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Text(_isNew ? 'Salvar Registro' : 'Salvar Alterações'),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final List<Widget> children;
  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _FormPanelItem {
  final String key;
  final String header;
  final Widget body;

  _FormPanelItem({required this.key, required this.header, required this.body});
}
