import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import 'network_image_with_fallback.dart';
import 'offer_status_badge.dart';

class TradeRequestCard extends StatelessWidget {
  const TradeRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  final TradeRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD8D8D8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: SizedBox(
            height: 92,
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 80,
                  child: NetworkImageWithFallback(
                    imageUrl: request.requestedBook.coverUrl,
                    fallbackIcon: Icons.menu_book_rounded,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        request.requestedBook.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.requestedBook.publishYear}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        request.requestedBook.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      OfferStatusBadge(
                        status: request.status,
                        expand: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 34,
                  color: Color(0xFF333333),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
