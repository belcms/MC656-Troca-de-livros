import 'package:flutter/material.dart';

import 'book_edition/book_edition_screen.dart';

import 'book_creation/book_creation_screen.dart';
import 'services/announcement_service.dart';

void main() {

  //run dummy data
  AnnouncementService.setDummyData();
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(),
        body: TabBarView(
          children: [
            const Center(child: Text("Teste")),
            BookEditionPage(
              id: 'a7d81cac-9407-49b0-bbb8-a339720c1d8d',
            ), //criado estaticamnete, depois passar o id do anuncio
            BookCreationPage(userId: '56cae0e6-ff60-4e63-a971-d951f015c28e'),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.edit)),
            Tab(icon: Icon(Icons.book)),
          ],
        ),
      ),
    );
  }
}
