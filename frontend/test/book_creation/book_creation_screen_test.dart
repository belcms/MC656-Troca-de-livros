import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/auth/auth_repository.dart';
import 'package:frontend/auth/auth_user.dart';
import 'package:frontend/book_creation/book_creation_screen.dart';

void main() {
  setUp(() {
    AuthRepository.instance.user = const AuthUser(
      id: 'user-test',
      fullName: 'Usuário Teste',
      nickname: 'usuario_teste',
      email: 'usuario@example.com',
    );
  });

  tearDown(() {
    AuthRepository.instance.user = null;
  });

  testWidgets('renderiza a tela de criação de anúncio', (tester) async {
    // Monta a tela virtualmente
    await tester.pumpWidget(const MaterialApp(home: BookCreationPage()));

    // Verifica se a página principal do widget foi desenhada
    expect(find.byType(BookCreationPage), findsOneWidget);

    // Verifica se o texto do AppBar apareceu na tela
    expect(find.text("Criar anúncio"), findsNWidgets(2));
  });
}
