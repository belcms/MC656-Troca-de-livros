import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
              id: '9baef69c-5e31-4b29-9159-88bfd4e1da42',
            ), //criado estaticamnete, depois passar o id do anuncio
            BookCreationPage(userId: 'd9490809-09b7-4bf9-8165-56db8d45c32c'),
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
