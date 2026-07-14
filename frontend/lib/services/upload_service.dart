import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';
import 'dart:convert';

class UploadService {
  final String baseUrl = ApiClient.baseUrl;

  final http.Client client;
  UploadService({http.Client? client}) : client = client ?? http.Client();

  Future<bool> uploadBookPhoto(String announcementId, XFile imageFile) async {
    try {
      var uri = Uri.parse(
        '$baseUrl/api/v1/announcements/$announcementId/photos',
      );

      var request = http.MultipartRequest('POST', uri);

      // 1. Descobrimos a extensão da imagem (jpg, jpeg, png...)
      String extension = imageFile.path.split('.').last.toLowerCase();

      // 2. Definimos o subtipo (o image_picker do iOS costuma usar jpg ou png)
      String subType = (extension == 'png') ? 'png' : 'jpeg';

      // 3. Criamos o arquivo anexando o rótulo oficial (MediaType)
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', subType), // <--- A MÁGICA ESTÁ AQUI
      );

      request.files.add(multipartFile);

      // var response = await request.send();
      var response = await client.send(request);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Falha no upload. Status: ${response.statusCode}');
        print('Motivo do erro (Backend): $responseBody');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return false;
    }
  }

  Future<bool> deleteBookPhoto(String announcementId, String photoUrl) async {
    try {
      var uri = Uri.parse(
        '$baseUrl/api/v1/announcements/$announcementId/photos',
      );

      // Enviamos a URL no corpo (body) da requisição DELETE
      var response = await http.delete(
        uri,
        headers: {
          // 'Content-Type': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
          // 'Authorization': 'Bearer SEU_TOKEN_AQUI', // Adicione se a rota for protegida
        },
        body: jsonEncode({
          'photo_url': photoUrl,
        }),
      );

      // O backend pode retornar 200 (OK) ou 204 (No Content)
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Falha ao deletar a foto. Status: ${response.statusCode}');
        print('Motivo do erro (Backend): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro de conexão ao tentar deletar a imagem: $e');
      return false;
    }
  }
}
