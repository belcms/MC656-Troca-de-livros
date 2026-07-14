import 'package:flutter/material.dart';

/// Reusable UI card for an Edition (used in Wishlist and similar places).
///
/// Displays a compact card with a 3:4 cover, title, and author.
class EditionCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverPhoto;
  final VoidCallback? onTap;

  const EditionCard({
    super.key,
    required this.title,
    required this.author,
    this.coverPhoto,
    this.onTap,
  });

  /// Renders the cover image in a fixed 3:4 frame.
  Widget _buildCoverImage() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverPhoto != null && coverPhoto!.isNotEmpty
            ? Image.network(
                coverPhoto!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book, size: 36, color: Colors.grey),
    );
  }

  /// Renders the textual metadata section.
  Widget _buildMetadata(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48, // Fix height so 1line vs 2lines titles take same space
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150, // slightly narrower than my_book_card
      child: Card(
        elevation: 0,
        color: const Color(0xFFF8F8F8), // Design guide color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD9D9D9), width: 1), // Stroke
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        clipBehavior: Clip.antiAlias, // ensure inkwell ripple respects border
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverImage(),
                const SizedBox(height: 10),
                _buildMetadata(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
