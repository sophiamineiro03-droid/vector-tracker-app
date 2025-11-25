import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Um widget de imagem inteligente que decide se deve carregar uma imagem da rede ou de um arquivo local.
/// Agora suporta cache offline (lê de local se existir).
class SmartImage extends StatefulWidget {
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
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  File? _cachedFile;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }
  
  @override
  void didUpdateWidget(SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageSource != widget.imageSource) {
      _checkCache();
    }
  }

  Future<void> _checkCache() async {
    if (!widget.imageSource.startsWith('http')) {
      if (mounted) {
        setState(() {
          _isLoadingCache = false;
          _cachedFile = null;
        });
      }
      return;
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/images_cache');
      
      // Estratégia simples de nome de arquivo: último segmento da URL
      final uri = Uri.parse(widget.imageSource);
      final filename = uri.pathSegments.last; 
      final file = File('${cacheDir.path}/$filename');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoadingCache = false;
          });
        }
        return;
      }
    } catch (e) {
      // Ignora erro de cache
    }

    if (mounted) {
      setState(() {
        _isLoadingCache = false;
        _cachedFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Se for arquivo local direto (caminho string)
    if (!widget.imageSource.startsWith('http')) {
       return _buildImageFile(File(widget.imageSource));
    }
    
    // 2. Se achou no cache
    if (_cachedFile != null) {
      return _buildImageFile(_cachedFile!);
    }

    // 3. Fallback para rede
    return Image.network(
      widget.imageSource,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
         return _buildErrorWidget();
      },
    );
  }

  Widget _buildImageFile(File file) {
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 40.0,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
