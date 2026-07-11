import 'package:flutter/material.dart';

import '../my_books/my_books_screen.dart';
import '../my_books/my_books_model.dart';
import '../services/my_books_service.dart';
import '../services/user_service.dart';

import '../book_details/announcement_detail_screen.dart';
import '../book_edition/book_edition_screen.dart';
import '../my_books/my_book_card.dart';

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
  Future<void> _openEditBook(String id) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookEditionPage(id: id),
      ),
    );

    if (updated == true) {
      setState(() {
        _booksFuture = _loadInitialBooks();
      });
    }
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
      child: Text(
        'Perfil',
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
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

        final books = snapshot.data!;

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
                  onEdit: () => _openEditBook(book.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
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
