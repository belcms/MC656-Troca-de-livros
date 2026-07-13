import 'package:flutter/material.dart';
import '../book_details/announcement_detail_screen.dart';

import 'my_book_card.dart';
import 'my_books_model.dart';
import '../book_edition/book_edition_screen.dart';

/// Horizontal list version of My Books cards.
///
/// This widget is shared by screens that need a compact carousel representation
/// of the user's announcements.
class MyBooksCarousel extends StatelessWidget {
  /// Card data to render.
  final List<MyBooksModel> books;

  const MyBooksCarousel({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Nenhum livro encontrado.')),
      );
    }

    return SizedBox(
      height: 385,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnnouncementDetailScreen(announcementId: book.id),
                ),
              );
            },
            child: MyBookCard(
              title: book.title,
              publishYear: book.publishYear,
              photo: book.realPhotoUrl ?? 'https://via.placeholder.com/300x400',
              status: book.status,
              location: book.location,
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookEditionPage(
                      id: book.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
