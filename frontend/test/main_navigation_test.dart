import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('barra inferior possui acesso a Solicitações', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Criar Anúncio'), findsOneWidget);
    expect(find.text('Solicitações'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  testWidgets('tocar em Solicitações abre a tela da feature', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('Solicitações'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitações de troca'), findsOneWidget);
  });
}
