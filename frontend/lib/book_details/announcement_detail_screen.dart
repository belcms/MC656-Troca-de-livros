import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import 'announcement_detail_model.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<AnnouncementDetail?> _future;

  @override
  void initState() {
    super.initState();
    _future = AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro')),
      body: FutureBuilder<AnnouncementDetail?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Não foi possível carregar os detalhes.'));
          }

          final detail = snapshot.data!;
          final book = detail.book;
          final edition = detail.edition;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((detail.realPhotoUrl ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    detail.realPhotoUrl!,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(book?.title ?? '-', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Autor: ${book?.author ?? '-'}'),
              Text('Sinopse: ${book?.synopsis ?? '-'}'),
              const Divider(height: 24),
              Text('Descrição: ${detail.description ?? '-'}'),
              Text('Condição: ${detail.condition ?? '-'}'),
              Text('Status: ${detail.status ?? '-'}'),
              const Divider(height: 24),
              Text('Editora: ${edition?.publisher ?? '-'}'),
              Text('Ano de publicação: ${edition?.publishYear?.toString() ?? '-'}'),
            ],
          );
        },
      ),
    );
  }
}