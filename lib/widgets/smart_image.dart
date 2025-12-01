import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; 

/// Um widget de imagem inteligente que decide se deve carregar uma imagem da rede, de um arquivo local ou de um asset.
/// Agora suporta cache offline REAL (baixa e salva no disco) com suporte a versionamento (query params).
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
  String? _debugError;

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

    if (!widget.imageSource.startsWith('http')) {
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

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/images_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      // GERA UM NOME ÚNICO BASEADO NA URL COMPLETA (incluindo query params como ?t=123)
      // Isso garante que se a URL mudar, o arquivo de cache muda.
      final urlHash = widget.imageSource.hashCode;
      final uri = Uri.parse(widget.imageSource);
      final extension = uri.pathSegments.last.split('.').last; // Tenta pegar extensão
      // Nome ex: 34829102_nomeoriginal.jpg
      final filename = '${urlHash}_${uri.pathSegments.last}'; 
      
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
      } else {
        _downloadAndCache(widget.imageSource, file);
      }
    } catch (e) {
       // Ignora erro
    }

    if (mounted) {
      setState(() {
        _isLoadingCache = false;
        _cachedFile = null;
      });
    }
  }
  
  Future<void> _downloadAndCache(String url, File targetFile) async {
     try {
       final response = await http.get(Uri.parse(url));
       if (response.statusCode == 200) {
          await targetFile.writeAsBytes(response.bodyBytes);
          // Opcional: Atualizar UI se quiser instantâneo, mas o Image.network cuida do primeiro load
       }
     } catch (e) {
       // Falha silenciosa
     }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageSource.startsWith('assets/')) {
      return Image.asset(
        widget.imageSource,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(error: error),
      );
    }

    if (!widget.imageSource.startsWith('http')) {
       return _buildImageFile(File(widget.imageSource));
    }
    
    if (_cachedFile != null) {
      return _buildImageFile(_cachedFile!);
    }

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
        child: Icon(
          Icons.person,
          size: 40.0,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
