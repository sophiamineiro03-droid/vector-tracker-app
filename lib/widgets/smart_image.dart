import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Um widget de imagem inteligente que decide se deve carregar uma imagem da rede, de um arquivo local ou de um asset.
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
  String? _debugError; // Variável para armazenar erro de debug

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
    // 0. Se for asset, não faz nada de cache
    if (widget.imageSource.startsWith('assets/')) {
      if (mounted) {
        setState(() {
          _isLoadingCache = false;
          _cachedFile = null;
          _debugError = null;
        });
      }
      return;
    }

    // 1. Se for arquivo local
    if (!widget.imageSource.startsWith('http')) {
      // Verifica se o arquivo local existe para debug
      final file = File(widget.imageSource);
      if (!await file.exists()) {
        if (mounted) setState(() => _debugError = "Arquivo não encontrado: ${widget.imageSource}");
      } else {
        if (mounted) setState(() => _debugError = null);
      }

      if (mounted) {
        setState(() {
          _isLoadingCache = false;
          _cachedFile = null;
        });
      }
      return;
    }

    // 2. Se for URL (http), tenta buscar no cache
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/images_cache');
      
      final uri = Uri.parse(widget.imageSource);
      final filename = uri.pathSegments.last; 
      final file = File('${cacheDir.path}/$filename');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoadingCache = false;
            _debugError = null;
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
    // 1. Se for Asset
    if (widget.imageSource.startsWith('assets/')) {
      return Image.asset(
        widget.imageSource,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(error: error),
      );
    }

    // 2. Se for arquivo local direto (caminho string e não começa com http)
    if (!widget.imageSource.startsWith('http')) {
       return _buildImageFile(File(widget.imageSource));
    }
    
    // 3. Se achou no cache (para URLs)
    if (_cachedFile != null) {
      return _buildImageFile(_cachedFile!);
    }

    // 4. Fallback para rede
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
         return _buildErrorWidget(error: error);
      },
    );
  }

  Widget _buildImageFile(File file) {
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(error: error),
    );
  }

  Widget _buildErrorWidget({Object? error}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 30.0,
              color: Colors.grey[400],
            ),
            // EXIBE O ERRO NA TELA PARA DEBUG (apenas se houver espaço)
            if (_debugError != null || error != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _debugError ?? error.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
