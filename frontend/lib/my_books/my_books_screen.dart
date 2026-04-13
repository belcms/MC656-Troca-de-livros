import 'package:flutter/material.dart';

import '../services/my_books_service.dart';
import '../services/user_service.dart';
import 'my_book_card.dart';
import 'my_books_model.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  late Future<List<MyBooksModel>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadInitialBooks();
  }

  Future<List<MyBooksModel>> _loadInitialBooks() async {
    // Busca o primeiro usuário do banco como substituto para um ID de sessão autenticado
    final users = await UserService.fetchUsers();
    if (users != null && users.isNotEmpty) {
      final firstUserId = users.first['id'];
      final books = await MyBooksService.fetchUserBooks(firstUserId);
      return books ?? [];
    }
    return [];
  }

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
              'Search',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontFamily: "Inter",
              ),
            ),
          ),
          Icon(Icons.mic_none_rounded, size: 30),
        ],
      ),
    );
  }

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
                child: MyBookCard(
                  title: book.title,
                  publishYear: book.publishYear,
                  photo:
                      book.realPhotoUrl ??
                      'https://via.placeholder.com/300x400',
                  status: book.status,
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit tapped: ${book.title}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

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
      backgroundColor: const Color(0xFFF2ECE2),
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
