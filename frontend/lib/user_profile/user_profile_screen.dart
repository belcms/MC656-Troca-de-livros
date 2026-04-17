import 'package:flutter/material.dart';

import '../my_books/my_books_screen.dart';
import '../my_books/my_books_carousel.dart';
import '../my_books/my_books_model.dart';
import '../services/my_books_service.dart';
import '../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<List<MyBooksModel>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadInitialBooks();
  }

  Future<List<MyBooksModel>> _loadInitialBooks() async {
    // Mesma lógica de busca utilizada na tela MyBooksScreen
    final users = await UserService.fetchUsers();
    if (users != null && users.isNotEmpty) {
      final firstUserId = users.first['id'];
      final books = await MyBooksService.fetchUserBooks(firstUserId);
      return books ?? [];
    }
    return [];
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Perfil',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        const Center(
          child: CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(
              'https://s2-ge.glbimg.com/6T3XhKm41eL0LIRR7twlOLzIKYA=/1280x0/filters:format(jpeg)/https://s01.video.glbimg.com/x720/4064848.jpg',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Neymar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
                fontFamily: 'Inter',
              ),
              children: [
                TextSpan(
                  text: 'Sobre mim: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Ancelotti me odeia :c, mas toma ai tentando ser convocado pra copa de 2026. Fé',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyBooksNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyBooksScreen()),
          );
        },
        child: Row(
          children: [
            Text(
              'Meus Livros',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksCarousel() {
    return FutureBuilder<List<MyBooksModel>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 385,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 385,
            child: Center(child: Text('Erro: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 385,
            child: Center(child: Text('Nenhum livro encontrado.')),
          );
        }

        return MyBooksCarousel(books: snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2ECE2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 30),
                _buildProfileInfo(),
                const SizedBox(height: 30),
                _buildMyBooksNavigation(context),
                const SizedBox(height: 16),
                _buildBooksCarousel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
