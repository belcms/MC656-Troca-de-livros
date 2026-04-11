import 'dart:ffi';
import 'package:flutter/material.dart';


class AnnouncementCard extends StatelessWidget {
  final String title;
  final Int publishYear;
  final String photo;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0, // Altura da sombra
      color: Colors.white, // Cor de fundo
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // Cantos arredondados
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0), // Espaçamento interno
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.album, size: 50),
            SizedBox(height: 10),
            Text('Título do Cartão', style: TextStyle(fontSize: 20)),
            Text('Subtítulo com a descrição do conteúdo do cartão.'),
          ],
        ),
      ),
    );
  }
}
