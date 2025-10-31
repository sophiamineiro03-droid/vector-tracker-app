import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector_tracker_app/services/denuncia_service.dart';
import 'package:vector_tracker_app/util/location_util.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

// --- Enums e Helpers ---

enum TipoAtividade { pesquisa, borrifacao, atendimentoPIT }
enum SituacaoImovel { reconhecida, nova, demolida }
enum Pendencia { semPendencias, fechado, recusa }
enum MelhoriaHabitacional { sim, nao }
enum CapturaStatus { triatomineo, nenhum }

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
    case 'sim': return 'Sim';
    case 'nao': return 'Não';
    case 'triatomineo': return 'Triatomíneo';
    case 'nenhum': return 'Nenhum';
    default: return name;
  }
}

T? _getEnumFromString<T>(List<T> values, String? value) {
  if (value == null) return null;
  try {
    return values.firstWhere((type) => type.toString().split('.').last.toLowerCase() == value.toLowerCase());
  } catch (e) {
    return null;
  }
}

// --- Tela Principal ---

class RegistroOcorrenciaAgenteScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const RegistroOcorrenciaAgenteScreen({super.key, required this.item});

  @override
  _RegistroOcorrenciaAgenteScreenState createState() => _RegistroOcorrenciaAgenteScreenState();
}

class _RegistroOcorrenciaAgenteScreenState extends State<RegistroOcorrenciaAgenteScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isNew, _isOcorrencia, _isDenuncia;
  late bool _isViewMode;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  
  // Listas de imagens
  final List<String> _localImagePaths = []; // Caminhos de arquivos já salvos localmente
  final List<XFile> _newlyAddedImages = []; // Novas imagens adicionadas nesta sessão

  // Variáveis para armazenar a localização obtida
  double? _currentLat;
  double? _currentLng;

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
  final _agenteController = TextEditingController(text: 'Agente Logado');

  TipoAtividade? _tipoAtividade = TipoAtividade.pesquisa;
  bool _realizarBorrifacaoNoPIT = false;
  SituacaoImovel? _situacaoImovel;
  Pendencia? _pendenciaPesquisa, _pendenciaBorrifacao;
  String? _tipoParede, _tipoTeto;
  MelhoriaHabitacional? _melhoriaHabitacional;
  int? _numeroAnexo;
  CapturaStatus? _capturaIntraStatus, _capturaPeriStatus;
  final Map<String, bool> _vestigiosIntra = {'Ovos': false, 'Ninfas': false, 'Exúvias': false, 'Fezes': false, 'Nenhum': false};
  final Map<String, bool> _vestigiosPeri = {'Ovos': false, 'Ninfas': false, 'Exúvias': false, 'Fezes': false, 'Nenhum': false};

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    
    _isOcorrencia = item['is_ocorrencia'] == true;
    _isDenuncia = item.isNotEmpty && !_isOcorrencia;
    _isNew = item.isEmpty;
    _isViewMode = _isOcorrencia; 

    if (_isOcorrencia) {
      _populateFromOcorrencia(item);
    } else if (_isDenuncia) {
      _populateFromDenuncia(item);
    } else {
      _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  void _populateFromOcorrencia(Map<String, dynamic> oco) {
    // Popula a lista de imagens locais já existentes
    if (oco['local_image_paths'] is List) {
      _localImagePaths.addAll(List<String>.from(oco['local_image_paths']));
    }

    if (oco['data_atividade'] != null) {
      try {
        _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(DateTime.parse(oco['data_atividade']));
      } catch (e) {
        try {
           final date = DateFormat('dd/MM/yyyy').parse(oco['data_atividade']);
          _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(date);
        } catch (e2) {
          _dataAtividadeController.text = 'Data inválida';
        }
      }
    } else {
       _dataAtividadeController.text = 'Não informada';
    }

    _currentLat = oco['latitude'];
    _currentLng = oco['longitude'];
    _numeroPITController.text = oco['numero_pit']?.toString() ?? '';
    _municipioController.text = oco['municipio']?.toString() ?? '';
    _codigoLocalidadeController.text = oco['codigo_localidade']?.toString() ?? '';
    _categoriaLocalidadeController.text = oco['categoria_localidade']?.toString() ?? '';
    _localidadeController.text = oco['localidade']?.toString() ?? '';
    _enderecoController.text = oco['endereco']?.toString() ?? '';
    _numeroController.text = oco['numero']?.toString() ?? '';
    _complementoController.text = oco['complemento']?.toString() ?? '';
    _nomeMoradorController.text = oco['nome_morador']?.toString() ?? '';
    _numBarbeirosIntraController.text = oco['num_barbeiros_intra']?.toString() ?? '0';
    _numBarbeirosPeriController.text = oco['num_barbeiros_peri']?.toString() ?? '0';
    _inseticidaController.text = oco['inseticida']?.toString() ?? '';
    _numCargasController.text = oco['num_cargas']?.toString() ?? '0';
    _codigoEtiquetaController.text = oco['codigo_etiqueta']?.toString() ?? '';
    _agenteController.text = oco['agente_responsavel']?.toString() ?? 'Agente não identificado';

    _tipoAtividade = _getEnumFromString(TipoAtividade.values, oco['tipo_atividade']);
    _realizarBorrifacaoNoPIT = oco['realizar_borrifacao_pit'] ?? false;
    _situacaoImovel = _getEnumFromString(SituacaoImovel.values, oco['situacao_imovel']);
    _pendenciaPesquisa = _getEnumFromString(Pendencia.values, oco['pendencia_pesquisa']);
    _pendenciaBorrifacao = _getEnumFromString(Pendencia.values, oco['pendencia_borrifacao']);
    _tipoParede = oco['tipo_parede'];
    _tipoTeto = oco['tipo_teto'];
    _melhoriaHabitacional = _getEnumFromString(MelhoriaHabitacional.values, oco['melhoria_habitacional']);
    _numeroAnexo = oco['numero_anexo'] is int ? oco['numero_anexo'] : int.tryParse(oco['numero_anexo'].toString());
    _capturaIntraStatus = _getEnumFromString(CapturaStatus.values, oco['captura_intra_status']);
    _capturaPeriStatus = _getEnumFromString(CapturaStatus.values, oco['captura_peri_status']);

    if (oco['vestigios_intra'] is Map) {
        final vestigios = Map<String, dynamic>.from(oco['vestigios_intra']);
        vestigios.forEach((key, value) {
            if (_vestigiosIntra.containsKey(key) && value is bool) _vestigiosIntra[key] = value;
        });
    }
    if (oco['vestigios_peri'] is Map) {
        final vestigios = Map<String, dynamic>.from(oco['vestigios_peri']);
        vestigios.forEach((key, value) {
            if (_vestigiosPeri.containsKey(key) && value is bool) _vestigiosPeri[key] = value;
        });
    }
  }

  void _populateFromDenuncia(Map<String, dynamic> den) {
    _tipoAtividade = TipoAtividade.atendimentoPIT;
    _dataAtividadeController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _numeroPITController.text = den['id']?.toString() ?? '';
    _municipioController.text = den['cidade'] ?? '';
    _localidadeController.text = den['bairro'] ?? '';
    _enderecoController.text = den['rua'] ?? '';
    _numeroController.text = den['numero']?.toString() ?? '';
    _complementoController.text = den['complemento'] ?? '';
    _currentLat = den['latitude'];
    _currentLng = den['longitude'];
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço preenchido com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }


  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      String isoDate;
      try {
        final date = DateFormat('dd/MM/yyyy').parse(_dataAtividadeController.text);
        isoDate = date.toIso8601String();
      } catch (e) {
        isoDate = DateTime.now().toIso8601String();
      }

      double? finalLat = _currentLat;
      double? finalLng = _currentLng;

      if (finalLat == null || finalLng == null) {
        final fullAddress = '${_enderecoController.text}, ${_numeroController.text}, ${_localidadeController.text}, ${_municipioController.text}, Brasil';
        try {
          final locations = await locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            finalLat = locations.first.latitude;
            finalLng = locations.first.longitude;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro de geocoding no salvamento: $e');
          }
        }
      }

      // Combina as imagens locais antigas (que não foram removidas) com as novas
      final allLocalImagePaths = [
        ..._localImagePaths,
        ..._newlyAddedImages.map((p) => p.path)
      ];
      
      final dataFromForm = {
        'image_paths': _newlyAddedImages.map((p) => p.path).toList(), // Para o sync service saber o que enviar
        'local_image_paths': allLocalImagePaths, // Para a UI exibir localmente
        'tipo_atividade': _tipoAtividade?.name,
        'realizar_borrifacao_pit': _realizarBorrifacaoNoPIT,
        'data_atividade': isoDate,
        'numero_pit': _numeroPITController.text,
        'municipio': _municipioController.text,
        'codigo_localidade': _codigoLocalidadeController.text,
        'categoria_localidade': _categoriaLocalidadeController.text,
        'localidade': _localidadeController.text,
        'endereco': _enderecoController.text,
        'numero': _numeroController.text,
        'complemento': _complementoController.text,
        'pendencia_pesquisa': _pendenciaPesquisa?.name,
        'pendencia_borrifacao': _pendenciaBorrifacao?.name,
        'nome_morador': _nomeMoradorController.text,
        'numero_anexo': _numeroAnexo,
        'situacao_imovel': _situacaoImovel?.name,
        'tipo_parede': _tipoParede,
        'tipo_teto': _tipoTeto,
        'melhoria_habitacional': _melhoriaHabitacional?.name,
        'captura_intra_status': _capturaIntraStatus?.name,
        'num_barbeiros_intra': int.tryParse(_numBarbeirosIntraController.text.isEmpty ? '0' : _numBarbeirosIntraController.text),
        'vestigios_intra': _vestigiosIntra,
        'captura_peri_status': _capturaPeriStatus?.name,
        'num_barbeiros_peri': int.tryParse(_numBarbeirosPeriController.text.isEmpty ? '0' : _numBarbeirosPeriController.text),
        'vestigios_peri': _vestigiosPeri,
        'inseticida': _inseticidaController.text,
        'num_cargas': int.tryParse(_numCargasController.text.isEmpty ? '0' : _numCargasController.text),
        'codigo_etiqueta': _codigoEtiquetaController.text,
        'agente_responsavel': _agenteController.text,
        'latitude': finalLat,
        'longitude': finalLng,
      };

      try {
        final denunciaService = Provider.of<DenunciaService>(context, listen: false);
        
        final updatedOcorrencia = await denunciaService.saveOcorrencia(
          dataFromForm: dataFromForm,
          originalItem: widget.item,
        );

        if (mounted) {
          final msg = _isNew ? 'Ocorrência salva com sucesso!' : 'Alterações salvas com sucesso!';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
          Navigator.of(context).pop(updatedOcorrencia); // RETORNA O OBJETO ATUALIZADO
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if(mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  _pickMultiImage();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pickSingleImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMultiImage() async {
    final picker = ImagePicker();
    try {
      final pickedFiles = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1024);
      setState(() {
        _newlyAddedImages.addAll(pickedFiles);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagens: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickSingleImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null) {
        setState(() {
          _newlyAddedImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _handleVestigiosChange(Map<String, bool> vestigios, String key, bool value) {
    setState(() {
      if (key == 'Nenhum' && value) {
        vestigios.updateAll((k, v) => false);
        vestigios['Nenhum'] = true;
      } else if (key != 'Nenhum' && value) {
        vestigios[key] = true;
        vestigios['Nenhum'] = false;
      } else {
        vestigios[key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showSprayingSection = _tipoAtividade == TipoAtividade.borrifacao || (_tipoAtividade == TipoAtividade.atendimentoPIT && _realizarBorrifacaoNoPIT);
    final hasOriginalDenunciaContext = widget.item['original_denuncia_context'] != null;

    return Scaffold(
      appBar: GradientAppBar(title: _isNew ? 'Nova Ocorrência' : (_isViewMode ? 'Detalhes da Visita' : 'Editar Visita')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isOcorrencia || (_isNew && !_isDenuncia)) _buildPhotosSection(),

              if (_isDenuncia || hasOriginalDenunciaContext) _buildVisitDetailsHeader(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('1. Dados da Atividade'),
              _buildActivitySection(isViewOnly: _isViewMode),
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
              onPressed: () {
                setState(() {
                  _isViewMode = false;
                });
              },
              label: const Text('Editar'),
              icon: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)));

  Widget _buildPhotosSection() {
    final imageUrls = List<String>.from(widget.item['image_urls'] ?? []);
    final allImages = [...imageUrls, ..._localImagePaths, ..._newlyAddedImages.map((p) => p.path)];

    if (_isViewMode && allImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle("Fotos da Visita do Agente"),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final imageSource = allImages[index];
                final isNewlyAdded = _newlyAddedImages.any((img) => img.path == imageSource);
                final isLocalPath = _localImagePaths.contains(imageSource);
                
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SmartImage(imageSource: imageSource),
                    ),
                    if (!_isViewMode && (isLocalPath || isNewlyAdded))
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const CircleAvatar(
                            radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 16)),
                        onPressed: () {
                          setState(() {
                            if (isNewlyAdded) {
                              _newlyAddedImages.removeWhere((img) => img.path == imageSource);
                            } else {
                              _localImagePaths.remove(imageSource);
                            }
                          });
                        },
                      ),
                  ],
                );
              },
            ),
            if (!_isViewMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Adicionar Fotos'),
                onPressed: _showImageSourceDialog,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDetailsHeader() {
    final contextData = widget.item['original_denuncia_context'] ?? widget.item;

    final imagePath = contextData['image_path'] as String?;
    final imageUrl = contextData['image_url'] as String?;
    final imageSource = imagePath ?? imageUrl;

    final descricao = contextData['descricao'] ?? 'Nenhuma descrição fornecida.';
    final endereco = [
      contextData['rua'], 
      contextData['numero'], 
      contextData['bairro']
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contexto da Denúncia Original'),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: imageSource != null
                    ? SmartImage(imageSource: imageSource)
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Localização Informada:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endereco.isEmpty ? "Endereço não fornecido" : endereco))]),
            const Divider(height: 24),
            const Text('Descrição do Morador:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(descricao, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection({required bool isViewOnly}) {
    bool isBasedOnDenuncia = _isDenuncia || widget.item['denuncia_id_origem'] != null;
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
                icon: _isGettingLocation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: const Text('Usar Minha Localização'),
                onPressed: _isGettingLocation ? null : _getCurrentLocationAndFillAddress,
              ),
            ),
          TextFormField(controller: _municipioController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Município', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _codigoLocalidadeController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Código da Localidade', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _categoriaLocalidadeController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Categoria da Localidade', border: OutlineInputBorder())),
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
    final paredes = ["Alvenaria c/ reboco", "Alvenaria s/ reboco", "Barro c/ reboco", "Barro s/ reboco", "Madeira", "Taipa", "Palha", "Outros"];
    final tetos = ["Telha", "Palha", "Madeira", "Metálico", "Outros"];
    return Card(
        elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (showSprayingPendency) ...[
            const Text('Pendência da Borrifação', style: TextStyle(fontWeight: FontWeight.bold)),
            ...Pendencia.values.where((p) => p != Pendencia.recusa).map((p) => RadioListTile<Pendencia>(
                  title: Text(formatEnumName(p.name)),
                  value: p,
                  groupValue: _pendenciaBorrifacao,
                  onChanged: isViewOnly ? null : (v) => setState(() => _pendenciaBorrifacao = v),
                )),
          ] else ...[
            const Text('Pendência da Pesquisa', style: TextStyle(fontWeight: FontWeight.bold)),
            ...Pendencia.values.map((p) => RadioListTile<Pendencia>(
                  title: Text(formatEnumName(p.name)),
                  value: p,
                  groupValue: _pendenciaPesquisa,
                  onChanged: isViewOnly ? null : (v) => setState(() => _pendenciaPesquisa = v),
                )),
          ],
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
          DropdownButtonFormField<String>(value: _tipoParede, decoration: const InputDecoration(labelText: 'Tipo de Parede', border: OutlineInputBorder()), items: paredes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _tipoParede = v), validator: (v) => v == null ? 'Campo obrigatório' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _tipoTeto, decoration: const InputDecoration(labelText: 'Tipo de Teto', border: OutlineInputBorder()), items: tetos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _tipoTeto = v), validator: (v) => v == null ? 'Campo obrigatório' : null),
          const Divider(height: 24),
          const Text('Melhoria Habitacional', style: TextStyle(fontWeight: FontWeight.bold)),
          ...MelhoriaHabitacional.values.map((m) => RadioListTile<MelhoriaHabitacional>(title: Text(formatEnumName(m.name)), value: m, groupValue: _melhoriaHabitacional, onChanged: isViewOnly ? null : (v) => setState(() => _melhoriaHabitacional = v))),
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
          Column(children: [
            RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(CapturaStatus.triatomineo.name)), value: CapturaStatus.triatomineo, groupValue: _capturaIntraStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaIntraStatus = v)),
            RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(CapturaStatus.nenhum.name)), value: CapturaStatus.nenhum, groupValue: _capturaIntraStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaIntraStatus = v)),
          ]),
          AbsorbPointer(absorbing: isViewOnly || intraDisabled, child: Opacity(opacity: isViewOnly || intraDisabled ? 0.5 : 1.0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _numBarbeirosIntraController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Nº de Barbeiros Capturados'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            const Text('Vestígios Encontrados:'),
            ..._vestigiosIntra.keys.map((key) => CheckboxListTile(title: Text(key), value: _vestigiosIntra[key], onChanged: isViewOnly ? null : (value) => _handleVestigiosChange(_vestigiosIntra, key, value!)))
          ]))),
          const Divider(height: 24),
          const Text('Captura Peridomicílio', style: TextStyle(fontWeight: FontWeight.bold)),
          Column(children: [
            RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(CapturaStatus.triatomineo.name)), value: CapturaStatus.triatomineo, groupValue: _capturaPeriStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaPeriStatus = v)),
            RadioListTile<CapturaStatus>(contentPadding: EdgeInsets.zero, title: Text(formatEnumName(CapturaStatus.nenhum.name)), value: CapturaStatus.nenhum, groupValue: _capturaPeriStatus, onChanged: isViewOnly ? null : (v) => setState(() => _capturaPeriStatus = v)),
          ]),
          AbsorbPointer(absorbing: isViewOnly || periDisabled, child: Opacity(opacity: isViewOnly || periDisabled ? 0.5 : 1.0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _numBarbeirosPeriController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Nº de Barbeiros Capturados'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            const Text('Vestígios Encontrados:'),
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
          DropdownButtonFormField<String>(value: _inseticidaController.text.isEmpty ? null : _inseticidaController.text, decoration: const InputDecoration(labelText: 'Inseticida', border: OutlineInputBorder()), items: inseticidas.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: isViewOnly ? null : (v) => setState(() => _inseticidaController.text = v!), validator: (v) => (_tipoAtividade == TipoAtividade.borrifacao && v == null) ? 'Campo obrigatório' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _numCargasController, readOnly: isViewOnly, decoration: const InputDecoration(labelText: 'Número de Cargas', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => (_tipoAtividade == TipoAtividade.borrifacao && (v == null || v.isEmpty)) ? 'Campo obrigatório' : null),
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
}
