import 'package:flutter/material.dart';

import 'my_book_card.dart';

class MyBooksScreen extends StatelessWidget {
  const MyBooksScreen({super.key});

  static final List<Map<String, dynamic>> _dummyBooks = [
    {
      'title':
          'Memórias póstumas de Brás Cubas e esse texto continua para testar o overflow',
      'publish_year': 2012,
      'real_photo_url': 'https://m.media-amazon.com/images/I/71OL9RU2tJL.jpg',
      'status': 'available',
    },
    {
      'title': 'The power of habit',
      'publish_year': 2014,
      'real_photo_url':
          'https://m.media-amazon.com/images/I/71QKQ9mwV7L._UF1000,1000_QL80_.jpg',
      'status': 'available',
    },
    {
      'title': '1984',
      'publish_year': 2009,
      'real_photo_url':
          'https://m.media-amazon.com/images/I/71kxa1-0mfL._UF1000,1000_QL80_.jpg',
      'status': 'reserved',
    },
  ];

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
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: _dummyBooks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          mainAxisExtent: cardExtent,
        ),
        itemBuilder: (context, index) {
          final book = _dummyBooks[index];
          return Align(
            alignment: Alignment.topCenter,
            child: MyBookCard(
              title: book['title'] as String,
              publishYear: book['publish_year'] as int,
              photo: book['real_photo_url'] as String,
              status: book['status'] as String,
              onEdit: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit tapped: ${book['title']}')),
                );
              },
            ),
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
    final cardMainAxisExtent = screenWidth < 380 ? 350.0 : 362.0;

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
