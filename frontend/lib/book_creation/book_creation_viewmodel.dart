import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

class BookCreationViewModel {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final publisherController = TextEditingController();
  final yearController = TextEditingController();
  final pagesController = TextEditingController();
  final synopsisController = TextEditingController();
  final descriptionController = TextEditingController();

  String genre = "Romance";
  String language = "Português";
  String status = "Disponível";
  String condition = "Novo";

  void setStatus(String value) {
    status = value;
  }

  void setCondition(String value) {
    condition = value;
  }

  /// Método chamado ao clicar em "Criar anúncio"
  Future<bool> submit(String? coverUrl, String userId) async {
    // 1. Aqui você agrupa todos os dados para enviar ao Back-end
    final Map<String, dynamic> novoLivro = {
      "title": titleController.text,
      "author": authorController.text,
      "publisher": publisherController.text,
      "year": yearController.text,
      "pages": pagesController.text,
      "synopsis": synopsisController.text,
      "description": descriptionController.text,
      "genre": genre,
      "language": language,
      "status": status,
      "condition": condition,
      "coverUrl": coverUrl ?? "", // Envia vazio se o usuário não colou link
    };

    try {
      // chamando o serviço de criação de anuncio
      final sucesso = await AnnouncementService.createAnnouncement(
        body: novoLivro, userId: userId
      );

      return sucesso; // Retorna sucesso
    } catch (e) {
      print("Erro ao salvar: $e");
      return false; // Retorna erro, ativando a mensagem de falha na tela
    }
  }

  /// Limpeza de memória
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    publisherController.dispose();
    yearController.dispose();
    pagesController.dispose();
    synopsisController.dispose();
    descriptionController.dispose();
  }
}
