import 'package:flutter/material.dart';
import 'package:frontend/book_details/announcement_detail_screen.dart';
import 'package:frontend/feed/announcement_card.dart';
import 'package:frontend/search/announcement_search_models.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';
import 'package:frontend/services/announcement_service.dart';

typedef SearchResultsLoader =
    Future<AnnouncementSearchResponse> Function({
      required String query,
      required int limit,
      required int offset,
    });

class FinalSearchResultsScreen extends StatefulWidget {
  const FinalSearchResultsScreen({
    super.key,
    required this.query,
    this.searchLoader = AnnouncementService.fetchSearchAnnouncements,
    this.scrollController,
  });

  final String query;
  final SearchResultsLoader searchLoader;
  final ScrollController? scrollController;

  @override
  State<FinalSearchResultsScreen> createState() =>
      _FinalSearchResultsScreenState();
}

class _FinalSearchResultsScreenState extends State<FinalSearchResultsScreen> {
  static const int _pageSize = 20;
  static const double _paginationThreshold = 200;

  final TextEditingController _controller = TextEditingController();
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  final List<AnnouncementSearchItem> _results = <AnnouncementSearchItem>[];

  String _query = '';
  int _totalResults = 0;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasInitialized = false;
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _query = widget.query.trim();
    _controller.text = _query;
    _scrollController.addListener(_handleScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isInitialLoading || _isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > _paginationThreshold) {
      return;
    }

    if (_results.length >= _totalResults) {
      return;
    }

    _fetchPage(reset: false);
  }

  Future<void> _fetchPage({required bool reset}) async {
    final trimmedQuery = _query.trim();

    if (trimmedQuery.length < 2) {
      setState(() {
        _results.clear();
        _totalResults = 0;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    final int requestToken = ++_requestToken;
    final int offset = reset ? 0 : _results.length;

    setState(() {
      if (reset || !_hasInitialized) {
        _isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await widget.searchLoader(
        query: trimmedQuery,
        limit: _pageSize,
        offset: offset,
      );

      if (!mounted || requestToken != _requestToken) {
        return;
      }

      setState(() {
        _query = trimmedQuery;
        if (reset) {
          _results
            ..clear()
            ..addAll(response.results);
        } else {
          _results.addAll(response.results);
        }
        _totalResults = response.total;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasInitialized = true;
      });
    } catch (e) {
      if (!mounted || requestToken != _requestToken) {
        return;
      }

      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasInitialized = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _submitQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _query.trim() && _results.isNotEmpty) {
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() {
      _query = trimmed;
      _controller.text = trimmed;
      _controller.selection = TextSelection.collapsed(offset: trimmed.length);
      _results.clear();
      _totalResults = 0;
    });

    _fetchPage(reset: true);
  }

  void _clearQuery() {
    setState(() {
      _query = '';
      _results.clear();
      _totalResults = 0;
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
    _requestToken++;
  }

  void _openAnnouncementDetails(String announcementId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AnnouncementDetailScreen(announcementId: announcementId),
      ),
    );
  }

  bool get _showEmptyState =>
      (!_isInitialLoading && _query.trim().length < 2) ||
      (!_isInitialLoading && _results.isEmpty && _totalResults == 0);

  bool get _canLoadMore =>
      _results.isNotEmpty && _results.length < _totalResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _query.trim().length < 2
        ? 'Digite ao menos 2 caracteres para buscar.'
        : 'Encontramos $_totalResults resultados para "$_query"';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Resultados',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      controller: _controller,
                      autofocus: false,
                      hintText: 'Buscar livros, autores ou editoras',
                      onChanged: (_) {},
                      onSubmitted: _submitQuery,
                      onClear: _clearQuery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF727272),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_isInitialLoading && _results.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_showEmptyState) {
                      return const Center(
                        child: Text('Nenhum livro encontrado.'),
                      );
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.50,
                          ),
                      itemCount: _results.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isLoadingMore && index == _results.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final result = _results[index];
                        return GestureDetector(
                          onTap: () => _openAnnouncementDetails(result.id),
                          child: AnnouncementCard(
                            title: result.title,
                            publishYear: result.publishYear,
                            photo: result.coverPhoto ?? '',
                            // photo: result.realPhotoUrl ?? '',
                            location: result.cep,
                            condition: result.condition,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_canLoadMore)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: SizedBox(
                      width: 260,
                      child: ElevatedButton(
                        onPressed: _isLoadingMore
                            ? null
                            : () => _fetchPage(reset: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF416956),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Ver mais resultados'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
