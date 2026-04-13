import 'package:flutter/material.dart';

import 'my_book_card.dart';
import 'my_books_model.dart';

//  Carrosel widget to display user's books in a horizontal scrollable list, used in both MyBooksScreen and UserProfileScreen
class MyBooksCarousel extends StatelessWidget {
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
          return MyBookCard(
            title: book.title,
            publishYear: book.publishYear,
            photo: book.realPhotoUrl ?? 'https://via.placeholder.com/300x400',
            status: book.status,
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit tapped: ${book.title}')),
              );
            },
          );
        },
      ),
    );
  }
}
