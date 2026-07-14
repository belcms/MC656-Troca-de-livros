import 'package:flutter/material.dart';
import '../services/edition_service.dart';
import '../services/wishlist_service.dart';
import '../services/user_service.dart';

class EditionDetailsScreen extends StatefulWidget {
  final String editionId;

  const EditionDetailsScreen({super.key, required this.editionId});

  @override
  State<EditionDetailsScreen> createState() => _EditionDetailsScreenState();
}

class _EditionDetailsScreenState extends State<EditionDetailsScreen> {
  late Future<EditionDetailsModel?> _editionFuture;
  bool _isInWishlist = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _editionFuture = _loadData();
  }

  Future<EditionDetailsModel?> _loadData() async {
    final users = await UserService.fetchUsers();
    if (users != null && users.isNotEmpty) {
      _currentUserId = users.first['id'];
      
      // Checa se está na wishlist
      final wishlist = await WishlistService.getWishlist(_currentUserId!);
      if (wishlist != null) {
        setState(() {
          _isInWishlist = wishlist.any((item) => item.editionId == widget.editionId);
        });
      }
    }

    return EditionService.getEditionDetails(widget.editionId);
  }

  Future<void> _toggleWishlist() async {
    if (_currentUserId == null) return;

    if (_isInWishlist) {
      final success = await WishlistService.removeFromWishlist(_currentUserId!, widget.editionId);
      if (success && mounted) {
        setState(() {
          _isInWishlist = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removido dos desejos')),
        );
      }
    } else {
      final success = await WishlistService.addToWishlist(_currentUserId!, widget.editionId);
      if (success && mounted) {
        setState(() {
          _isInWishlist = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicionado aos desejos')),
        );
      }
    }
  }

  Widget _buildCover(String? coverPhoto) {
    return Center(
      child: Container(
        height: 250,
        width: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: const Color(0xFFF1F1F1),
        ),
        clipBehavior: Clip.antiAlias,
        child: coverPhoto != null && coverPhoto.isNotEmpty
            ? Image.network(coverPhoto, fit: BoxFit.cover)
            : const Icon(Icons.menu_book, size: 60, color: Colors.grey),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Livro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<EditionDetailsModel?>(
        future: _editionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Erro ao carregar detalhes da edição.'));
          }

          final edition = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(edition.coverPhoto),
                const SizedBox(height: 24),
                Text(
                  edition.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  edition.author,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 24),
                
                if (edition.genre != null) _buildDetailRow('Gênero', edition.genre!),
                _buildDetailRow('Editora', edition.publisher),
                if (edition.publishYear != null) _buildDetailRow('Ano de Publicação', edition.publishYear.toString()),
                if (edition.pages != null) _buildDetailRow('Número de Páginas', edition.pages.toString()),
                if (edition.language != null) _buildDetailRow('Idioma', edition.language!),
                
                const SizedBox(height: 24),
                const Text(
                  'Sinopse',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 8),
                Text(
                  edition.synopsis ?? 'Sinopse não disponível.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 100), // Espaço para o botão
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _toggleWishlist,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isInWishlist ? Colors.red.shade100 : const Color(0xFF416956),
              foregroundColor: _isInWishlist ? Colors.red.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _isInWishlist ? Colors.red : Colors.transparent),
              ),
              elevation: 0,
            ),
            child: Text(
              _isInWishlist ? 'Remover dos Desejos' : 'Adicionar aos Desejos',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
