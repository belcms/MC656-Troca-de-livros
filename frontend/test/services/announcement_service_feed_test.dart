import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/feed/announcement_filters.dart';
import 'package:frontend/services/announcement_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AnnouncementService.fetchFeedAnnouncements', () {
    test(
      'envia usuário e parâmetros de distância quando autenticado',
      () async {
        Uri? requestedUrl;
        final client = MockClient((request) async {
          requestedUrl = request.url;
          return http.Response('[]', 200);
        });

        final result = await AnnouncementService.fetchFeedAnnouncements(
          currentUserId: ' user-123 ',
          sortByDistance: true,
          filters: const AnnouncementFilters(maxDistanceKm: 25),
          client: client,
        );

        expect(result, isEmpty);
        expect(requestedUrl?.queryParameters['current_user_id'], 'user-123');
        expect(requestedUrl?.queryParameters['sort_by_distance'], 'true');
        expect(requestedUrl?.queryParameters['max_distance_km'], '25.0');
      },
    );

    test('omite parâmetros de distância quando não há usuário', () async {
      Uri? requestedUrl;
      final client = MockClient((request) async {
        requestedUrl = request.url;
        return http.Response('[]', 200);
      });

      final result = await AnnouncementService.fetchFeedAnnouncements(
        currentUserId: null,
        sortByDistance: true,
        filters: const AnnouncementFilters(maxDistanceKm: 25),
        client: client,
      );

      expect(result, isEmpty);
      expect(requestedUrl?.queryParameters, isNot(contains('current_user_id')));
      expect(
        requestedUrl?.queryParameters,
        isNot(contains('sort_by_distance')),
      );
      expect(requestedUrl?.queryParameters, isNot(contains('max_distance_km')));
    });
  });
}
