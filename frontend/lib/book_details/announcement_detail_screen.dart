import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Erro ao carregar detalhes.'));
          }

          final data = snapshot.data!;
          final edition = (data['edition'] as Map<String, dynamic>?) ?? {};
          final book = (edition['book'] as Map<String, dynamic>?) ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((book['title'] ?? '-').toString(), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Autor: ${book['author'] ?? '-'}'),
                Text('Sinopse: ${book['synopsis'] ?? '-'}'),
              ],
            ),
          );
        },
      ),
    );
  }
}