import 'package:flutter/material.dart';
import 'package:frontend/book_details/announcement_detail_screen.dart';
import 'announcement_card.dart';
import '../services/announcement_service.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  List<dynamic> announcements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final data = await AnnouncementService.fetchFeedAnnouncements();
    setState(() {
      announcements = data ?? [];
      isLoading = false;
    });
  }

  // final List<Map<String, dynamic>> livros = [
  //   {'title': 'Trono de Vidro', 'year': 2012, 'photo': 'https://m.media-amazon.com/images/I/81m94OedHqL._SL1500_.jpg', 'cep': 'Americana - SP'},
  //   {'title': 'Coroa da Meia-Noite', 'year': 2013, 'photo': 'https://m.media-amazon.com/images/I/814x0T5JlsL._SL1500_.jpg', 'cep': 'Hortolândia - SP'},
  //   {'title': 'Herdeira do Fogo', 'year': 2014, 'photo': 'https://m.media-amazon.com/images/I/81z-fUzRFxL._SL1500_.jpg', 'cep': 'São Paulo - SP'},
  //   {'title': 'Rainha das Sombras', 'year': 2015, 'photo': 'https://m.media-amazon.com/images/I/81bXtL9Ii1L._SL1500_.jpg', 'cep': 'Vinhedo - SP'},
  //   {'title': 'Império de Tempestades', 'year': 2016, 'photo': 'https://m.media-amazon.com/images/I/910tBzUIfwL._SL1500_.jpg', 'cep': 'Campinas - SP'},
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Text(
                'Home',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: announcements.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 1.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.50,
                          ),
                      itemBuilder: (context, index) {
                        final ann = announcements[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetailScreen(
                                  announcementId: ann['id'].toString(),
                                ),
                              ),
                            );
                          },

                          child: AnnouncementCard(
                            title: ann['title'],
                            publishYear: ann['publishYear'],
                            photo: ann['real_photo_url'] ?? '',
                            cep: ann['cep'],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
