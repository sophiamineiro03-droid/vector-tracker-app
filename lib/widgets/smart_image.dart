import 'dart:io';
import 'package:flutter/material.dart';

/// Um widget de imagem inteligente que decide se deve carregar uma imagem da rede ou de um arquivo local.
///
/// Ele verifica se a `imageSource` começa com 'http' para carregar da rede,
/// caso contrário, trata como um caminho de arquivo local.
class SmartImage extends StatelessWidget {
  final String imageSource;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    required this.imageSource,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imageSource.startsWith('http');

    return isNetworkImage
        ? Image.network(
      imageSource,
      width: width,
      height: height,
      fit: fit,
      // Adiciona um indicador de carregamento para imagens da rede.
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      // Mostra um ícone de erro se a imagem da rede falhar ao carregar.
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image,
        size: width != null ? width! * 0.5 : 48.0,
        color: Colors.grey,
      ),
    )
        : Image.file(
      File(imageSource),
      width: width,
      height: height,
      fit: fit,
      // Mostra um ícone de erro se o arquivo local não for encontrado.
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image,
        size: width != null ? width! * 0.5 : 48.0,
        color: Colors.grey,
      ),
    );
  }
}
