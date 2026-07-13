import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';

class UploadService {
  final String baseUrl = ApiClient.baseUrl;

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

      var response = await request.send();

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
}
