import 'package:flutter/material.dart';
import '../components/edition_card.dart';
import '../services/wishlist_service.dart';
import '../services/user_service.dart';
import '../book_details/edition_details_screen.dart';
import '../components/edition_card.dart';
// import '../book_details/edition_details_screen.dart'; // To be implemented in Task 9

/// Expanded Wishlist page.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<WishlistItem>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _loadWishlist();
  }

  Future<List<WishlistItem>> _loadWishlist() async {
    final users = await UserService.fetchUsers();
    if (users != null && users.isNotEmpty) {
      final firstUserId = users.first['id'];
      final items = await WishlistService.getWishlist(firstUserId);
      return items ?? [];
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
        Text('Desejos', style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, double cardExtent) {
    return Expanded(
      child: FutureBuilder<List<WishlistItem>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum livro desejado encontrado.'));
          }

          final items = snapshot.data!;
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: cardExtent, // Altura do EditionCard
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Align(
                alignment: Alignment.topCenter,
                child: EditionCard(
                  title: item.title,
                  author: item.author,
                  coverPhoto: item.coverPhoto,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditionDetailsScreen(editionId: item.editionId),
                      ),
                    ).then((_) {
                      // Recarrega a wishlist ao voltar, caso tenha removido
                      setState(() {
                        _wishlistFuture = _loadWishlist();
                      });
                    });
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
