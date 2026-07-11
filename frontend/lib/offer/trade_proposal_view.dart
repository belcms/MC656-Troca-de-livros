// import 'package:flutter/material.dart';

// // ==========================================
// // MODELOS MOCKADOS (Substitua pelos seus)
// // ==========================================
// class DummyTargetBook {
//   final String title;
//   final String year;
//   final String location;
//   final String imageUrl;

//   DummyTargetBook({
//     required this.title,
//     required this.year,
//     required this.location,
//     required this.imageUrl,
//   });
// }

// class DummyMyBook {
//   final String id;
//   final String title;
//   final String year;
//   final String location;
//   final String imageUrl;

//   DummyMyBook({
//     required this.id,
//     required this.title,
//     required this.year,
//     required this.location,
//     required this.imageUrl,
//   });
// }

// // ==========================================
// // TELA PRINCIPAL
// // ==========================================
// class TradeProposalScreen extends StatefulWidget {
//   // Parâmetros que a tela vai receber
//   final String targetBookTitle;
//   final String targetBookYear;
//   final String targetBookLocation;
//   final String targetBookImageUrl;

//   const TradeProposalScreen({
//     super.key,
//     required this.targetBookTitle,
//     required this.targetBookYear,
//     required this.targetBookLocation,
//     required this.targetBookImageUrl,
//   });

//   @override
//   State<TradeProposalScreen> createState() => _TradeProposalScreenState();
// }

// class _TradeProposalScreenState extends State<TradeProposalScreen> {
//   // Estado para controlar quais livros foram selecionados (IDs)
//   final Set<String> _selectedBookIds = {};

//   final List<DummyMyBook> myBooks = [
//     DummyMyBook(
//       id: "1",
//       title: "A espada do destino",
//       year: "2012",
//       location: "Santos - SP",
//       imageUrl: "https://m.media-amazon.com/images/I/71AUx-lHOEL._SY522_.jpg",
//     ),
//     DummyMyBook(
//       id: "2",
//       title: "The power of habit",
//       year: "2014",
//       location: "Santos - SP",
//       imageUrl: "https://m.media-amazon.com/images/I/716i0dfXcgL._SL1500_.jpg",
//     ),
//     DummyMyBook(
//       id: "3",
//       title: "1984",
//       year: "2009",
//       location: "Santos - SP",
//       imageUrl: "https://m.media-amazon.com/images/I/819js3EQwbL._AC_UF1000,1000_QL80_.jpg",
//     ),
//   ];

//   void _toggleSelection(String bookId) {
//     setState(() {
//       if (_selectedBookIds.contains(bookId)) {
//         _selectedBookIds.remove(bookId);
//       } else {
//         _selectedBookIds.add(bookId);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Cor de fundo bege claro baseada no layout
//     const Color backgroundColor = Color(0xFFFFF8F0);

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ÁREA DE CONTEÚDO ROLÁVEL
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 16),

//                     // Botão de voltar customizado
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: const Icon(Icons.arrow_back, size: 28),
//                     ),

//                     const SizedBox(height: 24),

//                     // Título Superior
//                     const Center(
//                       child: Text(
//                         "Selecione os livros que você está disposto a\ntrocar por:",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // Livro Alvo Centralizado
//                     Center(
//                       child: _buildTargetBook(
//                         title: widget.targetBookTitle,
//                         year: widget.targetBookYear,
//                         location: widget.targetBookLocation,
//                         imageUrl: widget.targetBookImageUrl,
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     // Título da Seção
//                     const Text(
//                       "Meus livros",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Grid de Livros do Usuário
//                     _buildMyBooksGrid(),

//                     const SizedBox(height: 24), // Espaçamento extra no final do scroll
//                   ],
//                 ),
//               ),
//             ),

//             // BOTÃO FIXO NA BASE
//             _buildSubmitButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==========================================
//   // WIDGETS AUXILIARES
//   // ==========================================

// Widget _buildTargetBook({
//     required String title,
//     required String year,
//     required String location,
//     required String imageUrl,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             // ... (mantenha o estilo)
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Image.network(
//               imageUrl,
//               height: 180,
//               width: 120,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         const SizedBox(height: 4),
//         Text(year, style: const TextStyle(color: Colors.grey, fontSize: 14)),
//         Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
//       ],
//     );
//   }

//   Widget _buildMyBooksGrid() {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 0.58, // Ajuste para caber imagem + texto no card
//       ),
//       itemCount: myBooks.length,
//       itemBuilder: (context, index) {
//         final book = myBooks[index];
//         final isSelected = _selectedBookIds.contains(book.id);

//         return GestureDetector(
//           onTap: () => _toggleSelection(book.id),
//           child: _buildBookCard(book, isSelected),
//         );
//       },
//     );
//   }

//   Widget _buildBookCard(DummyMyBook book, bool isSelected) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFD3D3D3), // Fundo cinza do card
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected ? const Color(0xFF6B528B) : Colors.transparent,
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Imagem do livro preenchendo o topo do card
//           Expanded(
//             child: ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: Image.network(
//                   book.imageUrl,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           // Informações e Checkbox
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   book.title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   book.year,
//                   style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       book.location,
//                       style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                     ),
//                     // Custom Checkbox
//                     Container(
//                       width: 22,
//                       height: 22,
//                       decoration: BoxDecoration(
//                         color: isSelected ? const Color(0xFF6B528B) : Colors.transparent,
//                         border: Border.all(
//                           color: isSelected ? const Color(0xFF6B528B) : Colors.black54,
//                           width: 2,
//                         ),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: isSelected
//                           ? const Icon(Icons.check, size: 16, color: Colors.white)
//                           : null,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     final bool hasSelection = _selectedBookIds.isNotEmpty;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       color: const Color(0xFFFFF8F0),
//       child: ElevatedButton(
//         // Habilita o botão apenas se houver 1 ou mais livros selecionados
//         onPressed: hasSelection
//             ? () {
//                 debugPrint("Livros oferecidos: $_selectedBookIds");
//                 // TODO: Chamar o endpoint do backend /api/v1/offers
//               }
//             : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF477259), // Verde escuro do layout
//           disabledBackgroundColor: Colors.grey[400],
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         child: const Text(
//           "Enviar proposta",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'offer_proposal_view_model.dart';
import 'offer_book_model.dart';

class TradeProposalScreen extends StatefulWidget {
  final String targetAnnouncementId; // ID real do anúncio alvo
  final String targetBookTitle;
  final String targetBookYear;
  final String targetBookLocation;
  final String targetBookImageUrl;

  const TradeProposalScreen({
    super.key,
    required this.targetAnnouncementId,
    required this.targetBookTitle,
    required this.targetBookYear,
    required this.targetBookLocation,
    required this.targetBookImageUrl,
  });

  @override
  State<TradeProposalScreen> createState() => _TradeProposalScreenState();
}

class _TradeProposalScreenState extends State<TradeProposalScreen> {
  // Instanciando o ViewModel
  final TradeProposalViewModel _viewModel = TradeProposalViewModel();

  @override
  void initState() {
    super.initState();
    // Agora chamamos o novo nome do método da ViewModel
    _viewModel.loadEligibleBooks("cd1be270-d415-4db5-9d6f-c7ca619e69ed");
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
                          const Center(
                            child: Text(
                              "Você não tem livros disponíveis para troca.",
                            ),
                          ) // Empty State!
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
        color: const Color(0xFFD3D3D3),
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
        onPressed: _viewModel.canSubmit
            ? () async {
                final success = await _viewModel.submitProposal(
                  widget.targetAnnouncementId,
                  "cd1be270-d415-4db5-9d6f-c7ca619e69ed",
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
}
