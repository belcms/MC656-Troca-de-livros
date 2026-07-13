import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

class UploadService {

  final String baseUrl = ApiClient.baseUrl;

  Future<bool> uploadBookPhoto(String announcementId, XFile imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/ap1/v1/announcements/$announcementId/photos');
      
      // Criamos a requisição Multipart
      var request = http.MultipartRequest('POST', uri);
      
      // Lemos o arquivo pelo caminho e anexamos na requisição com a chave 'file'
      var multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(multipartFile);

      // Enviamos a requisição
      var response = await request.send();

      if (response.statusCode == 201) {
        return true; // Sucesso!
      } else {
        print('Falha no upload. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return false;
    }
  }
}