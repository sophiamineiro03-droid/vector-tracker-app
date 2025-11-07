import 'package:flutter/material.dart';
import 'package:vector_tracker_app/models/ocorrencia_enums.dart';
import 'package:vector_tracker_app/models/ocorrencia_enum_extensions.dart';
import 'package:vector_tracker_app/widgets/form_field_label.dart';

class CaptureSection extends StatelessWidget {
  final bool isViewOnly;

  final CapturaStatus? intraStatus;
  final ValueChanged<CapturaStatus?> onIntraStatusChanged;
  final Map<String, bool> intraVestigios;
  final void Function(String key, bool value) onIntraVestigiosChanged;
  final TextEditingController intraNumController;

  final CapturaStatus? periStatus;
  final ValueChanged<CapturaStatus?> onPeriStatusChanged;
  final Map<String, bool> periVestigios;
  final void Function(String key, bool value) onPeriVestigiosChanged;
  final TextEditingController periNumController;

  const CaptureSection({
    super.key,
    required this.isViewOnly,
    required this.intraStatus,
    required this.onIntraStatusChanged,
    required this.intraVestigios,
    required this.onIntraVestigiosChanged,
    required this.intraNumController,
    required this.periStatus,
    required this.onPeriStatusChanged,
    required this.periVestigios,
    required this.onPeriVestigiosChanged,
    required this.periNumController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCaptureSubSection(
          context: context,
          title: 'Captura Intradomicílio',
          status: intraStatus,
          onStatusChanged: onIntraStatusChanged,
          vestigios: intraVestigios,
          onVestigiosChanged: onIntraVestigiosChanged,
          numController: intraNumController,
          isViewOnly: isViewOnly,
        ),
        const Divider(height: 32),
        _buildCaptureSubSection(
          context: context,
          title: 'Captura Peridomicílio',
          status: periStatus,
          onStatusChanged: onPeriStatusChanged,
          vestigios: periVestigios,
          onVestigiosChanged: onPeriVestigiosChanged,
          numController: periNumController,
          isViewOnly: isViewOnly,
        ),
      ],
    );
  }

  Widget _buildCaptureSubSection({
    required BuildContext context,
    required String title,
    required CapturaStatus? status,
    required ValueChanged<CapturaStatus?> onStatusChanged,
    required Map<String, bool> vestigios,
    required void Function(String, bool) onVestigiosChanged,
    required TextEditingController numController,
    required bool isViewOnly,
  }) {
    final isTriatomineo = status == CapturaStatus.triatomineo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(title),
        ...CapturaStatus.values.map((s) => RadioListTile<CapturaStatus>(
              title: Text(s.displayName),
              value: s,
              groupValue: status,
              onChanged: isViewOnly ? null : onStatusChanged,
            )),
        const SizedBox(height: 16),
        const FormFieldLabel('Vestígios Encontrados'),
        ...vestigios.keys.map((key) => CheckboxListTile(
              title: Text(key),
              value: vestigios[key],
              onChanged: isViewOnly
                  ? null
                  : (val) => onVestigiosChanged(key, val!),
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
}
