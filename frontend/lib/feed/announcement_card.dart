import 'package:flutter/material.dart';

/// A visual card that displays the summarized information of an announcement
/// in the feed.
///
/// This widget displays the book cover, title, publication year, location and,
/// when available, the distance from the current user.
class AnnouncementCard extends StatelessWidget {
  /// Title of the book. It will be automatically truncated if it exceeds
  /// 2 lines.
  final String title;

  /// Publish year of the edition.
  final int publishYear;

  /// The URL to fetch the book's image added by the advertiser.
  final String photo;

  /// The postal code or formatted location from the advertiser.
  final String cep;

  /// Distance from the current user to the announcement, in kilometers.
  final double? distanceKm;

  /// Creates a new announcement card.
  ///
  /// The parameters [title], [publishYear], [photo], and [cep] are required.
  /// The [distanceKm] parameter is optional because the backend may not be
  /// able to calculate distance for all announcements.
  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    required this.cep,
    this.distanceKm,
  });

  String get _distanceLabel {
    final distance = distanceKm;

    if (distance == null) {
      return '';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m de você';
    }

    return '${distance.toStringAsFixed(1)} km de você';
  }

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _distanceLabel;

    return SizedBox(
      width: 180,
      height: 330,
      child: Card(
        elevation: 4.0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    8.0,
                  ),
                  child: Image.network(
                    photo,
                    height: 190,
                    width: 144,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.broken_image,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '$publishYear',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              Text(
                cep,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              if (distanceLabel.isNotEmpty)
                Text(
                  distanceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF416956),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}