import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import 'announcement_detail_model.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends State<AnnouncementDetailScreen> {
  late Future<AnnouncementDetail?> _future;

  @override
  void initState() {
    super.initState();
    _future =
        AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE3D8),
      body: SafeArea(
        child: FutureBuilder<AnnouncementDetail?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // TRATAMENTO DE EXCEÇÃO AQUI
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Ops! Ocorreu um erro:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
                        });
                      },
                      child: const Text('Tentar Novamente'),
                    )
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Nenhum dado encontrado."));
            }

            final data = snapshot.data!;
            final book = data.book;
            final edition = data.edition;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Voltar',
                ),
              
                  _buildCover(data.realPhotoUrl),
                  const SizedBox(height: 16),

                  _buildHeader(
                    title: book?.title,
                    author: book?.author,
                    condition: data.condition,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoSection(
                    tradedWith: data.userName,
                    cep: data.userCep,
                    description: data.description,
                    year: edition?.publishYear,
                    publisher: edition?.publisher,
                  ),

                  const SizedBox(height: 16),

                  _buildDescription(
                    synopsis: book?.synopsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 🎯 SECTIONS
  // =========================

  Widget _buildCover(String? url) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null
            ? Image.network(url, height: 260)
            : Container(
                height: 260,
                width: 160,
                color: Colors.grey[300],
              ),
      ),
    );
  }

  Widget _buildHeader({
  String? title,
  String? author,
  String? condition,
}) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Column(
        children: [
          Text(
            title ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            author ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      if (condition != null)
        Align(
          alignment: Alignment.centerRight,
          child: _buildBadge(condition),
        ),
    ],
  );
}

  Widget _buildInfoSection({
    String? tradedWith,
    String? cep,
    String? description,
    int? year,
    String? publisher,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Trocado por", tradedWith),
        _infoRow("CEP", cep),
        _infoRow("Descrição", description),

        const Divider(height: 24),

        _infoRow("Ano de publicação", year?.toString()),
        _infoRow("Editora", publisher),
      ],
    );
  }

  Widget _buildDescription({
    String? synopsis,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (synopsis != null) _textBlock("Sinopse", synopsis),
      ],
    );
  }

  // =========================
  // 🧩 SMALL BUILDERS
  // =========================

  Widget _infoRow(String label, String? value) {
    if (value == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _textBlock(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}