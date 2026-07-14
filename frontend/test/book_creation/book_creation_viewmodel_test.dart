import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_creation/book_creation_viewmodel.dart';

// 1. Criamos um serviço Falso que intercepta os dados em vez de mandar para a API
class FakeCreationService implements CreationServiceInterface {
  String? createResponse = 'fake_id_12345';
  String? lastUserId;
  Map<String, dynamic>? lastBody;

  @override
  Future<String?> createAnnouncement({
    required Map<String, dynamic> body,
    required String userId,
  }) async {
    lastUserId = userId;
    lastBody = body;
    return createResponse; // Simula que a API deu 201 Created
  }
}

void main() {
  group('BookCreationViewModel', () {
    test('submit traduz Enums e converte Ints para o backend', () async {
      final fakeService = FakeCreationService();
      // Se você quiser garantir um ID específico no teste, pode setar aqui:
      // fakeService.createResponse = "meu_id_123";

      final vm = BookCreationViewModel(service: fakeService);

      // Preenchendo a tela como se fosse um usuário real
      vm.titleController.text = "Duna";
      vm.authorController.text = "Frank Herbert";
      vm.publisherController.text = "Editora Aleph";
      vm.yearController.text = "1965"; // Texto!
      vm.pagesController.text = "680"; // Texto!
      vm.synopsisController.text = "Planeta deserto...";
      vm.descriptionController.text = "Livro incrível, cuidando muito bem!";

      // Preenchendo os Dropdowns e Radios com as opções em Português
      vm.genre = "Ficção científica";
      vm.language = "Português";
      vm.status = "Disponível";
      vm.condition = "Muito bom";

      // Disparando a função do botão (agora retorna o ID em vez de bool)
      final createdId = await vm.submit(
        "http://minhacapa.com/duna.jpg",
        "user_999",
      );

      // 👇 Verificações corrigidas!
      expect(
        createdId,
        isNotNull,
        reason: 'O submit deveria retornar uma String com o ID criado',
      );
      expect(fakeService.lastUserId, "user_999");

      // Valida se os campos de texto foram passados corretamente
      expect(fakeService.lastBody?["title"], "Duna");

      // IMPORTANTÍSSIMO: Valida se a conversão de String para Int funcionou
      expect(fakeService.lastBody?["year"], 1965);
      expect(fakeService.lastBody?["pages"], 680);

      // IMPORTANTÍSSIMO: Valida se a tradução dos Enums funcionou perfeitamente
      expect(fakeService.lastBody?["genre"], "Sci_fic");
      expect(fakeService.lastBody?["language"], "PT-br");
      expect(fakeService.lastBody?["status"], "Available");
      expect(fakeService.lastBody?["condition"], "Used");

      expect(
        fakeService.lastBody?["coverUrl"],
        "http://minhacapa.com/duna.jpg",
      );

      vm.dispose();
    });

    test('submit lida com a falta de URL de capa (null)', () async {
      final fakeService = FakeCreationService();
      final vm = BookCreationViewModel(service: fakeService);

      // Dispara o submit com a foto nula
      final createdId = await vm.submit(null, "user_999");

      // 👇 Verificação corrigida!
      expect(
        createdId,
        isNotNull,
        reason: 'Mesmo sem capa, deveria criar e retornar o ID',
      );

      // O ViewModel deveria enviar uma String vazia "" quando a imagem é nula
      expect(fakeService.lastBody?["coverUrl"], "");

      vm.dispose();
    });
  });
}
