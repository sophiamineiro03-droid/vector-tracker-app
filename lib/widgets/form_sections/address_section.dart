import 'package:flutter/material.dart';

class AddressSection extends StatelessWidget {
  final bool isViewOnly;
  final bool isGettingLocation;
  final VoidCallback onGetLocation;
  final TextEditingController localidadeController;
  final TextEditingController codigoLocalidadeController;
  final TextEditingController categoriaLocalidadeController;
  final TextEditingController enderecoController;
  final TextEditingController numeroController;
  final TextEditingController complementoController;

  const AddressSection({
    super.key,
    required this.isViewOnly,
    required this.isGettingLocation,
    required this.onGetLocation,
    required this.localidadeController,
    required this.codigoLocalidadeController,
    required this.categoriaLocalidadeController,
    required this.enderecoController,
    required this.numeroController,
    required this.complementoController,
  });

  @override
  Widget build(BuildContext context) {
    // Usando um Column para replicar o comportamento do widget _FormSection original
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isViewOnly) ...[
          OutlinedButton.icon(
            icon: isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Usar Minha Localização'),
            onPressed: isGettingLocation ? null : onGetLocation,
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                  controller: localidadeController,
                  readOnly: isViewOnly,
                  decoration: const InputDecoration(
                      labelText: 'Localidade*', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            ),
            TextFormField(
                controller: codigoLocalidadeController,
                readOnly: isViewOnly,
                decoration: const InputDecoration(
                    labelText: 'Código da Localidade',
                    border: OutlineInputBorder())),
            TextFormField(
                controller: categoriaLocalidadeController,
                readOnly: isViewOnly,
                decoration: const InputDecoration(
                    labelText: 'Categoria', border: OutlineInputBorder())),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
            controller: enderecoController,
            readOnly: isViewOnly,
            decoration: const InputDecoration(
                labelText: 'Endereço (Rua, Avenida, etc)',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    controller: numeroController,
                    readOnly: isViewOnly,
                    decoration: const InputDecoration(
                        labelText: 'Número', border: OutlineInputBorder()))),
            const SizedBox(width: 16),
            Expanded(
                child: TextFormField(
                    controller: complementoController,
                    readOnly: isViewOnly,
                    decoration: const InputDecoration(
                        labelText: 'Complemento',
                        border: OutlineInputBorder()))),
          ],
        ),
      ],
    );
  }
}
