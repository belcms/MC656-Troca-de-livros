import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/upload_service.dart'; // Ajuste o caminho
import 'dart:typed_data';
import 'dart:io';

void main() {
  group('UploadService', () {
    test(
      'deleteBookPhoto deve retornar true quando API retornar 200',
      () async {
        // 1. Criamos um "Servidor Falso" que sempre responde 200 OK
        final mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, contains('/photos'));
          expect(request.headers['Content-Type'], contains('application/json'));

          return http.Response('{"message": "Deletado com sucesso"}', 200);
        });

        // 2. Injetamos o servidor falso no nosso service
        final service = UploadService(client: mockClient);

        // 3. Executamos a função
        final result = await service.deleteBookPhoto(
          'ann-123',
          'http://minhafoto.com',
        );

        // 4. Verificamos se deu tudo certo
        expect(result, isTrue);
      },
    );

    test(
      'deleteBookPhoto deve retornar false quando API der erro (ex: 405 ou 500)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"detail": "Method Not Allowed"}', 405);
        });

        final service = UploadService(client: mockClient);
        final result = await service.deleteBookPhoto(
          'ann-123',
          'http://minhafoto.com',
        );

        expect(result, isFalse);
      },
    );

    test('uploadBookPhoto deve retornar true com multipart correto', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request is http.MultipartRequest, isTrue);
        return http.Response('{"message": "Upload ok"}', 201);
      });

      final service = UploadService(client: mockClient);

      // 👇 MUDANÇA AQUI: Cria um arquivo de verdade no disco só pro teste
      final tempFile = File('foto_falsa.png');
      await tempFile.writeAsBytes([0, 1, 2]); // Escreve bytes reais

      final fakeImage = XFile(tempFile.path);

      final result = await service.uploadBookPhoto('ann-123', fakeImage);

      expect(result, isTrue);

      // 👇 Limpa a "sujeira" apagando o arquivo depois de testar
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}
