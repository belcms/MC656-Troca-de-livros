import 'package:flutter/material.dart';
import 'announcement_card.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnnouncementCard(title: 'Trono de vidro', publishYear: 2014, photo: 'https://m.media-amazon.com/images/I/81m94OedHqL._SY522_.jpg', cep: "Campinas - SP")
    );
    
  }
}
