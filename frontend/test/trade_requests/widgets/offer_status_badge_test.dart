import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/widgets/offer_status_badge.dart';

void main() {
  testWidgets('exibe o rótulo de cada status', (tester) async {
    for (final status in OfferStatus.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfferStatusBadge(status: status),
          ),
        ),
      );

      expect(find.text(status.label), findsOneWidget);
    }
  });

  testWidgets('expand ocupa a largura disponível', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: OfferStatusBadge(
              status: OfferStatus.pending,
              expand: true,
            ),
          ),
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.text('Pendente'),
            matching: find.byType(SizedBox),
          )
          .first,
    );

    expect(sizedBox.width, double.infinity);
  });
}
