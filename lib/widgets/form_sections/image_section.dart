import 'package:flutter/material.dart';
import 'package:vector_tracker_app/widgets/smart_image.dart';

class ImageSection extends StatelessWidget {
  final bool isViewOnly;
  final List<String> allImages;
  final VoidCallback onAddImage;
  final Function(String) onRemoveImage;

  const ImageSection({
    super.key,
    required this.isViewOnly,
    required this.allImages,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = allImages.length < 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allImages.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text('Nenhuma foto adicionada.'),
          )),
        if (allImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final imagePath = allImages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        SmartImage(imageSource: imagePath, fit: BoxFit.cover),
                  ),
                  if (!isViewOnly)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                          onPressed: () => onRemoveImage(imagePath),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (!isViewOnly) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Adicionar Foto'),
              onPressed: canAddMore ? onAddImage : null,
            ),
          ),
          if (!canAddMore)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text('Limite de 4 fotos atingido.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ],
    );
  }
}
