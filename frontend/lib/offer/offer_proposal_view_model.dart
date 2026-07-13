import 'package:flutter/material.dart';
import 'offer_book_model.dart';
import 'package:frontend/services/offer_service.dart'; // Importando o Service

class TradeProposalViewModel extends ChangeNotifier {
  // Instância do Service que fará o trabalho pesado de rede
  final OfferService _offerService;

  // Permite injetar um service mockado para testes unitários depois
  TradeProposalViewModel({OfferService? offerService}) 
      : _offerService = offerService ?? OfferService();

  // Estados da tela
  bool isLoading = false;
  bool isSubmitting = false; // Novo estado para o botão de envio
  String? errorMessage;
  
  // Dados
  List<OfferBookModel> availableBooks = [];
  final Set<String> selectedBookIds = {};

  // Validação do botão
  bool get canSubmit => selectedBookIds.isNotEmpty && !isSubmitting;

  /// Busca os livros delegando para o Service
  Future<void> loadEligibleBooks(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); 

    try {
      // Chama o Service em vez de fazer o http.get aqui
      availableBooks = await _offerService.fetchEligibleBooks(userId);
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      isLoading = false;
      notifyListeners(); 
    }
  }

  /// Adiciona ou remove um livro da seleção
  void toggleSelection(String bookId) {
    if (selectedBookIds.contains(bookId)) {
      selectedBookIds.remove(bookId);
    } else {
      selectedBookIds.add(bookId);
    }
    notifyListeners(); 
  }

  /// Método para enviar a proposta delegando para o Service
  Future<bool> submitProposal(String targetAnnouncementId, String userId) async {
    if (!canSubmit) return false;

    isSubmitting = true;
    errorMessage = null;
    notifyListeners(); // Avisa a View para mostrar um loading no botão, se quiser

    try {
      final success = await _offerService.createOffer(
        userId: userId,
        targetAnnouncementId: targetAnnouncementId,
        offeredBookIds: selectedBookIds.toList(),
      );
      
      return success; // Retorna true para a View saber que deu certo e fechar a tela
    } catch (e) {
      errorMessage = "Erro ao enviar proposta: ${e.toString().replaceAll("Exception: ", "")}";
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}