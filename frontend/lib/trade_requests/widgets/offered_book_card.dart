import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import 'network_image_with_fallback.dart';

class OfferedBookCard extends StatelessWidget {
  const OfferedBookCard({
    super.key,
    required this.book,
  });

  final TradeBook book;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFFF7F7F7),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFD4D4D4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: NetworkImageWithFallback(
                    imageUrl: book.coverUrl,
                    fallbackIcon: Icons.menu_book_rounded,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
              Text(
                '${book.publishYear}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                book.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
