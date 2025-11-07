import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/form_field_label.dart';

class AgentSection extends StatelessWidget {
  final TextEditingController controller;

  const AgentSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormFieldLabel('Agente de Combate às Endemias'),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              fillColor: Colors.black12,
              filled: true),
        ),
      ],
    );
  }
}
