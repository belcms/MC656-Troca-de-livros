import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_edition/book_edition_viewmodel.dart';

class FakeService implements AnnouncementServiceInterface {
  Map<String, dynamic>? detailsResponse;
  bool updateResponse = true;

  String? lastId;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>?> fetchAnnouncementDetails(String id) async {
    return detailsResponse;
  }

  @override
  Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    lastId = id;
    lastBody = body;
    return updateResponse;
  }
}

void main() {
  test('loadFromServer preenche os campos', () async {
    final fakeService = FakeService()
      ..detailsResponse = {
        "id": "1",
        "title": "1984",
        "author": "George Orwell",
        "publisher": "Secker",
        "genre": "Sci_fic",
        "language": "En",
        "publishYear": 1949,
        "pages": 328,
        "synopsis": "distopia",
        "description": "livro bom",
        "status": "Available",
        "condition": "Good",
        "real_photo_url": "url"
      };

    final vm = BookEditionViewModel(service: fakeService);

    final ok = await vm.loadFromServer("1");

    expect(ok, true);
    expect(vm.titleController.text, "1984");
    expect(vm.authorController.text, "George Orwell");
    expect(vm.genre, "Ficção científica");
    expect(vm.language, "Inglês");
    expect(vm.status, "Disponível");
    expect(vm.condition, "Bom");

    vm.dispose();
  });

  test('submit envia dados convertidos para o backend', () async {
    final fakeService = FakeService();

    final vm = BookEditionViewModel(service: fakeService);

    vm.titleController.text = "1984";
    vm.authorController.text = "George Orwell";
    vm.publisherController.text = "Secker";
    vm.yearController.text = "1949";
    vm.pagesController.text = "328";
    vm.synopsisController.text = "distopia";
    vm.descriptionController.text = "livro bom";
    vm.genre = "Ficção científica";
    vm.language = "Inglês";
    vm.status = "Disponível";
    vm.condition = "Bom";

    final ok = await vm.submit("1");

    expect(ok, true);
    expect(fakeService.lastId, "1");
    expect(fakeService.lastBody?["genre"], "Sci_fic");
    expect(fakeService.lastBody?["language"], "En");
    expect(fakeService.lastBody?["status"], "Available");
    expect(fakeService.lastBody?["condition"], "Good");

    vm.dispose();
  });
}