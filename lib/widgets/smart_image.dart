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

    Widget errorWidget = SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 40.0, // Tamanho ajustado
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
      // --- A CORREÇÃO ESTÁ AQUI ---
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        // Garante que o indicador de loading tenha um tamanho fixo,
        // evitando o erro de layout no ListTile.
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0, // Deixa o círculo mais fino
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => errorWidget,
    )
        : Image.file(
      File(imageSource),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }
}