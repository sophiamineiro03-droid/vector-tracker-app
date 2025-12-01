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
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/screens/image_viewer_screen.dart'; // Para o Zoom funcionar

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
class _RegistroOcorrenciaAgenteScreenState extends State<RegistroOcorrenciaAgenteScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late bool _isNew;
  late bool _isViewMode;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  bool _waitingForGPS = false; // Controla se estamos esperando o usuário voltar do GPS
  // Variáveis para controle da mensagem de localização
  String? _locationMessage;
  Color _locationMessageColor = Colors.black;
  String? _openPanelKey = 'atividade';
  final List<String> _localImagePaths = [];
  final List<XFile> _newlyAddedImages = [];
  double? _currentLat;
  double? _currentLng;

  bool _isLoading = true;
  List<LocalidadeSimples> _localidadesAgente = [];
  String? _selectedLocalidadeId;
  // --- Adicione estas linhas ---
  Denuncia? _denunciaContexto;
  bool _isLoadingContexto = false;
// Keys for scrolling to invalid fields
  final _municipioKey = GlobalKey();
  final _dataAtividadeKey = GlobalKey();
  final _numeroPITKey = GlobalKey();
  final _localidadeKey = GlobalKey();
  final _tipoParedeKey = GlobalKey();
  final _tipoTetoKey = GlobalKey();
  final _inseticidaKey = GlobalKey();
  final _numBarbeirosIntraKey = GlobalKey();
  final _numBarbeirosPeriKey = GlobalKey();

  final _panelKeys = {
    'atividade': GlobalKey(),
    'domicilio': GlobalKey(),
    'detalhes_domicilio': GlobalKey(),
    'captura': GlobalKey(),
    'borrifacao': GlobalKey(),
  };
  final _dataAtividadeController = TextEditingController();
  final _numeroPITController = TextEditingController();
  final _municipioController = TextEditingController();
  final _nomeLocalidadeController = TextEditingController();
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
    super.initState();WidgetsBinding.instance.addObserver(this);
    _isNew = widget.ocorrencia == null;
    _isViewMode = widget.isViewOnly;
    _initializeFormData();
  }

  // --- Substitua o seu método _initializeFormData que está quebrado por este ---
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
      // Lógica do Passo 4: Se a ocorrência tem um ID de denúncia, busca o contexto.
      if (widget.ocorrencia!.denuncia_id != null) {
        _fetchDenunciaContexto(widget.ocorrencia!.denuncia_id!);
      }
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

// --- O novo método vem logo depois ---
  Future<void> _fetchDenunciaContexto(String denunciaId) async {
    setState(() => _isLoadingContexto = true);
    try {
      final denunciaService = context.read<DenunciaService>();// 1. Tenta pegar da lista já carregada na memória (que vem do cache)
      final cachedDenuncia = denunciaService.items.firstWhere(
            (d) => d['id'] == denunciaId,
        orElse: () => {},
      );

      if (cachedDenuncia.isNotEmpty) {
        if (mounted) {
          setState(() {
            _denunciaContexto = Denuncia.fromMap(cachedDenuncia);
          });
        }
      } else {
        // 2. Se não achar na memória, tenta buscar do banco (fallback online)
        final response = await Supabase.instance.client
            .from('denuncias')
            .select('*, municipios!cidade(nome)')
            .eq('id', denunciaId)
            .single();

        if (response != null && mounted) {
          setState(() {
            _denunciaContexto = Denuncia.fromMap(response);
          });
        }
      }
    } catch (e) {
      // Silencioso ou log leve, pois se não carregar o contexto, o form ainda funciona
      if (kDebugMode) print("Erro ao buscar contexto da denúncia: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingContexto = false);
      }
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
    // 1. IMAGENS
    if (oco.fotos_urls != null) {
      _localImagePaths.addAll(oco.fotos_urls!);
    }
    if (oco.localImagePaths != null) {
      _localImagePaths.addAll(oco.localImagePaths!);
    }

    // 2. DADOS BÁSICOS
    _dataAtividadeController.text = oco.data_atividade != null
        ? DateFormat('dd/MM/yyyy').format(oco.data_atividade!)
        : '';
    _currentLat = oco.latitude;
    _currentLng = oco.longitude;
    _numeroPITController.text = oco.numero_pit ?? '';

    if (oco.municipioNome != null && oco.municipioNome!.isNotEmpty) {
      _municipioController.text = oco.municipioNome!;
    } else if (oco.municipio_id_ui != null && oco.municipio_id_ui!.isNotEmpty) {
      _municipioController.text = oco.municipio_id_ui!;
    }

    if (oco.localidade_id != null) {
      _selectedLocalidadeId = oco.localidade_id;
    }

    // ATUALIZAÇÃO: Lê o nome da localidade do campo correto
    _nomeLocalidadeController.text = oco.nome_localidade ?? '';
    _codigoLocalidadeController.text = oco.codigo_localidade ?? '';
    _categoriaLocalidadeController.text = oco.categoria_localidade ?? '';

    _enderecoController.text = oco.endereco ?? '';
    _numeroController.text = oco.numero ?? '';
    _complementoController.text = oco.complemento ?? '';
    _nomeMoradorController.text = oco.nome_morador ?? '';

    // 3. ATIVIDADES
    _tiposAtividade.clear();
    if (oco.tipo_atividade != null) {
      _tiposAtividade.addAll(oco.tipo_atividade!);
    }
    if (oco.pendencia_pesquisa != null) {
      _tiposAtividade.add(TipoAtividade.pesquisa);
    }
    if (oco.numero_pit != null && oco.numero_pit!.isNotEmpty) {
      _tiposAtividade.add(TipoAtividade.atendimentoPIT);
    }
    if ((oco.inseticida != null && oco.inseticida!.isNotEmpty) || (oco.numero_cargas ?? 0) > 0) {
      _tiposAtividade.add(TipoAtividade.borrifacao);
    }

    // 4. BORRIFAÇÃO
    _inseticidaController.text = oco.inseticida ?? '';
    _numCargasController.text = oco.numero_cargas?.toString() ?? '0';
    _codigoEtiquetaController.text = oco.codigo_etiqueta ?? '';

    // 5. DETALHES
    _situacaoImovel = oco.situacao_imovel;
    _pendenciaPesquisa = oco.pendencia_pesquisa;
    _pendenciaBorrifacao = oco.pendencia_borrifacao;
    _tipoParede = oco.tipo_parede;
    _tipoTeto = oco.tipo_teto;
    _melhoriaHabitacional = oco.melhoria_habitacional;
    _numeroAnexo = oco.numero_anexo;

    // 6. CAPTURA
    _numBarbeirosIntraController.text = oco.barbeiros_intradomicilio?.toString() ?? '0';
    if (oco.vestigios_intradomicilio != null) {
      _restoreVestigios(oco.vestigios_intradomicilio!, _vestigiosIntra);
    }
    if ((oco.barbeiros_intradomicilio ?? 0) > 0) {
      _capturaIntraStatus = CapturaStatus.triatomineo;
    } else {
      _capturaIntraStatus = CapturaStatus.nenhum;
    }

    _numBarbeirosPeriController.text = oco.barbeiros_peridomicilio?.toString() ?? '0';
    if (oco.vestigios_peridomicilio != null) {
      _restoreVestigios(oco.vestigios_peridomicilio!, _vestigiosPeri);
    }
    if ((oco.barbeiros_peridomicilio ?? 0) > 0) {
      _capturaPeriStatus = CapturaStatus.triatomineo;
    } else {
      _capturaPeriStatus = CapturaStatus.nenhum;
    }
  }
  void _restoreVestigios(String savedString, Map<String, bool> map) {
    map.updateAll((key, val) => false);
    if (savedString == 'Nenhum' || savedString.isEmpty) {
      if (map.containsKey('Nenhum')) map['Nenhum'] = true;
    } else {
      if (map.containsKey('Nenhum')) map['Nenhum'] = false;
      final parts = savedString.split(', ');
      for (var p in parts) {
        if (map.containsKey(p)) {
          map[p] = true;
        }
      }
    }
  }
  void _populateFromDenuncia(Denuncia den) {
    _tiposAtividade.clear();
    _tiposAtividade.add(TipoAtividade.pesquisa);

    _dataAtividadeController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    // CORREÇÃO: Usa o NOME do município.
    if (den.municipioNome != null && den.municipioNome!.isNotEmpty) {
      _municipioController.text = den.municipioNome!;
    }

    // Limpa campos manuais
    _selectedLocalidadeId = null;
    _nomeLocalidadeController.clear();
    _codigoLocalidadeController.clear();
    _categoriaLocalidadeController.clear();

    _enderecoController.text = den.rua ?? '';
    _numeroController.text = den.numero ?? '';
    _complementoController.text = den.complemento ?? '';
    _currentLat = den.latitude;
    _currentLng = den.longitude;

    if (den.foto_url != null && den.foto_url!.isNotEmpty) {
      _localImagePaths.add(den.foto_url!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGPS) {
      _waitingForGPS = false;
      _getCurrentLocationAndFillAddress();
    }
  }
  Future<void> _saveForm() async {
    if (_isViewMode) return;

    if (!_formKey.currentState!.validate()) {
      final errorFieldKey = _findFirstErrorFieldKey();
      if (errorFieldKey != null) {
        final panelKey = _findPanelForField(errorFieldKey);
        setState(() { _openPanelKey = panelKey; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = errorFieldKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, alignment: 0.3);
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, corrija os erros em vermelho.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    final agentRepo = context.read<AgenteRepository>();
    final currentAgent = await agentRepo.getCurrentAgent();
    final agentOcorrenciaService = context.read<AgentOcorrenciaService>();

    final dataAtividade = DateFormat('dd/MM/yyyy').tryParse(_dataAtividadeController.text) ?? DateTime.now();

    // CRIAÇÃO DO OBJETO PARA SALVAR (Agora usando os campos corretos)
    final ocorrenciaToSave = Ocorrencia(
      id: widget.ocorrencia?.id ?? const Uuid().v4(),
      agente_id: currentAgent?.id,
      denuncia_id: widget.ocorrencia?.denuncia_id ?? widget.denunciaOrigem?.id,
      localidade_id: null, // NULO (Pois é manual)
      tipo_atividade: _tiposAtividade.toList(),
      data_atividade: dataAtividade,
      numero_pit: _numeroPITController.text,

      nome_localidade: _nomeLocalidadeController.text, // << SALVA AQUI AGORA
      codigo_localidade: _codigoLocalidadeController.text,
      categoria_localidade: _categoriaLocalidadeController.text,

      endereco: _enderecoController.text, // << ENDEREÇO LIMPO (Sem concatenação)
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
      created_at: widget.ocorrencia?.created_at ?? DateTime.now(),
      fotos_urls: _localImagePaths,
      localImagePaths: _newlyAddedImages.map((f) => f.path).toList(),
      sincronizado: false,
      municipio_id_ui: _municipioController.text,
      setor_id_ui: widget.ocorrencia?.setor_id_ui,
    );

    try {
      await agentOcorrenciaService.saveOcorrencia(ocorrenciaToSave);

      if (ocorrenciaToSave.denuncia_id != null) {
        final denunciaService = context.read<DenunciaService>();
        await denunciaService.updateDenunciaStatus(ocorrenciaToSave.denuncia_id!, 'atendida');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isNew ? 'Ocorrência salva com sucesso!' : 'Alterações salvas!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  GlobalKey? _findFirstErrorFieldKey() {
    // A validação do Form já foi executada, então aqui só verificamos a condição
    // de cada campo na ordem em que aparecem na tela para encontrar o primeiro erro.
    if ((_municipioController.text.isEmpty)) return _municipioKey;
    if ((_dataAtividadeController.text.isEmpty)) return _dataAtividadeKey;
    if (_tiposAtividade.contains(TipoAtividade.atendimentoPIT) && _numeroPITController.text.isEmpty) return _numeroPITKey;

    if (_tipoParede == null) return _tipoParedeKey;
    if (_tipoTeto == null) return _tipoTetoKey;
    if (_tiposAtividade.contains(TipoAtividade.borrifacao) && _inseticidaController.text.isEmpty) return _inseticidaKey;
    if (_capturaIntraStatus == CapturaStatus.triatomineo && (int.tryParse(_numBarbeirosIntraController.text) ?? 0) == 0) return _numBarbeirosIntraKey;
    if (_capturaPeriStatus == CapturaStatus.triatomineo && (int.tryParse(_numBarbeirosPeriController.text) ?? 0) == 0) return _numBarbeirosPeriKey;

    return null;
  }

  String? _findPanelForField(GlobalKey fieldKey) {
    // Mapeia a chave de um campo para a chave do painel que o contém.
    if (fieldKey == _dataAtividadeKey || fieldKey == _numeroPITKey) {
      return 'atividade';
    }
    if (fieldKey == _localidadeKey) {
      return 'domicilio';
    }
    if (fieldKey == _tipoParedeKey || fieldKey == _tipoTetoKey) {
      return 'detalhes_domicilio';
    }
    if (fieldKey == _numBarbeirosIntraKey || fieldKey == _numBarbeirosPeriKey) {
      return 'captura';
    }
    if (fieldKey == _inseticidaKey) {
      return 'borrifacao';
    }
    // Se não estiver em um painel (como o campo município), retorna o painel aberto no momento.
    return _openPanelKey;
  }
  //====================== ATÉ AQUI ======================
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
                      // Se estiver ATENDENDO uma nova denúncia, mostra o card
                      if (widget.denunciaOrigem != null) ...[
                        _buildDenunciaContextCard(widget.denunciaOrigem!),
                        const SizedBox(height: 24),
                      ]
// Se estiver EDITANDO e o contexto já foi carregado, mostra o card
                      else if (_denunciaContexto != null) ...[
                        _buildDenunciaContextCard(_denunciaContexto!),
                        const SizedBox(height: 24),
                      ]
// Se estiver carregando o contexto, mostra um indicador
                      else if (_isLoadingContexto) ...[
                          const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              )),
                          const SizedBox(height: 24),
                        ],
                      TextFormField(
                        key: _municipioKey, // <<<<<<<<<<< ADICIONE ESTA LINHA
                        controller: _municipioController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Município',
                          //...
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
                      const SizedBox(height: 80), // <--- ADICIONE ESTA LINHA PARA DAR ESPAÇO EXTRA
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

  // --- Substitua o método inteiro por esta versão atualizada ---
  Widget _buildDenunciaContextCard(Denuncia denuncia) {
    final theme = Theme.of(context);
    String endereco = '${denuncia.rua ?? ''}, ${denuncia.numero ?? ''} - ${denuncia.bairro ?? ''}';

    return Card(
      elevation: 4,
      color: Colors.blueGrey[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contexto da Denúncia',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            if (denuncia.foto_url != null && denuncia.foto_url!.isNotEmpty) ...[
              GestureDetector( // Adicionado clique para zoom
                onTap: () {
                  Navigator.push(
                    context,
                    // CORREÇÃO AQUI: Usando .single para funcionar com a nova galeria
                    MaterialPageRoute(builder: (context) => ImageViewerScreen.single(imageUrl: denuncia.foto_url!)),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Hero( // Adicionado Hero para animação bonita
                    tag: denuncia.foto_url!,
                    child: SmartImage(
                      imageSource: denuncia.foto_url!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(context, Icons.description, 'Descrição', denuncia.descricao ?? 'Nenhuma descrição informada'),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.location_on, 'Endereço', endereco),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.home_work, 'Complemento', denuncia.complemento ?? 'Não informado'),
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
    final isViewOnly = _isViewMode;final List<_FormPanelItem> panelItems = [
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
          body: _buildImageSection(isViewOnly: isViewOnly)), // <<<<<< CORREÇÃO AQUI
      _FormPanelItem(
          key: 'agente',
          header: '8. Agente Responsável',
          body: _buildAgentSection()),
    ];

    // A mudança está aqui: Usamos `ExpansionPanelList` em vez de `ExpansionPanelList.radio`
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          // Se um painel for expandido, seu 'key' é guardado. Se for fechado, a 'key' é limpa.
          // Isso garante que apenas um painel fique aberto por vez.
          _openPanelKey = isExpanded ? panelItems[index].key : null;
        });
      },
      children: panelItems.map<ExpansionPanel>((item) {
        return ExpansionPanel(
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
          // Esta é a linha mais importante: ela diz qual painel deve estar expandido
          // baseado na variável `_openPanelKey` que mudamos no `_saveForm`.
          isExpanded: _openPanelKey == item.key,
          canTapOnHeader: true,
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
            label: const Text('Obter Localização'), // Mudado o texto
            onPressed:
            _isGettingLocation ? null : _getCurrentLocationAndFillAddress,
          ),

          // AVISO DE LOCALIZAÇÃO NOVO
          if (_locationMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _locationMessageColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _locationMessageColor.withOpacity(0.5)),
              ),
              child: Text(
                _locationMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _locationMessageColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],

        // Nome da Localidade
        TextFormField(
            controller: _nomeLocalidadeController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Nome da Localidade',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),

        // Código da Localidade
        TextFormField(
            controller: _codigoLocalidadeController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Código da Localidade',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),

        // Categoria
        TextFormField(
            controller: _categoriaLocalidadeController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),

        // Endereço
        TextFormField(
            controller: _enderecoController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Endereço (Rua, Avenida, etc)',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),

        // Número e Complemento
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

  Widget _buildImageSection({required bool isViewOnly}) {    final allImages = [
    ..._localImagePaths,
    ..._newlyAddedImages.map((f) => f.path)
  ];
  final canAddMore = allImages.length < 4;

  return _FormSection(
    children: [
      if (allImages.isEmpty && isViewOnly)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('Nenhuma foto registrada.'),
        ),

      // LISTA HORIZONTAL (CARROSSEL)
      SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allImages.length + (isViewOnly || !canAddMore ? 0 : 1),
          itemBuilder: (context, index) {

            // BOTÃO DE ADICIONAR
            if (index == allImages.length && !isViewOnly) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 2), // Borda sólida
                ),
                child: InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Adicionar', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            // FOTO DA LISTA
            final imagePath = allImages[index];
            return Stack(
              children: [
                Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      // === MUDANÇA AQUI: MANDA A LISTA TODA PRA GALERIA ===
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            imageUrls: allImages, // Manda todas as fotos
                            initialIndex: index,  // Abre na que clicou
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: imagePath,
                        child: SmartImage(imageSource: imagePath, fit: BoxFit.cover, height: 160, width: 140),
                      ),
                    ),
                  ),
                ),

                if (!isViewOnly)
                  Positioned(
                    top: 4,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_newlyAddedImages.any((x) => x.path == imagePath)) {
                            _newlyAddedImages.removeWhere((x) => x.path == imagePath);
                          } else {
                            _localImagePaths.remove(imagePath);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      if (!isViewOnly && canAddMore)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('${allImages.length}/4 fotos', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('GPS Desativado'),
          content: const Text('A localização é necessária. Por favor, ative o GPS.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.pop(context);
              },
              child: const Text('Ativar GPS'),
            ),
          ],
        ),
      );
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    setState(() {
      _isGettingLocation = true;
      _locationMessage = 'Obtendo GPS...';
      _locationMessageColor = Colors.grey;
    });

    try {
      final position = await LocationUtil.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });

        List<Placemark> placemarks = [];
        try {
          placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        } catch (e) {
          // Ignora erro de geocoding (offline)
        }

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _enderecoController.text = p.street ?? _enderecoController.text;
            _numeroController.text = p.subThoroughfare ?? _numeroController.text;
            // REMOVIDA a atualização do município para não sobrescrever o fixo

            _locationMessage = 'Localização e Endereço atualizados! Por favor, confira o número.';
            _locationMessageColor = Colors.green;
          });
        } else {
          setState(() {
            // Mensagem amigável OFFLINE
            _locationMessage = 'Coordenadas GPS capturadas! Não foi possível carregar os dados do endereço sem internet. Por favor, preencha.';
            _locationMessageColor = Colors.orange.shade800;
          });
        }
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Erro ao obter GPS: $e';
        _locationMessageColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
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