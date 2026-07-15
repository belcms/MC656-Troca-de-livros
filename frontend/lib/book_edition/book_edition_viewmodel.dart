
import 'package:flutter/material.dart';
import 'book_model.dart';
import '../services/announcement_service.dart';

/// defines the contract used by the viewmodel to communicate with the service layer
abstract class AnnouncementServiceInterface {
  /// fetches announcement details by id
  /// returns the json map or null if something goes wrong
  Future<Map<String, dynamic>?> fetchAnnouncementDetails(String id);

  /// sends updated announcement data to backend
  /// returns true if update works
  Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  });
}

/// adapts the real service to the interface used by the viewmodel
class AnnouncementServiceAdapter implements AnnouncementServiceInterface {
  /// calls the service method that fetches announcement details
  @override
  Future<Map<String, dynamic>?> fetchAnnouncementDetails(String id) {
    return AnnouncementService.fetchAnnouncementDetailsRaw(id);
  }

  /// calls the service method that updates an announcement
  @override
  Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) {
    return AnnouncementService.updateAnnouncement(id: id, body: body);
  }
}

/// manages the state and logic of the book edition screen
class BookEditionViewModel {
  /// service responsible for backend communication
  final AnnouncementServiceInterface service;

  /// allows dependency injection for testing or custom implementations
  BookEditionViewModel({AnnouncementServiceInterface? service})
      : service = service ?? AnnouncementServiceAdapter();

  /// controllers used to manage form field values
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final publisherController = TextEditingController();
  final yearController = TextEditingController();
  final pagesController = TextEditingController();
  final synopsisController = TextEditingController();
  final descriptionController = TextEditingController();
  final cepController = TextEditingController();

  /// selected values used in dropdowns and chips
  String genre = "Romance";
  String language = "Português";
  String status = "Disponível";
  String condition = "Novo";
  
  List<String> photoUrls = [];

  /// loads announcement data from backend
  /// fills controllers and local state with returned values
  Future<bool> loadFromServer(String id) async {
    final data = await service.fetchAnnouncementDetails(id);

    if (data == null) {
      return false;
    }

    final book = Book.fromJson(data);

    // Garante que se vier nulo do banco, não quebre a tela transformando em string vazia
    titleController.text = book.title ?? '';
    authorController.text = book.author ?? '';
    publisherController.text = book.publisher ?? '';
    yearController.text = book.year?.toString() ?? '';
    pagesController.text = book.pages?.toString() ?? ''; // Garante que carrega as páginas!
    synopsisController.text = book.synopsis ?? '';
    descriptionController.text = book.description ?? '';

    cepController.text = (data['cep_id'] ?? '').toString();

    genre = (book.genre == null || book.genre.isEmpty) ? "Romance" : book.genre;
    language = (book.language == null || book.language.isEmpty) ? "Português" : book.language;
    status = (book.status == null || book.status.isEmpty) ? "Disponível" : book.status;
    condition = (book.condition == null || book.condition.isEmpty) ? "Novo" : book.condition;

    photoUrls = book.photoUrls;

    return true;
  }

  /// updates selected announcement status
  void setStatus(String value) {
    status = value;
  }

  /// updates selected book condition
  void setCondition(String value) {
    condition = value;
  }

  /// creates a book object using current form values
  Book buildBook(String id) {
    return Book(
      id: id,
      /// trims user input before sending
      title: titleController.text.trim(),
      author: authorController.text.trim(),
      publisher: publisherController.text.trim(),
      genre: genre,
      language: language,
      year: yearController.text.trim(),
      pages: pagesController.text.trim(),
      synopsis: synopsisController.text.trim(),
      description: descriptionController.text.trim(),
      status: status,
      condition: condition,
      photoUrls: photoUrls, // Manda a primeira foto como capa (se o book_model ainda usar isso)
      cep_id: cepController.text.trim(),
      // Se o seu book_model aceitar a lista inteira, adicione ela aqui (ex: photos: photoUrls)
    );
  }

  /// sends the edited data to backend
  /// returns true if update succeeds
  Future<bool> submit(String id) async {
    final book = buildBook(id);

    final ok = await service.updateAnnouncement(id: id, body: book.toJson());

    return ok;
  }

  /// disposes all controllers to avoid memory leaks
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