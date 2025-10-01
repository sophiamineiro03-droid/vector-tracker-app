import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class DenunciaScreen extends StatefulWidget {
  const DenunciaScreen({super.key});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _descriptionController = TextEditingController();
  final String _location = "Localização Fictícia: Teresina, PI";
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Registrar Ocorrência'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área da Imagem
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: _image != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.file(_image!, fit: BoxFit.cover),
              )
                  : const Center(
                child: Text('Nenhuma imagem selecionada.'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Selecionar Foto da Galeria'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 24),

            // Campo de Descrição
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Encontrado na parede do quarto, perto da janela.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Localização Simulada
            const Text('Localização (simulada):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_location),
            ),
            const SizedBox(height: 32),

            // Botão de Envio
            ElevatedButton(
              onPressed: () {
                // Lógica de envio da denúncia aqui
                Navigator.of(context).pop(); // Volta para a tela anterior
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Denúncia enviada com sucesso!')),
                );
              },
              child: const Text('Enviar Denúncia'),
            ),
          ],
        ),
      ),
    );
  }
}