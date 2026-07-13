import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import 'announcement_detail_model.dart';
import 'interest_bottom_bar.dart';
import 'package:frontend/offer/trade_proposal_view.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/components/badge_component.dart';

/// Screen responsible for displaying detailed information about a trade announcement.
///
/// This widget fetches announcement data from the backend and renders it
/// using a structured and user-friendly layout. It handles loading states,
/// error states, and successful data rendering.
///
/// Features:
/// - Fetches data asynchronously using `AnnouncementService`
/// - Displays loading indicator while waiting for data
/// - Handles errors with retry capability
/// - Shows announcement details including:
///     - Book cover image
///     - Title and author
///     - Item condition (badge)
///     - User and trade information
///     - Edition details
///     - Book synopsis
///
/// Navigation:
/// - Includes a back button to return to the previous screen
///
/// UI Structure:
/// - Scrollable layout (`SingleChildScrollView`)
/// - Modular sections for better readability and maintainability
///
/// State Management:
/// - Uses `FutureBuilder` to reactively update UI based on async state
class AnnouncementDetailScreen extends StatefulWidget {
  /// Unique identifier of the announcement to be displayed.
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  /// Future that holds the announcement data retrieved from the API.
  ///
  /// This is initialized in `initState` and reused by the `FutureBuilder`
  /// to manage UI updates.
  late Future<AnnouncementDetail?> _future;
  bool _hasPendingOffer = false;
  bool _isLoadingOfferStatus = true;
  String? meuUsuarioLogadoId;
  bool isLoading = true;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    /// Initiates the API request when the screen is first created.
    _future = AnnouncementService.fetchAnnouncementDetails(
      widget.announcementId,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await UserService.fetchUsers();

    if (mounted) {
      setState(() {
        if (users != null && users.isNotEmpty) {
          meuUsuarioLogadoId = users.first['id'];
        } else {
          meuUsuarioLogadoId = "f3f4e2d6-02b7-44d9-afc0-d9e8341ca2f4";
        }
        isLoading = false; // ID carregado!
      });

      // Agora SIM chamamos a verificação da oferta, pois temos certeza que o ID não é nulo.
      await _checkIfHasOffer();
    }
  }

  Future<void> _checkIfHasOffer() async {
    final hasOffer = await OfferService().checkPendingOffer(
      meuUsuarioLogadoId!, // O ID mockado do usuário logado
      widget.announcementId,
    );

    if (mounted) {
      setState(() {
        _hasPendingOffer = hasOffer;
        _isLoadingOfferStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Ensures content is displayed within safe screen boundaries.
      body: SafeArea(
        child: FutureBuilder<AnnouncementDetail?>(
          future: _future,

          /// Builds UI based on the current state of the async operation.
          builder: (context, snapshot) {
            /// Loading state
            if (snapshot.connectionState == ConnectionState.waiting ||
                isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            /// Error state with retry option
            else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! An error occurred:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    /// Retry button triggers a new API request
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future =
                              AnnouncementService.fetchAnnouncementDetails(
                                widget.announcementId,
                              );
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }
            /// Empty state
            else if (!snapshot.hasData) {
              return const Center(child: Text("No data found."));
            }

            /// Success state
            final data = snapshot.data!;
            final book = data.book;
            final edition = data.edition;

            // final String meuUsuarioLogadoId =
            //     // "cd1be270-d415-4db5-9d6f-c7ca619e69ed";
            //     "f3f4e2d6-02b7-44d9-afc0-d9e8341ca2f4";

            final bool isOwner = data.userId == meuUsuarioLogadoId;

            // Trocamos o retorno direto do ScrollView por uma Column
            return Column(
              children: [
                /// 1. A área rolável do anúncio, envolvida em um Expanded
                /// para ocupar todo o espaço disponível
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),

                    /// Main layout structure
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Back navigation button
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),

                        /// Book cover / announcement image
                        _buildCarousel(
                          data.photos,
                          'https://axiomprint.com/icons/default-squre.jpg',
                        ),
                        // _buildCover(data.realPhotoUrl),
                        const SizedBox(height: 16),

                        /// Title, author, and condition badge
                        _buildHeader(
                          title: book?.title,
                          author: book?.author,
                          condition: data.condition,
                        ),

                        const SizedBox(height: 16),

                        /// User + edition info
                        _buildInfoSection(
                          tradedWith: data.userName,
                          cep: data.userCep,
                          description: data.description,
                          year: edition?.publishYear,
                          publisher: edition?.publisher,
                        ),

                        const SizedBox(height: 16),

                        /// Book synopsis
                        _buildDescription(synopsis: book?.synopsis),
                      ],
                    ),
                  ),
                ),

                /// 2. O seu componente fixado no final da tela
                InterestBottomBar(
                  isOwner: isOwner,
                  isPending: _isLoadingOfferStatus ? false : _hasPendingOffer,
                  onInterestPressed: () {
                    // Passando os dados reais do anúncio para a próxima tela
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TradeProposalScreen(
                          targetAnnouncementId: widget.announcementId,
                          targetBookTitle: book?.title ?? 'Título desconhecido',
                          targetBookYear:
                              edition?.publishYear?.toString() ??
                              'Ano não informado',
                          targetBookLocation:
                              data.userCep ?? 'Localização não informada',
                          targetBookImageUrl:
                              data.realPhotoUrl ?? 'URL_DA_IMAGEM_PADRAO_AQUI',
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  // SECTIONS
  // =========================

  /// Builds the cover image section.
  ///
  /// If a valid URL is provided, it displays the image from the network.
  /// Otherwise, it shows a placeholder image.
  Widget _buildCover(String? url) {
    // Define a URL padrão caso a fornecida seja inválida
    const String fallbackUrl = 'https://axiomprint.com/icons/default-squre.jpg';

    // Verifica se a URL é nula, vazia ou apenas espaços
    final bool isValidUrl =
        url != null && url.trim().isNotEmpty && url.startsWith('http');

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          isValidUrl ? url : fallbackUrl,
          height: 260,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(fallbackUrl, height: 260);
          },
        ),
      ),
    );
  }

  /// Builds a swipeable photo carousel if multiple photos exist,
  /// or a single image/fallback if there's only one or none.
  Widget _buildCarousel(List<String>? photos, String? fallbackPhoto) {
    const String defaultPlaceholder =
        'https://axiomprint.com/icons/default-squre.jpg';

    // 1. Monta uma lista segura de fotos válidas
    List<String> validPhotos = [];
    if (photos != null && photos.isNotEmpty) {
      validPhotos = photos.where((url) => url.trim().isNotEmpty).toList();
    }

    // 2. Se a lista de fotos veio vazia, tenta usar a foto antiga de fallback
    if (validPhotos.isEmpty &&
        fallbackPhoto != null &&
        fallbackPhoto.trim().isNotEmpty) {
      validPhotos = [fallbackPhoto];
    }

    // 3. Se tudo falhar, usa a imagem cinza de placeholder
    if (validPhotos.isEmpty) {
      validPhotos = [defaultPlaceholder];
    }

    const double carouselHeight = 350.0;
    // Se tiver só 1 foto, não precisamos do carrossel, apenas da imagem
    if (validPhotos.length == 1) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            validPhotos.first,
            height: carouselHeight,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Image.network(defaultPlaceholder, height: 260),
          ),
        ),
      );
    }

    // Se tiver mais de 1 foto, constrói o Carrossel (PageView)
    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            itemCount: validPhotos.length,
            onPageChanged: (index) {
              // Quando o usuário arrastar pro lado, atualizamos a bolinha acesa
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                ), // Espaçinho entre as fotos
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    validPhotos[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.network(defaultPlaceholder, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(validPhotos.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentImageIndex == index ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentImageIndex == index
                    ? const Color(0xFF416956) // Cor ativa (verde do seu app)
                    : Colors.grey.shade300, // Cor inativa
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Builds the header section containing:
  /// - Book title
  /// - Author
  /// - Condition badge (aligned to the right)
  Widget _buildHeader({String? title, String? author, String? condition}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              author ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),

        if (condition != null)
          Align(
            alignment: Alignment.centerRight,
            child: buildBadge(condition, context),
          ),
      ],
    );
  }

  /// Builds the section with user and edition information.
  ///
  /// Includes:
  /// - User name (trade owner)
  /// - CEP (postal code)
  /// - Description
  /// - Publication year
  /// - Publisher
  Widget _buildInfoSection({
    String? tradedWith,
    String? cep,
    String? description,
    int? year,
    String? publisher,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Anunciado por", tradedWith),
        _infoRow("CEP", cep),
        _infoRow("Descrição", description),

        const Divider(height: 24),

        _infoRow("Ano de publicação", year?.toString()),
        _infoRow("Editora", publisher),
      ],
    );
  }

  /// Builds the description section (e.g., book synopsis).
  Widget _buildDescription({String? synopsis}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [if (synopsis != null) _textBlock("Sinopse", synopsis)],
    );
  }

  // =========================
  // SMALL BUILDERS
  // =========================

  /// Builds a labeled row for displaying key-value information.
  ///
  /// If the value is null, the row is not rendered.
  Widget _infoRow(String label, String? value) {
    if (value == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// Builds a text block with a title and content.
  Widget _textBlock(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // /// Builds a visual badge to represent the item's condition/status.
  // Widget _buildBadge(String status) {
  //   Color bgColor;
  //   String label;

  //   switch (status.toLowerCase()) {
  //     case 'new':
  //       // case 'novo':
  //       bgColor = const Color(0xFF24523C);
  //       label = 'Novo';
  //     case 'used':
  //       // case 'muito bom':
  //       bgColor = const Color(0xFF416956);
  //       label = 'Muito bom';
  //     case 'good':
  //       // case 'bom':
  //       bgColor = const Color(0xFFDB8F44);
  //       label = 'Bom';
  //     case 'worn':
  //       // case 'desgastado':
  //       bgColor = const Color(0xFF7B2518);
  //       label = 'Desgastado';
  //     default:
  //       bgColor = Theme.of(context).colorScheme.primary;
  //       label = status.isNotEmpty ? status : 'Novo';
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //     decoration: BoxDecoration(
  //       // color: Colors.green[700],
  //       color: bgColor,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       label,
  //       style: const TextStyle(color: Colors.white, fontSize: 12),
  //     ),
  //   );
  // }
}
