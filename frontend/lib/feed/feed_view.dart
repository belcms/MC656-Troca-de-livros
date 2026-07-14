import 'package:flutter/material.dart';
import 'package:frontend/book_details/announcement_detail_screen.dart';

import '../services/announcement_service.dart';
import 'announcement_card.dart';
import 'announcement_filter_sheet.dart';
import 'announcement_filters.dart';

import 'package:frontend/search/intermediate_search_screen.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';

import '../services/announcement_service.dart';
import 'announcement_card.dart';

/// The main screen of the application that displays the feed of book
/// announcements.
///
/// This widget handles its own state to fetch data asynchronously via
/// [AnnouncementService.fetchFeedAnnouncements] when it initializes.
/// Depending on the data state, it will render a loading indicator,
/// an [EmptyFeedState] if no books are found, or a grid of
/// [AnnouncementCard]s.
class FeedView extends StatefulWidget {
  const FeedView({
    super.key,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  List<dynamic> announcements = [];
  bool isLoading = true;
  static const currentUserId = String.fromEnvironment(
    'CURRENT_USER_ID',
  );

  AnnouncementFilters activeFilters =
      const AnnouncementFilters();

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  /// Fetches the feed data from the backend and updates the UI state.
  ///
  /// The backend is responsible for sorting by distance. The frontend only
  /// requests distance sorting and renders the response in the received order.
  Future<void> _loadFeed() async {
    setState(() {
      isLoading = true;
    });

    final data =
        await AnnouncementService.fetchFeedAnnouncements(
      currentUserId: currentUserId,
      filters: activeFilters,
      sortByDistance: true,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      announcements = data ?? [];
      isLoading = false;
    });
  }

  Future<void> _openFilters() async {
    final result =
        await showModalBottomSheet<AnnouncementFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return AnnouncementFilterSheet(
          initialFilters: activeFilters,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      activeFilters = result;
    });

    await _loadFeed();
  }

  Future<void> _clearAllFilters() async {
    setState(() {
      activeFilters = const AnnouncementFilters();
    });

    await _loadFeed();
  }

  Future<void> _removeYearFilter() async {
    setState(() {
      activeFilters = activeFilters.copyWith(
        clearYears: true,
      );
    });

    await _loadFeed();
  }

  Future<void> _removeCondition(
    String condition,
  ) async {
    final updatedConditions = List<String>.from(
      activeFilters.conditions,
    )..remove(condition);

    setState(() {
      activeFilters = activeFilters.copyWith(
        conditions: updatedConditions,
      );
    });

    await _loadFeed();
  }

  Future<void> _removeGenre(
    String genre,
  ) async {
    final updatedGenres = List<String>.from(
      activeFilters.genres,
    )..remove(genre);

    setState(() {
      activeFilters = activeFilters.copyWith(
        genres: updatedGenres,
      );
    });

    await _loadFeed();
  }

  Future<void> _removeDistanceFilter() async {
    setState(() {
      activeFilters = activeFilters.copyWith(
        clearDistance: true,
      );
    });

    await _loadFeed();
  }

  String _conditionLabel(String value) {
    const labels = {
      'New': 'Novo',
      'Good': 'Bom',
      'Used': 'Usado',
      'Worn': 'Desgastado',
    };

    return labels[value] ?? value;
  }

  String _genreLabel(String value) {
    const labels = {
      'Fantasy': 'Fantasia',
      'Romance': 'Romance',
      'Sci_fic': 'Ficção científica',
      'Non_fiction': 'Não ficção',
      'Biography': 'Biografia',
      'Graphic_novel': 'Graphic novel',
      'Horror': 'Terror',
      'Self_help': 'Autoajuda',
      'Thriller': 'Suspense',
      'Education': 'Educação',
    };

    return labels[value] ?? value;
  }

  int _parsePublishYear(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _parseDistanceKm(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Home',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openFilters,
                    tooltip: 'Filtrar livros',
                    icon: Badge(
                      isLabelVisible:
                          activeFilters
                              .hasActiveFilters,
                      child: const Icon(
                        Icons.tune,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (activeFilters.hasActiveFilters)
              _ActiveFiltersSection(
                filters: activeFilters,
                conditionLabel:
                    _conditionLabel,
                genreLabel: _genreLabel,
                onRemoveYear:
                    _removeYearFilter,
                onRemoveCondition:
                    _removeCondition,
                onRemoveGenre:
                    _removeGenre,
                onRemoveDistance:
                    _removeDistanceFilter,
                onClearAll:
                    _clearAllFilters,
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ),
              child: CustomSearchBar(
                readOnly: true,
                hintText: 'Buscar livros, autores ou editoras',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const IntermediateSearchScreen(),
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
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : announcements.isEmpty
                      ? const EmptyFeedState()
                      : RefreshIndicator(
                          onRefresh: _loadFeed,
                          child: GridView.builder(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                announcements.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.50,
                            ),
                            itemBuilder:
                                (context, index) {
                              final ann =
                                  announcements[index] as Map;

                              final announcementId =
                                  ann['id']?.toString() ?? '';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              AnnouncementDetailScreen(
                                        announcementId:
                                            announcementId,
                                      ),
                                    ),
                                  );
                                },
                                child:
                                    AnnouncementCard(
                                  title:
                                      ann['title']?.toString() ??
                                          'Livro sem título',
                                  publishYear:
                                      _parsePublishYear(
                                        ann[
                                            'publishYear'],
                                      ),
                                  photo:
                                      ann['real_photo_url']?.toString() ??
                                          '',
                                  cep: ann['cep']?.toString() ??
                                      'Localização não informada',
                                  distanceKm:
                                      _parseDistanceKm(
                                        ann['distanceKm'],
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFiltersSection extends StatelessWidget {
  final AnnouncementFilters filters;
  final String Function(String) conditionLabel;
  final String Function(String) genreLabel;
  final VoidCallback onRemoveYear;
  final ValueChanged<String> onRemoveCondition;
  final ValueChanged<String> onRemoveGenre;
  final VoidCallback onRemoveDistance;
  final VoidCallback onClearAll;

  const _ActiveFiltersSection({
    required this.filters,
    required this.conditionLabel,
    required this.genreLabel,
    required this.onRemoveYear,
    required this.onRemoveCondition,
    required this.onRemoveGenre,
    required this.onRemoveDistance,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Text(
                  'Filtros ativos',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                if (filters.hasYearFilter)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: InputChip(
                      label: Text(
                        '${filters.startYear}'
                        '–'
                        '${filters.endYear}',
                      ),
                      avatar: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                      ),
                      onDeleted: onRemoveYear,
                    ),
                  ),

                ...filters.conditions.map(
                  (condition) => Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: InputChip(
                      label: Text(
                        conditionLabel(condition),
                      ),
                      avatar: const Icon(
                        Icons.auto_stories_outlined,
                        size: 18,
                      ),
                      onDeleted: () {
                        onRemoveCondition(condition);
                      },
                    ),
                  ),
                ),

                ...filters.genres.map(
                  (genre) => Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: InputChip(
                      label: Text(
                        genreLabel(genre),
                      ),
                      avatar: const Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                      ),
                      onDeleted: () {
                        onRemoveGenre(genre);
                      },
                    ),
                  ),
                ),

                if (filters.maxDistanceKm != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: InputChip(
                      label: Text(
                        'Até '
                        '${filters.maxDistanceKm!.toInt()} km',
                      ),
                      avatar: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                      ),
                      onDeleted:
                          onRemoveDistance,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// A visual placeholder displayed when the feed has no announcements.
///
/// This widget shows a book icon and a friendly message encouraging the
/// user to take the first step and create a book trade announcement.
class EmptyFeedState extends StatelessWidget {
  const EmptyFeedState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          20.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories,
              size: 80.0,
              color: Colors.grey,
            ),
            const SizedBox(height: 24.0),
            Text(
              "O feed está vazio!",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12.0),
            Text(
              "Que tal dar o primeiro passo e anunciar aquele livro que está parado na estante?",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}