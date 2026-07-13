import 'dart:convert';
import 'package:frontend/offer/offer_book_model.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/offer/offer_book_model.dart';
import 'api_client.dart';

class OfferService {
  // Ajuste para o IP local da sua máquina ou URL de produção
  final String baseUrl = ApiClient.baseUrl;

  /// Busca os livros do usuário disponíveis para troca
  Future<List<OfferBookModel>> fetchEligibleBooks(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/offers/eligible-items?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OfferBookModel.fromJson(json)).toList();
    } else {
      // Lança uma exceção para que a ViewModel capture o erro
      throw Exception(
        "Erro ao carregar os livros. Código: ${response.statusCode}",
      );
    }
  }

  /// Envia a proposta de troca para o backend
  Future<bool> createOffer({
    required String userId,
    required String targetAnnouncementId,
    required List<String> offeredBookIds,
  }) async {
    // Monta o payload de acordo com o Schema Pydantic que criamos no backend
    final Map<String, dynamic> payload = {
      "userId": userId,
      "targetAnnouncementId": targetAnnouncementId,
      "offeredAnnouncements": offeredBookIds
          .map((id) => {"offeredAnnouncementId": id})
          .toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/offers/create-offer'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      // Vamos tentar ler a mensagem exata que o FastAPI mandou no "detail"
      try {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('detail')) {
          // Lança a mensagem real do backend para a ViewModel exibir na tela
          throw Exception(errorData['detail']);
        }
      } catch (e) {
        // Se der ruim ao ler o JSON, cai no erro genérico
      }
      
      throw Exception("Falha ao criar proposta. Código: ${response.statusCode}");
    }
  }

  Future<bool> checkPendingOffer(String userId, String announcementId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/offers/check-pending?user_id=$userId&target_announcement_id=$announcementId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasPendingOffer'] ?? false;
      }
      return false;
    } catch (e) {
      print("Erro ao checar proposta pendente: $e");
      return false; // Em caso de erro de rede, liberamos o botão por padrão
    }
  }
}

