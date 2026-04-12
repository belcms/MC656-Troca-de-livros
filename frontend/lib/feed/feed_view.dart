import 'package:flutter/material.dart';
import 'announcement_card.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  


  @override
  Widget build(BuildContext context) {


    final List<Map<String, dynamic>> livros = [
      {'title': 'Trono de Vidro', 'year': 2012, 'photo': 'https://m.media-amazon.com/images/I/81m94OedHqL._SL1500_.jpg', 'cep': 'Americana - SP'},
      {'title': 'Coroa da Meia-Noite', 'year': 2013, 'photo': 'https://m.media-amazon.com/images/I/814x0T5JlsL._SL1500_.jpg', 'cep': 'Hortolândia - SP'},
      {'title': 'Herdeira do Fogo', 'year': 2014, 'photo': 'https://m.media-amazon.com/images/I/81z-fUzRFxL._SL1500_.jpg', 'cep': 'São Paulo - SP'},
      {'title': 'Rainha das Sombras', 'year': 2015, 'photo': 'https://m.media-amazon.com/images/I/81bXtL9Ii1L._SL1500_.jpg', 'cep': 'Vinhedo - SP'},
      {'title': 'Império de Tempestades', 'year': 2016, 'photo': 'https://m.media-amazon.com/images/I/910tBzUIfwL._SL1500_.jpg', 'cep': 'Campinas - SP'},
    ];


    return Scaffold(

      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Text('Home', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: .bold)),
              ),



            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: livros.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,         
                  crossAxisSpacing: 1.0,   
                  mainAxisSpacing: 16.0,    
                  childAspectRatio: 0.50,    
                  
              ), 
              itemBuilder: (context, index) {
                final livro = livros[index];
                return AnnouncementCard(title: livro['title'], publishYear: livro['year'], photo: livro['photo'], cep: livro['cep']);
              },
            )
            )
        ],)
        )
    );
  }
}
