import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class VisitManagementScreen extends StatefulWidget {
  final Map<String, dynamic> denuncia;

  const VisitManagementScreen({super.key, required this.denuncia});

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores do Formulário
  String? _statusVisita;
  String? _resultadoVisita;
  bool _amostraColetada = false;
  final _especieController = TextEditingController();
  final _localCapturaController = TextEditingController();
  String? _tipoMoradia;
  final _riscosController = TextEditingController();

  @override
  void dispose() {
    _especieController.dispose();
    _localCapturaController.dispose();
    _riscosController.dispose(); // Limpa o novo controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Gerenciar Visita'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHistoryCard(context),
              const SizedBox(height: 24),
              _buildVisitDataSection(context),
              const SizedBox(height: 24),
              _buildCollectionDataSection(context),
              const SizedBox(height: 24),
              // --- NOVAS SEÇÕES ADICIONADAS ---
              _buildPropertyDataSection(context),
              const SizedBox(height: 24),
              _buildRisksSection(context),
              // Botão Salvar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Salvar Alterações'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Lógica para salvar todos os dados coletados no Supabase
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) { /* ...código mantido... */ return Container(); }

  Widget _buildVisitDataSection(BuildContext context) { /* ...código mantido... */ return Container(); }

  Widget _buildCollectionDataSection(BuildContext context) { /* ...código mantido... */ return Container(); }

  // --- SEÇÃO DE DADOS DO IMÓVEL ---
  Widget _buildPropertyDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Dados do Imóvel'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoMoradia,
          onChanged: (value) => setState(() => _tipoMoradia = value),
          decoration: const InputDecoration(labelText: 'Tipo de Moradia', border: OutlineInputBorder()),
          items: ['Alvenaria', 'Taipa', 'Madeira', 'Mista']
              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
              .toList(),
          validator: (value) => value == null ? 'Selecione o tipo de moradia' : null,
        ),
      ],
    );
  }

  // --- SEÇÃO DE RISCOS ADICIONAIS ---
  Widget _buildRisksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Riscos Sociais e Sanitários'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _riscosController,
          decoration: const InputDecoration(
            labelText: 'Observações (Ex: acúmulo de lixo, animais, etc.)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4, // Campo de texto com múltiplas linhas
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
