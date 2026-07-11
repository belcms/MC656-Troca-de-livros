import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import 'network_image_with_fallback.dart';

class RequestExchangeHeader extends StatelessWidget {
  const RequestExchangeHeader({
    super.key,
    required this.request,
  });

  final TradeRequest request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: NetworkImageWithFallback(
                    imageUrl: request.requester.photoUrl,
                    fallbackIcon: Icons.person,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.requester.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  request.requester.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 42),
            child: Icon(Icons.arrow_forward, size: 42),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 82,
                  height: 112,
                  child: NetworkImageWithFallback(
                    imageUrl: request.requestedBook.coverUrl,
                    fallbackIcon: Icons.menu_book_rounded,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.requestedBook.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  '${request.requestedBook.publishYear}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
