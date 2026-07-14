import 'package:flutter/material.dart';
import 'package:frontend/book_creation/book_creation_screen.dart';
import 'package:frontend/auth/auth_repository.dart';
import 'offer_proposal_view_model.dart';
import 'offer_book_model.dart';

class TradeProposalScreen extends StatefulWidget {
  final String targetAnnouncementId; // ID real do anúncio alvo
  final String targetBookTitle;
  final String targetBookYear;
  final String targetBookLocation;
  final String targetBookImageUrl;

  final TradeProposalViewModel? viewModel;

  const TradeProposalScreen({
    super.key,
    required this.targetAnnouncementId,
    required this.targetBookTitle,
    required this.targetBookYear,
    required this.targetBookLocation,
    required this.targetBookImageUrl,
    this.viewModel,
  });

  @override
  State<TradeProposalScreen> createState() => _TradeProposalScreenState();
}

class _TradeProposalScreenState extends State<TradeProposalScreen> {
  // Instanciando o ViewModel
  late final TradeProposalViewModel _viewModel;
  String? _firstUserId;
  // final TradeProposalViewModel _viewModel = TradeProposalViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? TradeProposalViewModel();

    // Chama o método assíncrono sem colocar 'await' aqui
    _initData();
  }

  // Novo método assíncrono para lidar com o carregamento
  Future<void> _initData() async {
    _firstUserId = AuthRepository.instance.user?.id;

    if (_firstUserId != null) {
      await _viewModel.loadEligibleBooks(_firstUserId!);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFFF8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      // ListenableBuilder escuta o ViewModel e reconstrói a tela quando notificado
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, size: 28),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            "Selecione os livros que você está disposto a\ntrocar por:",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Livro alvo
                        Center(child: _buildTargetBook()),
                        const SizedBox(height: 40),

                        const Text(
                          "Meus livros",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lógica de Renderização Baseada no Estado do ViewModel
                        if (_viewModel.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_viewModel.errorMessage != null)
                          Center(
                            child: Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_viewModel.availableBooks.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildMyBooksGrid(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildSubmitButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetBook() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.targetBookImageUrl,
              height: 180,
              width: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.targetBookTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          widget.targetBookYear,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          widget.targetBookLocation,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMyBooksGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: _viewModel.availableBooks.length,
      itemBuilder: (context, index) {
        final book = _viewModel.availableBooks[index];
        final isSelected = _viewModel.selectedBookIds.contains(book.id);

        return GestureDetector(
          onTap: () => _viewModel.toggleSelection(book.id),
          child: _buildBookCard(book, isSelected),
        );
      },
    );
  }

  Widget _buildBookCard(OfferBookModel book, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 248, 247, 247),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6B528B) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(book.realPhotoUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.publishYear,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      book.location,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B528B)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6B528B)
                              : Colors.black54,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFFFF8F0),
      child: ElevatedButton(
        onPressed: _viewModel.canSubmit && _firstUserId != null
            ? () async {
                final success = await _viewModel.submitProposal(
                  widget.targetAnnouncementId,
                  _firstUserId!,
                );

                if (success && mounted) {
                  // Se a proposta foi criada com sucesso, volta para a tela anterior
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposta enviada com sucesso!'),
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF477259),
          disabledBackgroundColor: Colors.grey[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          "Enviar proposta",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Nenhum livro disponível",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Você precisa ter pelo menos um livro anunciado na sua estante para poder propor uma troca.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookCreationPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Anunciar um livro",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF6B528B,
              ), // Usando a cor roxa do seu app
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
