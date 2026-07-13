import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/auth/auth_controller.dart';
import 'package:frontend/auth/auth_user.dart';
import 'package:frontend/main.dart';

AuthController authenticatedController() {
  final controller = AuthController();
  controller.initializing = false;
  controller.repository.user = const AuthUser(
    id: 'user-test',
    fullName: 'Usuário Teste',
    nickname: 'usuario_teste',
    email: 'usuario@example.com',
  );
  return controller;
}

void main() {
  testWidgets('barra inferior possui acesso a Solicitações', (tester) async {
    final controller = authenticatedController();
    addTearDown(() => controller.repository.user = null);

    await tester.pumpWidget(
      AuthScope(controller: controller, child: const MyApp()),
    );
    await tester.pump();

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Criar Anúncio'), findsOneWidget);
    expect(find.text('Solicitações'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  testWidgets('tocar em Solicitações abre a tela da feature', (tester) async {
    final controller = authenticatedController();
    addTearDown(() => controller.repository.user = null);

    await tester.pumpWidget(
      AuthScope(controller: controller, child: const MyApp()),
    );
    await tester.pump();

    await tester.tap(find.text('Solicitações'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitações de troca'), findsOneWidget);
  });
}
