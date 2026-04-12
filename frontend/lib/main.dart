import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'book_details/announcement_detail_screen.dart';
import 'services/user_service.dart';
import 'feed/feed_view.dart';

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

// 1. A ESTRUTURA PRINCIPAL
class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(),

        // AQUI ESTÁ A MÁGICA: O corpo da tela chama as classes
        body: const TabBarView(
          children: [
            FeedView(), // <--- Chamando sua classe aqui!
            AnnouncementDetailScreen(announcementId: '4db58101-279f-42b6-bfca-d9b269d93329'), // <--- Chamando outra classe de teste
          ],
        ),

        // BARRA NO RODAPÉ
        bottomNavigationBar: Container(
          color: Colors.blueGrey[900],
          child: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.cyan,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Feed'),
              Tab(icon: Icon(Icons.settings), text: 'Config'),
            ],
          ),
        ),
      ),
    );
  }
}


// 3. OUTRA CLASSE APENAS PARA TESTAR A TAB
class SegundaTelaTestes extends StatelessWidget {
  const SegundaTelaTestes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("OUTRA TELA DE TESTE"));
  }
}
