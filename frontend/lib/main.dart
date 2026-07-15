import 'package:flutter/material.dart';
import 'book_creation/book_creation_screen.dart';
import 'feed/feed_view.dart';
import 'user_profile/user_profile_screen.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_screens.dart';
import 'trade_requests/screens/trade_requests_screen.dart';
import 'auth/http_auth_repository.dart';
import 'services/api_client.dart';

void main() {
  final authRepository = HttpAuthRepository.instance;

  ApiClient.authTokenProvider = authRepository;

  final auth = AuthController(
    repository: authRepository,
  );

  runApp(
    AuthScope(
      controller: auth,
      child: const MyApp(),
    ),
  );

  auth.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Books',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF416956),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF6EA),
        useMaterial3: true,
        textTheme: const TextTheme(
          // Page Titles (like 'Meus Livros')
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          // 'Disponibilidade'-level headers
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          // Book Card Titles
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          // Book Card Year
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400,
            color: Color(0xFF727272),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.authenticated ? const TelaPrincipal() : const LoginScreen();
  }
}

class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),

        body: const TabBarView(children: [FeedView(), UserProfileScreen(), BookCreationPage(), TradeRequestsScreen()]),

        // BARRA NO RODAPÉ
        bottomNavigationBar: Container(
          color: Colors.blueGrey[900],
          child: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.cyan,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Feed'),
              Tab(icon: Icon(Icons.person), text: 'Perfil'),
              Tab(icon: Icon(Icons.create), text: "Criar Anúncio",),
              Tab(icon: Icon(Icons.swap_horiz), text: "Solicitações",)
            ],
          ),
        ),
      ),
    );
  }
}