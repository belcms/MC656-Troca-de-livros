import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import 'announcement_detail_model.dart';

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

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends State<AnnouncementDetailScreen> {

  /// Future that holds the announcement data retrieved from the API.
  ///
  /// This is initialized in `initState` and reused by the `FutureBuilder`
  /// to manage UI updates.
  late Future<AnnouncementDetail?> _future;

  @override
  void initState() {
    super.initState();

    /// Initiates the API request when the screen is first created.
    _future =
        AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE3D8),

      /// Ensures content is displayed within safe screen boundaries.
      body: SafeArea(
        child: FutureBuilder<AnnouncementDetail?>(
          future: _future,

          /// Builds UI based on the current state of the async operation.
          builder: (context, snapshot) {

            /// Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            /// Error state with retry option
            else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! An error occurred:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    /// Retry button triggers a new API request
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = AnnouncementService.fetchAnnouncementDetails(widget.announcementId);
                        });
                      },
                      child: const Text('Try Again'),
                    )
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

            return SingleChildScrollView(
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
                  _buildCover(data.realPhotoUrl),
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
                  _buildDescription(
                    synopsis: book?.synopsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 🎯 SECTIONS
  // =========================

  /// Builds the cover image section.
  ///
  /// If a valid URL is provided, it displays the image from the network.
  /// Otherwise, it shows a placeholder container.
  Widget _buildCover(String? url) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null
            ? Image.network(url, height: 260)
            : Container(
                height: 260,
                width: 160,
                color: Colors.grey[300],
              ),
      ),
    );
  }

  /// Builds the header section containing:
  /// - Book title
  /// - Author
  /// - Condition badge (aligned to the right)
  Widget _buildHeader({
    String? title,
    String? author,
    String? condition,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              author ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),

        if (condition != null)
          Align(
            alignment: Alignment.centerRight,
            child: _buildBadge(condition),
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
        _infoRow("Traded with", tradedWith),
        _infoRow("CEP", cep),
        _infoRow("Description", description),

        const Divider(height: 24),

        _infoRow("Publication year", year?.toString()),
        _infoRow("Publisher", publisher),
      ],
    );
  }

  /// Builds the description section (e.g., book synopsis).
  Widget _buildDescription({
    String? synopsis,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (synopsis != null) _textBlock("Synopsis", synopsis),
      ],
    );
  }

  // =========================
  // 🧩 SMALL BUILDERS
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  /// Builds a visual badge to represent the item's condition/status.
  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}