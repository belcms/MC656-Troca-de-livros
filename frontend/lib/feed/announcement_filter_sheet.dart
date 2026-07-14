import 'package:flutter/material.dart';

import 'announcement_filters.dart';

class AnnouncementFilterSheet extends StatefulWidget {
  final AnnouncementFilters initialFilters;

  const AnnouncementFilterSheet({
    super.key,
    required this.initialFilters,
  });

  @override
  State<AnnouncementFilterSheet> createState() =>
      _AnnouncementFilterSheetState();
}

class _AnnouncementFilterSheetState
    extends State<AnnouncementFilterSheet> {
  static const int minimumYear =
      AnnouncementFilters.defaultStartYear;

  static const int maximumYear =
      AnnouncementFilters.defaultEndYear;

  late RangeValues selectedYears;
  late Set<String> selectedConditions;
  late Set<String> selectedGenres;
  double? selectedDistance;

  final conditions = const [
    FilterOption(
      label: 'Novo',
      value: 'New',
    ),
    FilterOption(
      label: 'Bom',
      value: 'Good',
    ),
    FilterOption(
      label: 'Usado',
      value: 'Used',
    ),
    FilterOption(
      label: 'Desgastado',
      value: 'Worn',
    ),
  ];

  final genres = const [
    FilterOption(
      label: 'Fantasia',
      value: 'Fantasy',
    ),
    FilterOption(
      label: 'Romance',
      value: 'Romance',
    ),
    FilterOption(
      label: 'Ficção científica',
      value: 'Sci_fic',
    ),
    FilterOption(
      label: 'Não ficção',
      value: 'Non_fiction',
    ),
    FilterOption(
      label: 'Biografia',
      value: 'Biography',
    ),
    FilterOption(
      label: 'Graphic novel',
      value: 'Graphic_novel',
    ),
    FilterOption(
      label: 'Terror',
      value: 'Horror',
    ),
    FilterOption(
      label: 'Autoajuda',
      value: 'Self_help',
    ),
    FilterOption(
      label: 'Suspense',
      value: 'Thriller',
    ),
    FilterOption(
      label: 'Educação',
      value: 'Education',
    ),
  ];

  final distances = const [
    5.0,
    10.0,
    20.0,
    50.0,
    100.0,
  ];

  @override
  void initState() {
    super.initState();

    selectedYears = RangeValues(
      widget.initialFilters.startYear.toDouble(),
      widget.initialFilters.endYear.toDouble(),
    );

    selectedConditions = {
      ...widget.initialFilters.conditions,
    };

    selectedGenres = {
      ...widget.initialFilters.genres,
    };

    selectedDistance =
        widget.initialFilters.maxDistanceKm;
  }

  void _toggleCondition(
    String condition,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        selectedConditions.add(condition);
      } else {
        selectedConditions.remove(condition);
      }
    });
  }

  void _toggleGenre(
    String genre,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        selectedGenres.add(genre);
      } else {
        selectedGenres.remove(genre);
      }
    });
  }

  void _applyFilters() {
    Navigator.pop(
      context,
      AnnouncementFilters(
        startYear: selectedYears.start.round(),
        endYear: selectedYears.end.round(),
        conditions: selectedConditions.toList(),
        genres: selectedGenres.toList(),
        maxDistanceKm: selectedDistance,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedYears = RangeValues(
        minimumYear.toDouble(),
        maximumYear.toDouble(),
      );

      selectedConditions.clear();
      selectedGenres.clear();
      selectedDistance = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final startYear = selectedYears.start.round();
    final endYear = selectedYears.end.round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Ano de publicação',
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _YearLabel(year: startYear),
                  _YearLabel(year: endYear),
                ],
              ),

              RangeSlider(
                min: minimumYear.toDouble(),
                max: maximumYear.toDouble(),
                divisions:
                    maximumYear - minimumYear,
                values: selectedYears,
                labels: RangeLabels(
                  startYear.toString(),
                  endYear.toString(),
                ),
                onChanged: (values) {
                  setState(() {
                    selectedYears = values;
                  });
                },
              ),

              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Distância',
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<double>(
                initialValue: selectedDistance,
                decoration: InputDecoration(
                  hintText: 'Selecionar distância',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                items: distances.map((distance) {
                  return DropdownMenuItem<double>(
                    value: distance,
                    child: Text(
                      'Até ${distance.toInt()} km',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDistance = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const _SectionTitle(
                title: 'Estado de conservação',
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditions.map((option) {
                  final selected =
                      selectedConditions.contains(
                    option.value,
                  );

                  return FilterChip(
                    label: Text(option.label),
                    selected: selected,
                    showCheckmark: true,
                    onSelected: (isSelected) {
                      _toggleCondition(
                        option.value,
                        isSelected,
                      );
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const _SectionTitle(
                title: 'Gênero literário',
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genres.map((option) {
                  final selected =
                      selectedGenres.contains(
                    option.value,
                  );

                  return FilterChip(
                    label: Text(option.label),
                    selected: selected,
                    showCheckmark: true,
                    onSelected: (isSelected) {
                      _toggleGenre(
                        option.value,
                        isSelected,
                      );
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _applyFilters,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aplicar filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class FilterOption {
  final String label;
  final String value;

  const FilterOption({
    required this.label,
    required this.value,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _YearLabel extends StatelessWidget {
  final int year;

  const _YearLabel({
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        year.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}