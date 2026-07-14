class AnnouncementFilters {
  static const int defaultStartYear = 1900;
  static const int defaultEndYear = 2026;

  final int startYear;
  final int endYear;
  final List<String> conditions;
  final List<String> genres;
  final double? maxDistanceKm;

  const AnnouncementFilters({
    this.startYear = defaultStartYear,
    this.endYear = defaultEndYear,
    this.conditions = const [],
    this.genres = const [],
    this.maxDistanceKm,
  });

  bool get hasActiveFilters {
    return startYear != defaultStartYear ||
        endYear != defaultEndYear ||
        conditions.isNotEmpty ||
        genres.isNotEmpty ||
        maxDistanceKm != null;
  }

  bool get hasYearFilter {
    return startYear != defaultStartYear ||
        endYear != defaultEndYear;
  }

  AnnouncementFilters copyWith({
    int? startYear,
    int? endYear,
    List<String>? conditions,
    List<String>? genres,
    double? maxDistanceKm,
    bool clearYears = false,
    bool clearConditions = false,
    bool clearGenres = false,
    bool clearDistance = false,
  }) {
    return AnnouncementFilters(
      startYear: clearYears
          ? defaultStartYear
          : startYear ?? this.startYear,
      endYear: clearYears
          ? defaultEndYear
          : endYear ?? this.endYear,
      conditions: clearConditions
          ? const []
          : conditions ?? this.conditions,
      genres: clearGenres
          ? const []
          : genres ?? this.genres,
      maxDistanceKm: clearDistance
          ? null
          : maxDistanceKm ?? this.maxDistanceKm,
    );
  }

  static const empty = AnnouncementFilters();
}