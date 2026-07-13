import 'package:flutter/material.dart';
import 'package:frontend/components/badge_component.dart';

/// A visual card that displays the summarized information of an announcement in the feed.
///
/// This widget displays the book cover, title, publication year, location (CEP),
/// and the physical condition of the book.
class AnnouncementCard extends StatelessWidget {
  /// Title of the book. It will be automatically truncated if it exceeds 2 lines.
  final String title;

  /// Publish Year of the Edition.
  final int publishYear;

  /// The URL to fetch the book's image added by the advertiser.
  final String photo;

  /// The postal code (CEP) or city from the advertiser.
  final String location;

  /// The physical condition of the book (e.g., Novo, Usado).
  final String condition;

  /// Creates a new announcement card.
  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    required this.location,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height:
          360, // Aumentado levemente para evitar overflow com os novos itens
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
              Center(child: _buildCoverImage()),
              const SizedBox(height: 10),

              // Título
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              // Ano
              Text(
                '$publishYear',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),

              // Localização com Ícone de Pino
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(), // Empurra a tag de condição lá pro final do card
              // Tag de Condição
              buildBadge(condition, context),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the cover image in a fixed 3:4 frame.
  Widget _buildCoverImage() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photo,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF1F1F1),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  // /// Maps backend condition values to a visual colored tag
  // Widget _buildConditionChip(BuildContext context) {
  //   Color bgColor;
  //   String label;

  //   switch (condition.toLowerCase()) {
  //     case 'new':
  //       // case 'novo':
  //       bgColor = const Color(0xFF24523C);
  //       label = 'Novo';
  //       break;
  //     case 'used':
  //       // case 'muito bom':
  //       bgColor = const Color(0xFF416956);
  //       label = 'Muito bom';
  //       break;
  //     case 'good':
  //       // case 'bom':
  //       bgColor = const Color(0xFFDB8F44);
  //       label = 'Bom';
  //       break;
  //     case 'worn':
  //       // case 'desgastado':
  //       bgColor = const Color(0xFF7B2518);
  //       label = 'Desgastado';
  //       break;
  //     default:
  //       bgColor = Theme.of(context).colorScheme.primary;
  //       label = condition.isNotEmpty ? condition : 'Novo';
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: bgColor,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       label,
  //       style: const TextStyle(
  //         color: Colors.white,
  //         fontSize: 11,
  //         fontWeight: FontWeight.w700,
  //       ),
  //     ),
  //   );
  // }
}
