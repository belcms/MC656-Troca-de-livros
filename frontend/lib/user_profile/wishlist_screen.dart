import 'package:flutter/material.dart';
import '../components/edition_card.dart';
// import '../book_details/edition_details_screen.dart'; // To be implemented in Task 9

/// Expanded Wishlist page.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Dados mockados temporariamente
  final List<Map<String, String>> mockWishlist = [
    {
      'title': 'O Senhor dos Anéis', 
      'author': 'J.R.R. Tolkien', 
      'photo': 'https://m.media-amazon.com/images/I/71ZWs4hjVLL._AC_UF1000,1000_QL80_.jpg'
    },
    {
      'title': '1984', 
      'author': 'George Orwell', 
      'photo': 'https://m.media-amazon.com/images/I/71kXa1qcBPL._AC_UF1000,1000_QL80_.jpg'
    },
    {
      'title': 'O Pequeno Príncipe', 
      'author': 'Antoine de Saint-Exupéry', 
      'photo': 'https://m.media-amazon.com/images/I/81B4W1hZc0L._AC_UF1000,1000_QL80_.jpg'
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
        Text('Desejos', style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, double cardExtent) {
    if (mockWishlist.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nenhum livro desejado encontrado.')),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: mockWishlist.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          mainAxisExtent: cardExtent, // Altura do EditionCard
        ),
        itemBuilder: (context, index) {
          final item = mockWishlist[index];
          return Align(
            alignment: Alignment.topCenter,
            child: EditionCard(
              title: item['title']!,
              author: item['author']!,
              coverPhoto: item['photo'],
              onTap: () {
                // TODO: Navegar para detalhes da edição
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrir detalhes da edição')),
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
            // Ação não implementada ainda
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Adicionar para desejos')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF416956),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Adicionar para desejos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // EditionCard tem aproximadamente 280~290 de altura
    final cardMainAxisExtent = 290.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
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
