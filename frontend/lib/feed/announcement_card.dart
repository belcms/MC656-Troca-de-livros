import 'dart:ffi';
import 'package:flutter/material.dart';

/// A visual card that displays the summarized information of an announcement in the feed.
///
/// This widget displays the book cover, title, publication year, and the
/// advertiser's ZIP code (CEP).
class AnnouncementCard extends StatelessWidget {
  /// Title of the book. It will be automatically truncated if it exceeds 2 lines.
  final String title;

  /// Publish Year of the Edition.
  final int publishYear;

  /// The URL to fetch the book's image added by the advertiser.
  final String photo;

  /// The postal code (CEP) from the advertiser.
  final String cep;

  /// Creates a new announcement card.
  ///
  /// The parameters [title], [publishYear], [photo], and [cep] are required.
  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    required this.cep,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 330,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: AspectRatio(aspectRatio: 3/4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    photo,
                    height: 190,
                    width: 144,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1F1F1),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                        ),
                      );
                    },
                  ),
                ),
                )
              ),

              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
