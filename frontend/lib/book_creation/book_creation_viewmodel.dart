import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

/// Abstract interface defining the contract for the announcement creation service.
abstract class CreationServiceInterface {
  /// Submits a new announcement payload to the backend for a specific user.
  ///
  /// [body] is a map containing the parsed book and announcement data.
  Future<String?> createAnnouncement({required Map<String, dynamic> body});
}

/// Concrete implementation of [CreationServiceInterface] that delegates
/// the creation request to the [AnnouncementService].
class CreationServiceAdapter implements CreationServiceInterface {
  @override
  Future<String?> createAnnouncement({required Map<String, dynamic> body}) {
    return AnnouncementService.createAnnouncement(body: body);
  }
}

/// ViewModel responsible for managing the state, text controllers, and business
/// logic of the book creation screen.
class BookCreationViewModel {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final publisherController = TextEditingController();
  final yearController = TextEditingController();
  final pagesController = TextEditingController();
  final synopsisController = TextEditingController();
  final descriptionController = TextEditingController();
  final cepController = TextEditingController();


  String genre = "Romance";
  String language = "Português";
  String status = "Disponível";
  String condition = "Novo";

  final CreationServiceInterface service;

  BookCreationViewModel({CreationServiceInterface? service})
    : service = service ?? CreationServiceAdapter();

  /// Updates the current status of the book announcement.
  ///
  /// [value] is the localized status string selected by the user.
  void setStatus(String value) {
    status = value;
  }

  /// Updates the physical condition of the book.
  ///
  /// [value] is the localized condition string selected by the user.
  void setCondition(String value) {
    condition = value;
  }

  /// Processes the form data and submits the announcement creation request.
  ///
  /// This method performs several steps:
  /// 1. Maps localized UI strings (Portuguese) to backend enum values (English).
  /// 2. Parses string inputs for 'year' and 'pages' into integers.
  /// 3. Constructs the final JSON payload.
  /// 4. Delegates the network request to the injected service.
  ///
  /// [coverUrl] is the optional URL of the uploaded cover image.
  ///
  /// Returns a Future that resolves to `true` if the announcement was created
  /// successfully, or `false` if an error occurred.
  Future<String?> submit(String? coverUrl) async {
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
      "cep": cepController.text.trim().isNotEmpty ? cepController.text.trim() : null,
    };

    // try {
    //   final sucesso = await service.createAnnouncement(body: novoLivro, userId: userId,);
    //   return sucesso;
    // } catch (e) {
    //   return false;
    // }

    try {
      final sucesso = await service.createAnnouncement(body: novoLivro);
      return sucesso;
    } catch (e) {
      return null; // Retorna null em caso de erro
    }
  }

  /// Disposes of all text controllers to free up resources and prevent memory leaks.
  /// This should be called when the ViewModel is destroyed.
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    publisherController.dispose();
    yearController.dispose();
    pagesController.dispose();
    synopsisController.dispose();
    descriptionController.dispose();
    cepController.dispose();
  }
}
