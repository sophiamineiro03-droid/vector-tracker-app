import 'package:flutter/material.dart';

class LabelCodeSection extends StatelessWidget {
  final bool isViewOnly;
  final TextEditingController controller;

  const LabelCodeSection({
    super.key,
    required this.isViewOnly,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: isViewOnly,
          decoration: const InputDecoration(
              labelText: 'Código de Etiqueta',
              border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
