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

    // CORREÇÃO: Cria um widget de erro padronizado que SEMPRE tem um tamanho.
    // Isso evita o erro 'RenderBox was not laid out'.
    Widget errorWidget = SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 48.0, // Tamanho fixo para o ícone
          color: Colors.grey[400],
        ),
      ),
    );

    return isNetworkImage
        ? Image.network(
      imageSource,
      width: width,
      height: height,
      fit: fit,
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
      // Usa o widget de erro padronizado.
      errorBuilder: (context, error, stackTrace) => errorWidget,
    )
        : Image.file(
      File(imageSource),
      width: width,
      height: height,
      fit: fit,
      // Usa o widget de erro padronizado também para arquivos locais.
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }
}