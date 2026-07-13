import 'package:flutter/material.dart';
import 'package:frontend/book_details/announcement_detail_screen.dart';
import 'package:frontend/search/intermediate_search_screen.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';
import 'announcement_card.dart';
import '../services/announcement_service.dart';

/// The main screen of the application that displays the feed of book announcements.
///
/// This widget handles its own state to fetch data asynchronously via
/// [AnnouncementService.fetchFeedAnnouncements] when it initializes.
/// Depending on the data state, it will render a loading indicator,
/// an [EmptyFeedState] if no books are found, or a grid of [AnnouncementCard]s.
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

  /// Fetches the feed data from the backend and updates the UI state.
  Future<void> _loadFeed() async {
    final data = await AnnouncementService.fetchFeedAnnouncements();
    setState(() {
      announcements = data ?? [];
      isLoading = false;
    });
  }

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CustomSearchBar(
                readOnly: true,
                hintText: 'Buscar livros, autores ou editoras',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntermediateSearchScreen(),
                    ),
                  );
                },
                onChanged: (_) {},
                onSubmitted: (_) {},
                onClear: () {},
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : announcements.isEmpty
                  ? const EmptyFeedState()
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
                            photo: ann['cover_photo']?.toString() ?? '',
                            // photo: ann['real_photo_url'] ?? '',
                            location: ann['cep'],
                            condition: ann['condition'] ?? '',
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

/// A visual placeholder displayed when the feed has no announcements.
///
/// This widget shows a book icon and a friendly message encouraging the
/// user to take the first step and create a book trade announcement.
class EmptyFeedState extends StatelessWidget {
  const EmptyFeedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 80.0, color: Colors.grey),
            const SizedBox(height: 24.0),
            Text(
              "O feed está vazio!",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12.0),
            Text(
              "Que tal dar o primeiro passo e anunciar aquele livro que está parado na estante?",
              textAlign: .center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
