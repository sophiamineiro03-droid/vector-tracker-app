import 'package:flutter/material.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/widgets/form_field_label.dart';

class SprayingSection extends StatelessWidget {
  final bool isViewOnly;
  final TextEditingController inseticidaController;
  final TextEditingController numCargasController;
  final ValueChanged<String> onNumCargasChanged;
  final TipoAtividade? tipoAtividade;
  final bool realizarBorrifacaoNoPIT;

  const SprayingSection({
    super.key,
    required this.isViewOnly,
    required this.inseticidaController,
    required this.numCargasController,
    required this.onNumCargasChanged,
    required this.tipoAtividade,
    required this.realizarBorrifacaoNoPIT,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: inseticidaController,
          readOnly: isViewOnly,
          decoration: const InputDecoration(
              labelText: 'Inseticida*', border: OutlineInputBorder()),
          validator: (v) {
            if ((tipoAtividade == TipoAtividade.borrifacao ||
                    realizarBorrifacaoNoPIT) &&
                (v == null || v.isEmpty)) {
              return 'Obrigatório para borrifação';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const FormFieldLabel("Número de Cargas*"),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(6, (int index) {
            return ChoiceChip(
              label: Text(index.toString()),
              selected: numCargasController.text == index.toString(),
              onSelected: isViewOnly
                  ? null
                  : (bool selected) =>
                      onNumCargasChanged(selected ? index.toString() : '0'),
            );
          }),
        ),
      ],
    );
  }
}
