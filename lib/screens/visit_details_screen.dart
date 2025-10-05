import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vector_tracker_app/main.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

// Enumerações para tipagem forte
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
  late Future<int> _historyCountFuture;
  bool _isSaving = false;
  XFile? _agentPhoto;

  // Variáveis do formulário
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
    _historyCountFuture = _fetchHistoryCount();
  }

  Future<int> _fetchHistoryCount() async {
    final lat = widget.denuncia['latitude'];
    final lon = widget.denuncia['longitude'];
    if (lat == null || lon == null) return 0;
    try {
      final count = await supabase.from('denuncias').count(CountOption.exact).eq('latitude', lat).eq('longitude', lon);
      return count > 0 ? count - 1 : 0;
    } catch (e) {
      debugPrint("Error fetching history: $e");
      return 0;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1024);
      if (pickedFile != null) {
        setState(() => _agentPhoto = pickedFile);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao usar a câmera: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveVisit() async {
    if (_statusVisita == null || _resultadoInspecao == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status da Visita e Resultado são obrigatórios.'), backgroundColor: Colors.orange));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? agentPhotoUrl;
      if (_agentPhoto != null) {
        final photoFile = File(_agentPhoto!.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        // CORRIGIDO: Apontando para o bucket correto 'imagens_denuncias'
        await supabase.storage.from('imagens_denuncias').upload(fileName, photoFile);
        agentPhotoUrl = supabase.storage.from('imagens_denuncias').getPublicUrl(fileName);
      }

      final updateData = {
        'status': _statusVisita?.name,
        'visit_result': _resultadoInspecao?.name,
        'sample_collected': _amostraColetada,
        'species_suspicion': _especieSuspeita,
        'capture_location': _localCaptura?.name,
        'vector_quantity': int.tryParse(_quantidadeController.text),
        'dwelling_type': _tipoMoradia,
        'social_risks': _riscosSociaisController.text,
        'sanitary_risks': _riscosSanitariosController.text,
        'observations': _observacoesController.text,
        'visited_at': DateTime.now().toIso8601String(),
        'agent_image_url': agentPhotoUrl,
      };

      await supabase.from('denuncias').update(updateData).eq('id', widget.denuncia['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visita salva com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $error'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _riscosSociaisController.dispose();
    _riscosSanitariosController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Prancheta da Visita'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildDenunciaContextCard(context),
            const SizedBox(height: 16),
            _buildImovelHistoryCard(context),
            const SizedBox(height: 24),
            _buildVisitFormSection(context),
            const SizedBox(height: 24),
            _buildDomicilioSection(context),
            const SizedBox(height: 24),
            _buildDocumentationAndRisksSection(context),
            const SizedBox(height: 32),
            _buildFinalizationSection(context),
          ]),
        ),
      ),
    );
  }

  String _buildAddress() {
    final parts = [widget.denuncia['rua'], widget.denuncia['numero'], widget.denuncia['bairro'], widget.denuncia['cidade'], widget.denuncia['estado']]
        .where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    return parts.isEmpty ? "Endereço não fornecido" : parts;
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));

  Widget _buildDenunciaContextCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = widget.denuncia['image_url'] as String?;
    final descricao = widget.denuncia['descricao'] as String? ?? 'Nenhuma descrição fornecida.';
    final endereco = _buildAddress();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contexto da Denúncia', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (imageUrl != null)
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)))
          else
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200], image: const DecorationImage(image: AssetImage('assets/barbeiro.jpg'), fit: BoxFit.cover))),
          const SizedBox(height: 16),
          const Text('Localização:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endereco, style: const TextStyle(fontSize: 14)))]),
          const Divider(height: 24),
          const Text('Descrição do Morador:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(descricao, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ]),
      ),
    );
  }

  Widget _buildImovelHistoryCard(BuildContext context) {
    return FutureBuilder<int>(
      future: _historyCountFuture,
      builder: (context, snapshot) {
        String message = 'Buscando histórico...';
        IconData icon = Icons.hourglass_empty;
        Color color = Colors.grey;
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            message = 'Erro ao buscar histórico.';
            icon = Icons.error_outline;
            color = Colors.red;
          } else if (snapshot.hasData && snapshot.data! > 0) {
            final count = snapshot.data!;
            message = 'Atenção: $count outra(s) ocorrência(s) neste imóvel.';
            icon = Icons.history_rounded;
            color = Theme.of(context).colorScheme.primary;
          } else {
            message = 'Primeira ocorrência registrada neste local.';
            icon = Icons.new_releases_outlined;
            color = Colors.green;
          }
        }
        return Card(
          color: color.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.4))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 16),
              Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildVisitFormSection(BuildContext context) {
    final bool denunciaConfirmada = _resultadoInspecao == ResultadoInspecao.confirmada;
    String statusName(StatusVisita s) => {StatusVisita.realizada: 'Visita Realizada', StatusVisita.fechado: 'Imóvel Fechado', StatusVisita.recusada: 'Visita Recusada'}[s]!;
    String resultadoName(ResultadoInspecao r) => {ResultadoInspecao.confirmada: 'Denúncia Confirmada (vetor encontrado)', ResultadoInspecao.descartada: 'Denúncia Descartada (não era o vetor)', ResultadoInspecao.naoAvaliavel: 'Não Avaliável'}[r]!;
    String localName(LocalCaptura l) => {LocalCaptura.intradomicilio: 'Dentro de casa (Intradomicílio)', LocalCaptura.peridomicilio: 'No quintal/terreno (Peridomicílio)'}[l]!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Formulário da Visita'),
            const SizedBox(height: 16),
            const Text('1. Status da Visita', style: TextStyle(fontWeight: FontWeight.bold)),
            ...StatusVisita.values.map((s) => RadioListTile<StatusVisita>(title: Text(statusName(s)), value: s, groupValue: _statusVisita, onChanged: (v) => setState(() => _statusVisita = v))),
            const Divider(height: 24),
            const Text('2. Resultado da Inspeção', style: TextStyle(fontWeight: FontWeight.bold)),
            ...ResultadoInspecao.values.map((r) => RadioListTile<ResultadoInspecao>(title: Text(resultadoName(r)), value: r, groupValue: _resultadoInspecao, onChanged: (v) => setState(() => _resultadoInspecao = v))),
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
                ...LocalCaptura.values.map((l) => RadioListTile<LocalCaptura>(title: Text(localName(l)), value: l, groupValue: _localCaptura, onChanged: (v) => setState(() => _localCaptura = v))),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDomicilioSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Características do Domicílio'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(validator: (v) => v == null ? 'Campo obrigatório' : null, value: _tipoMoradia, decoration: const InputDecoration(labelText: 'Tipo de Moradia', border: OutlineInputBorder()), items: ['Alvenaria', 'Taipa', 'Madeira', 'Outro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _tipoMoradia = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentationAndRisksSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        ]),
      ),
    );
  }

  Widget _buildAgentPhotoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto do Agente:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_agentPhoto == null)
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Adicionar Foto'),
            onPressed: _pickImage,
          )
        else
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_agentPhoto!.path), height: 200, width: double.infinity, fit: BoxFit.cover)),
              IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)), onPressed: () => setState(() => _agentPhoto = null)),
            ],
          ),
      ],
    );
  }

  Widget _buildFinalizationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveVisit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
          child: _isSaving
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Salvar e Finalizar Visita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
