import 'dart:io';
import 'package:flutter/material.dart';

class SmartImage extends StatelessWidget {
  final String? imageSource;
  final BoxFit? fit;

  // CORRIGIDO: Adicionado o parâmetro 'fit' ao construtor.
  const SmartImage({super.key, required this.imageSource, this.fit});

  @override
  Widget build(BuildContext context) {
    final source = imageSource;
    if (source == null || source.isEmpty) {
      // Retorna um placeholder se a fonte da imagem for nula ou vazia.
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
      );
    }

    if (source.startsWith('http')) {
      // Se o texto começa com 'http', é uma URL da internet.
      return Image.network(
        source,
        // CORRIGIDO: Usa o 'fit' fornecido, ou BoxFit.cover como padrão.
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          return progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
          );
        },
      );
    } else {
      // Caso contrário, é um caminho de arquivo local.
      final file = File(source);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              // CORRIGIDO: Usa o 'fit' fornecido, ou BoxFit.cover como padrão.
              fit: fit ?? BoxFit.cover,
            );
          } else {
            return const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
            );
          }
        },
      );
    }
  }
}
