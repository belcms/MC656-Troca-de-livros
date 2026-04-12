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
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF416956),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF6EA),
        useMaterial3: true,
      ),
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),

        body: const TabBarView(children: [FeedView(), SegundaTelaTestes()]),

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
class SegundaTelaTestes extends StatefulWidget {
  const SegundaTelaTestes({super.key});

  @override
  State<SegundaTelaTestes> createState() => _SegundaTelaTestesState();
}

class _SegundaTelaTestesState extends State<SegundaTelaTestes> {
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Teste detalhes do anúncio'),
          const SizedBox(height: 12),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'UUID do anúncio',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final id = _idController.text.trim();
              if (id.isEmpty) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(announcementId: id),
                ),
              );
            },
            child: const Text('Abrir detalhes'),
          ),
        ],
      ),
    );
  }
}
