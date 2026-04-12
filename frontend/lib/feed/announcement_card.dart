import 'dart:ffi';
import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final int publishYear;
  final String photo;
  final String cep;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    required this.cep
  });

@override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 300,
      child: Card(
        elevation: 4.0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Mantém os textos à esquerda
            children: <Widget>[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    photo,
                    height: 192,
                    width: 144,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                title, 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, 
                ),
              ),
              Text(
                '$publishYear', 
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                cep, 
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
