import 'package:flutter/material.dart';
import 'package:frontend/book_edition/book_model.dart';
import '../services/announcement_service.dart';

// 1. Crie a Interface e o Adapter (Igual no Edition)
abstract class CreationServiceInterface {
  Future<bool> createAnnouncement({
    required Map<String, dynamic> body,
    required String userId,
  });
}

class CreationServiceAdapter implements CreationServiceInterface {
  @override
  Future<bool> createAnnouncement({
    required Map<String, dynamic> body,
    required String userId,
  }) {
    return AnnouncementService.createAnnouncement(body: body, userId: userId);
  }
}

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

  final CreationServiceInterface service;

  BookCreationViewModel({CreationServiceInterface? service})
      : service = service ?? CreationServiceAdapter();

  void setStatus(String value) {
    status = value;
  }

  void setCondition(String value) {
    condition = value;
  }

  /// Método chamado ao clicar em "Criar anúncio"
  Future<bool> submit(String? coverUrl, String userId) async {
    // 1. TRADUTORES: Convertem do português da tela para o inglês do Banco
    String mapLanguage() {
      if (language == "Inglês") return "En";
      if (language == "Espanhol") return "Espanhol";
      return "PT-br";
    }

    String mapGenre() {
      switch (genre) {
        case "Fantasia":
          return "Fantasy";
        case "Ficção científica":
          return "Sci_fic";
        case "Não ficção":
          return "Non_fiction";
        case "Biografia":
          return "Biography";
        case "Graphic novel":
          return "Graphic_novel";
        case "Terror":
          return "Horror";
        case "Autoajuda":
          return "Self_help";
        case "Suspense":
          return "Thriller";
        case "Acadêmico":
          return "Education";
        default:
          return "Romance";
      }
    }

    String mapCondition() {
      if (condition == "Muito bom") return "Used";
      if (condition == "Bom") return "Good";
      if (condition == "Desgastado") return "Worn";
      return "New";
    }

    String mapStatus() {
      if (status == "Negociando") return "Reserved";
      if (status == "Trocado") return "Traded";
      return "Available";
    }

    // 2. CONVERSÃO: Garante que Ano e Páginas vão como Números (Int) e não Texto
    int anoFormatado = int.tryParse(yearController.text) ?? 0;
    int paginasFormatadas = int.tryParse(pagesController.text) ?? 0;

    // 3. Monta o JSON blindado!
    final Map<String, dynamic> novoLivro = {
      "title": titleController.text,
      "author": authorController.text,
      "publisher": publisherController.text,
      "year": anoFormatado, // <--- Enviando como Int!
      "pages": paginasFormatadas, // <--- Enviando como Int!
      "synopsis": synopsisController.text,
      "description": descriptionController.text,
      "genre": mapGenre(), // <--- Usando o tradutor de Gênero
      "language": mapLanguage(), // <--- Usando o tradutor de Idioma
      "status": mapStatus(), // <--- Usando o tradutor de Status
      "condition": mapCondition(), // <--- Usando o tradutor de Condição
      "coverUrl": coverUrl ?? "",
    };

    try {
      final sucesso = await service.createAnnouncement(
        body: novoLivro,
        userId: userId,
      );

      return sucesso;
    } catch (e) {
      print("Erro ao salvar: $e");
      return false;
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
