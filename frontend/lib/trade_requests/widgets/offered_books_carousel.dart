import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import 'offered_book_card.dart';

class OfferedBooksCarousel extends StatelessWidget {
  const OfferedBooksCarousel({
    super.key,
    required this.books,
  });

  final List<TradeBook> books;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Nenhum livro foi oferecido para esta troca.'),
        ),
      );
    }

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => OfferedBookCard(book: books[index]),
      ),
    );
  }
}
