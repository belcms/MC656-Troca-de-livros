import 'package:flutter/material.dart';

/// Visual card used to display an intermediate search result for a post.
class IntermediatePostResultCard extends StatelessWidget {
  /// Creates a new [IntermediatePostResultCard].
  const IntermediatePostResultCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.location,
    required this.photoUrl,
    this.onTap,
  });

  /// Book title shown in the card.
  final String title;

  /// Publication year shown under the title.
  final String publishYear;

  /// Location shown as the secondary metadata line.
  final String location;

  /// Cover image URL.
  final String photoUrl;

  /// Optional tap handler used by the future search screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;
    final detailStyle = theme.textTheme.bodyMedium;

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 160,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return ColoredBox(
                      color: const Color(0xFFECECEC),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFECECEC),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: Color(0xFF727272),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    publishYear,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: detailStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: detailStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
