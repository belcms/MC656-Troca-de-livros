import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Necessário para o XFile

class PhotoCarouselPicker extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAddImage;
  final Function(int index) onRemoveImage;

  const PhotoCarouselPicker({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Fotos do Livro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: [
                  // Renderiza as fotos usando a lista recebida por parâmetro
                  ...List.generate(images.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.file(
                              File(images[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: -10,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(index), // Chama a função do pai
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Botão de adicionar
                  if (images.length < 5)
                    GestureDetector(
                      onTap: onAddImage, // Chama a função do pai
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Contador
          Text(
            '${images.length}/5',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}