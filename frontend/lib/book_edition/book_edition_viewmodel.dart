import 'package:flutter/material.dart';
import 'book_model.dart';
import '../services/announcement_service.dart';

class BookEditionViewModel {
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
  String? coverUrl;

  Future<bool> loadFromServer(String id) async {
    final data = await AnnouncementService.fetchAnnouncementDetails(id);

    if (data == null) {
      return false;
    }

    final book = Book.fromJson(data);

    titleController.text = book.title;
    authorController.text = book.author;
    publisherController.text = book.publisher;
    yearController.text = book.year;
    pagesController.text = book.pages;
    synopsisController.text = book.synopsis;
    descriptionController.text = book.description;

    genre = book.genre.isEmpty ? "Romance" : book.genre;
    language = book.language.isEmpty ? "Português" : book.language;
    status = book.status.isEmpty ? "Disponível" : book.status;
    condition = book.condition.isEmpty ? "Novo" : book.condition;
    coverUrl = book.coverUrl;

    return true;
  }

  void setStatus(String value) {
    status = value;
  }

  void setCondition(String value) {
    condition = value;
  }

  Book buildBook(String id) {
    return Book(
      id: id,
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
      coverUrl: coverUrl,
    );
  }

  Future<bool> submit(String id) async {
    final book = buildBook(id);

    final ok = await AnnouncementService.updateAnnouncement(
      id: id,
      body: book.toJson(),
    );

    return ok;
  }

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