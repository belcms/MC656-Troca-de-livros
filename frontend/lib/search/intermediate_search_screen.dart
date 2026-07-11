import 'package:flutter/material.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';
import 'package:frontend/search/widgets/intermediate_post_result_card.dart';

class IntermediateSearchScreen extends StatefulWidget {
  const IntermediateSearchScreen({super.key});

  @override
  State<IntermediateSearchScreen> createState() =>
      _IntermediateSearchScreenState();
}

class _IntermediateSearchScreenState extends State<IntermediateSearchScreen> {
  final TextEditingController _controller = TextEditingController(text: 'Harr');

  final List<_MockSearchResult> _results = const [
    _MockSearchResult(
      title: 'Flores para Algernon',
      publishYear: '2000',
      location: 'Campinas - SP',
      photoUrl: 'https://example.com/flores-para-algernon.jpg',
    ),
    _MockSearchResult(
      title: 'O tal do 1984',
      publishYear: '2000',
      location: 'Campinas - SP',
      photoUrl: 'https://example.com/o-tal-do-1984.jpg',
    ),
    _MockSearchResult(
      title: 'O poder do hábito',
      publishYear: '2000',
      location: 'Campinas - SP',
      photoUrl: 'https://example.com/o-poder-do-habito.jpg',
    ),
    _MockSearchResult(
      title: 'O pequeno príncipe',
      publishYear: '2000',
      location: 'Campinas - SP',
      photoUrl: 'https://example.com/o-pequeno-principe.jpg',
    ),
  ];

  String _query = 'Harr';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      _query = _controller.text;
    });
  }

  void _handleSubmitted(String value) {
    debugPrint('Search submitted: $value');
  }

  void _handleClear() {
    setState(() {
      _query = _controller.text;
    });
  }

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
                      onChanged: (value) => setState(() => _query = value),
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
                'Encontramos 7 resultados para "$_query"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF727272),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final result in _results)
                        IntermediatePostResultCard(
                          title: result.title,
                          publishYear: result.publishYear,
                          location: result.location,
                          photoUrl: result.photoUrl,
                        ),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Ver mais resultados'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _MockSearchResult {
  const _MockSearchResult({
    required this.title,
    required this.publishYear,
    required this.location,
    required this.photoUrl,
  });

  final String title;
  final String publishYear;
  final String location;
  final String photoUrl;
}
