import 'package:flutter/material.dart';
import 'package:frontend/components/badge_component.dart';

/// A visual card that displays the summarized information of an announcement
/// in the feed.
///
/// This widget displays the book cover, title, publication year, location (CEP),
/// the physical condition of the book, and,
/// when available, the distance from the current user.
class AnnouncementCard extends StatelessWidget {
  /// Title of the book. It will be automatically truncated if it exceeds
  /// 2 lines.
  final String title;

  /// Publish year of the edition.
  final int publishYear;

  /// The URL to fetch the book's image added by the advertiser.
  final String photo;

  /// The postal code (CEP) or city from the advertiser.
  // final String location;

  /// The physical condition of the book (e.g., Novo, Usado).
  final String condition;

  /// The postal code or formatted location from the advertiser.
  final String cep;

  /// Distance from the current user to the announcement, in kilometers.
  final double? distanceKm;

  /// Creates a new announcement card.
  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    // required this.location,
    required this.condition,
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
      height:
          400, // Aumentado levemente para evitar overflow com os novos itens
      child: Card(
        elevation: 4.0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
              // const SizedBox(height: 2),
              Text(
                '$publishYear',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),

              // Localização com Ícone de Pino
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alinha os itens à esquerda
                children: [
                  // 1. O Ícone e o CEP na mesma linha (Row)
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
                          cep,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w400,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),

                  // 2. O distanceLabel logo abaixo (em Column), se houver
                  if (distanceLabel.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ), // Espaçamento vertical entre o CEP e a distância
                    Text(
                      distanceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF416956),
                      ),
                    ),
                  ],
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
