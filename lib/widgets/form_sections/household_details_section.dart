import 'package:flutter/material.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
import 'package:vector_tracker_app/widgets/form_field_label.dart';

class HouseholdDetailsSection extends StatelessWidget {
  final bool isViewOnly;
  final Pendencia? pendenciaPesquisa;
  final ValueChanged<Pendencia?> onPendenciaPesquisaChanged;
  final Pendencia? pendenciaBorrifacao;
  final ValueChanged<Pendencia?> onPendenciaBorrifacaoChanged;
  final TextEditingController nomeMoradorController;
  final int? numeroAnexo;
  final ValueChanged<int?> onNumeroAnexoChanged;
  final SituacaoImovel? situacaoImovel;
  final ValueChanged<SituacaoImovel?> onSituacaoImovelChanged;
  final String? tipoParede;
  final ValueChanged<String?> onTipoParedeChanged;
  final String? tipoTeto;
  final ValueChanged<String?> onTipoTetoChanged;
  final bool? melhoriaHabitacional;
  final ValueChanged<bool?> onMelhoriaHabitacionalChanged;

  const HouseholdDetailsSection({
    super.key,
    required this.isViewOnly,
    required this.pendenciaPesquisa,
    required this.onPendenciaPesquisaChanged,
    required this.pendenciaBorrifacao,
    required this.onPendenciaBorrifacaoChanged,
    required this.nomeMoradorController,
    required this.numeroAnexo,
    required this.onNumeroAnexoChanged,
    required this.situacaoImovel,
    required this.onSituacaoImovelChanged,
    required this.tipoParede,
    required this.onTipoParedeChanged,
    required this.tipoTeto,
    required this.onTipoTetoChanged,
    required this.melhoriaHabitacional,
    required this.onMelhoriaHabitacionalChanged,
  });

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPendencySection('Pendência da Pesquisa', pendenciaPesquisa,
            onPendenciaPesquisaChanged, isViewOnly),
        const Divider(height: 32),
        _buildPendencySection('Pendência da Borrifação', pendenciaBorrifacao,
            onPendenciaBorrifacaoChanged, isViewOnly),
        const Divider(height: 32),
        TextFormField(
            controller: nomeMoradorController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Nome do Morador', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        const FormFieldLabel('Número Anexo*'),
        Wrap(
            spacing: 8.0,
            children: List<Widget>.generate(6, (int index) {
              return ChoiceChip(
                  label: Text(index.toString()),
                  selected: numeroAnexo == index,
                  onSelected: isViewOnly
                      ? null
                      : (bool selected) =>
                          onNumeroAnexoChanged(selected ? index : null));
            })),
        const Divider(height: 32),
        const FormFieldLabel('Situação do Imóvel*'),
        ...SituacaoImovel.values.map((s) => RadioListTile<SituacaoImovel>(
            title: Text(s.displayName),
            value: s,
            groupValue: situacaoImovel,
            onChanged: isViewOnly ? null : onSituacaoImovelChanged)),
        const Divider(height: 32),
        DropdownButtonFormField<String>(
          value: tipoParede,
          decoration: const InputDecoration(
              labelText: 'Tipo de Parede*', border: OutlineInputBorder()),
          items:
              paredes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: isViewOnly ? null : onTipoParedeChanged,
          validator: (v) => v == null ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: tipoTeto,
          decoration: const InputDecoration(
              labelText: 'Tipo de Teto*', border: OutlineInputBorder()),
          items:
              tetos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: isViewOnly ? null : onTipoTetoChanged,
          validator: (v) => v == null ? 'Campo obrigatório' : null,
        ),
        const Divider(height: 32),
        const FormFieldLabel('Melhoria Habitacional*'),
        Row(children: [
          Expanded(
              child: RadioListTile<bool?>(
                  title: const Text('Sim'),
                  value: true,
                  groupValue: melhoriaHabitacional,
                  onChanged: isViewOnly ? null : onMelhoriaHabitacionalChanged)),
          Expanded(
              child: RadioListTile<bool?>(
                  title: const Text('Não'),
                  value: false,
                  groupValue: melhoriaHabitacional,
                  onChanged: isViewOnly ? null : onMelhoriaHabitacionalChanged)),
        ]),
      ],
    );
  }

  Widget _buildPendencySection(String title, Pendencia? groupValue,
      ValueChanged<Pendencia?> onChanged, bool isViewOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(title),
        ...Pendencia.values.map((p) => RadioListTile<Pendencia>(
              title: Text(p.displayName),
              value: p,
              groupValue: groupValue,
              onChanged: isViewOnly ? null : onChanged,
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }
}
