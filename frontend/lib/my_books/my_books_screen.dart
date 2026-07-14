import 'package:flutter/material.dart';
import '../book_details/announcement_detail_screen.dart';

import '../services/my_books_service.dart';
import 'my_book_card.dart';
import 'my_books_model.dart';
import '../book_edition/book_edition_screen.dart';

/// Main page for the My Books feature.
///
/// It loads backend announcements and renders them as cards in a two-column
/// grid, with loading, error and empty states.
class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  /// Future used by [FutureBuilder] to render async states in the grid.
  late Future<List<MyBooksModel>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadInitialBooks();
  }

  /// Loads initial books for the screen.
  ///
  Future<List<MyBooksModel>> _loadInitialBooks() async {
    return await MyBooksService.fetchMyBooks() ?? [];
  }

  /// Builds the top title row with back navigation.
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 4),
        Text('Meus Livros', style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }

  /// Builds the visual search bar placeholder.
  ///
  /// Search behavior is not wired yet in this version.
  Widget _buildSearchBar() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDAD3C8),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pesquisa',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontFamily: "Inter",
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the availability sort/filter caption area.
  ///
  /// Sort action is currently presentation-only.
  Widget _buildSortFilter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Disponibilidade', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 4),
        const Icon(Icons.unfold_more_rounded, size: 28),
      ],
    );
  }

  /// Builds the books grid using [_booksFuture] states.
  Widget _buildGrid(BuildContext context, double cardExtent) {
    return Expanded(
      child: FutureBuilder<List<MyBooksModel>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum livro encontrado.'));
          }

          final books = snapshot.data!;
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: books.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: cardExtent,
            ),
            itemBuilder: (context, index) {
              final book = books[index];
              return Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
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
                    photo:
                        book.coverPhoto ??
                        'https://via.placeholder.com/300x400',
                    status: book.status,
                    location: book.location,
                    
                    onEdit: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookEditionPage(id: book.id),
                        ),
                      );

                      if (updated == true && mounted) {
                        setState(() {
                          _booksFuture = _loadInitialBooks();
                        });
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the bottom call-to-action button.
  ///
  /// The add flow is currently represented by a feedback snackbar.
  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: SizedBox(
        height: 45,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Add book tapped')));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF416956),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Adicionar Livro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Increased the mainAxisExtent to prevent "bottom overflowed by 2.0 pixels" after adding more texts
    final cardMainAxisExtent = screenWidth < 380 ? 375.0 : 385.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 18),
              _buildSortFilter(context),
              const SizedBox(height: 14),
              _buildGrid(context, cardMainAxisExtent),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildAddButton(context),
      ),
    );
  }
}