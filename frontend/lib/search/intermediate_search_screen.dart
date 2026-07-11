import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/search/announcement_search_models.dart';
import 'package:frontend/services/announcement_service.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';
import 'package:frontend/search/widgets/intermediate_post_result_card.dart';

typedef SearchAnnouncementsLoader =
    Future<AnnouncementSearchResponse> Function({
      required String query,
      required int limit,
      required int offset,
    });

class IntermediateSearchScreen extends StatefulWidget {
  const IntermediateSearchScreen({
    super.key,
    this.searchLoader = AnnouncementService.fetchSearchAnnouncements,
  });

  final SearchAnnouncementsLoader searchLoader;

  @override
  State<IntermediateSearchScreen> createState() =>
      _IntermediateSearchScreenState();
}

class _IntermediateSearchScreenState extends State<IntermediateSearchScreen> {
  static const int _pageSize = 4;

  final TextEditingController _controller = TextEditingController();
  final List<AnnouncementSearchItem> _results = <AnnouncementSearchItem>[];
  Timer? _debounceTimer;

  String _query = '';
  int _totalResults = 0;
  bool _isLoading = false;
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    _scheduleSearch(_controller.text);
  }

  void _handleSubmitted(String value) {
    _debounceTimer?.cancel();
    _performSearch(value);
  }

  void _handleClear() {
    setState(() {
      _query = _controller.text;
      _results.clear();
      _totalResults = 0;
      _isLoading = false;
    });
    _debounceTimer?.cancel();
  }

  void _scheduleSearch(String value) {
    setState(() {
      _query = value;
    });

    _debounceTimer?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        _results.clear();
        _totalResults = 0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String value) async {
    final trimmedQuery = value.trim();

    if (trimmedQuery.length < 2) {
      return;
    }

    final int requestToken = ++_requestToken;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.searchLoader(
        query: trimmedQuery,
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted || requestToken != _requestToken) {
        return;
      }

      setState(() {
        _query = trimmedQuery;
        _results
          ..clear()
          ..addAll(response.results);
        _totalResults = response.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestToken != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool get _shouldShowEmptyState =>
      _query.trim().length < 2 || (!_isLoading && _totalResults == 0);

  bool get _shouldShowMoreButton =>
      !_isLoading && _totalResults > _results.length && _results.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomSearchBar(
                      controller: _controller,
                      autofocus: true,
                      hintText: 'Buscar livros, autores ou editoras',
                      onChanged: _scheduleSearch,
                      onSubmitted: _handleSubmitted,
                      onClear: _handleClear,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Resultados', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                _query.trim().length < 2
                    ? 'Digite ao menos 2 caracteres para buscar.'
                    : 'Encontramos $_totalResults resultados para "$_query"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF727272),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_shouldShowEmptyState) {
                      return const Center(
                        child: Text('Nenhum livro encontrado.'),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final result in _results)
                            IntermediatePostResultCard(
                              title: result.title,
                              publishYear: result.publishYear.toString(),
                              location: result.cep,
                              photoUrl: result.realPhotoUrl ?? '',
                            ),
                          if (_shouldShowMoreButton) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: SizedBox(
                                width: 260,
                                child: ElevatedButton(
                                  onPressed: () {
                                    debugPrint('Ver mais resultados');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF416956),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text('Ver mais resultados'),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
