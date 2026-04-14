import 'package:flutter/material.dart';

import 'book_edition/book_edition_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(),
        body: TabBarView(
          children: [
            const Center(child: Text("Teste")),
            BookEditionPage(id: 'b12f1eeb-b2c8-426e-8153-bb7679c393f0'), //criado estaticamnete, depois passar o id do anuncio
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.edit)),
          ],
        ),
      ),
    );
  }
}