import 'package:flutter/material.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
import 'package:vector_tracker_app/widgets/form_field_label.dart';

class ActivitySection extends StatelessWidget {
  final bool isViewOnly;
  final TipoAtividade? tipoAtividade;
  final ValueChanged<TipoAtividade?> onTipoAtividadeChanged;
  final TextEditingController dataAtividadeController;
  final TextEditingController numeroPITController;
  final VoidCallback onSelectDate;

  const ActivitySection({
    super.key,
    required this.isViewOnly,
    required this.tipoAtividade,
    required this.onTipoAtividadeChanged,
    required this.dataAtividadeController,
    required this.numeroPITController,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormFieldLabel('Tipo de Atividade*'),
        ...TipoAtividade.values.map((tipo) => RadioListTile<TipoAtividade>(
            title: Text(tipo.displayName),
            value: tipo,
            groupValue: tipoAtividade,
            onChanged: isViewOnly ? null : onTipoAtividadeChanged)),
        const SizedBox(height: 16),
        TextFormField(
          controller: dataAtividadeController,
          decoration: const InputDecoration(
              labelText: 'Data da Atividade*',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: isViewOnly ? null : onSelectDate,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
        if (tipoAtividade == TipoAtividade.atendimentoPIT) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: numeroPITController,
            readOnly: isViewOnly,
            decoration: InputDecoration(
              labelText: 'Número do PIT*',
              border: const OutlineInputBorder(),
              fillColor: isViewOnly ? Colors.black12 : null,
              filled: isViewOnly,
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (tipoAtividade == TipoAtividade.atendimentoPIT &&
                        (v == null || v.isEmpty))
                    ? 'Campo obrigatório'
                    : null,
          ),
        ],
      ],
    );
  }
}
