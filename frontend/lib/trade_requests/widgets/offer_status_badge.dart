import 'package:flutter/material.dart';

import '../models/trade_request.dart';

class OfferStatusBadge extends StatelessWidget {
  const OfferStatusBadge({
    super.key,
    required this.status,
    this.expand = false,
  });

  final OfferStatus status;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);

    final badge = Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: badge) : badge;
  }

  _BadgeStyle _styleFor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return const _BadgeStyle(Color(0xFF416956));
      case OfferStatus.accepted:
        return const _BadgeStyle(Color(0xFF2E7D32));
      case OfferStatus.rejected:
        return const _BadgeStyle(Color(0xFFA7A7A7));
      case OfferStatus.canceled:
        return const _BadgeStyle(Color(0xFF757575));
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.background);

  final Color background;
}
