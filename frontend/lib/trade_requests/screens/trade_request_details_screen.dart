import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import '../services/trade_request_service.dart';
import '../widgets/offer_status_badge.dart';
import '../widgets/offered_books_carousel.dart';
import '../widgets/request_exchange_header.dart';
import '../widgets/trade_request_action_bar.dart';

class TradeRequestDetailsScreen extends StatefulWidget {
  const TradeRequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.service,
  });

  final String requestId;
  final TradeRequestService service;

  @override
  State<TradeRequestDetailsScreen> createState() =>
      _TradeRequestDetailsScreenState();
}

class _TradeRequestDetailsScreenState
    extends State<TradeRequestDetailsScreen> {
  late Future<TradeRequest> _requestFuture;
  TradeRequest? _request;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requestFuture = _loadRequest();
  }

  Future<TradeRequest> _loadRequest() async {
    final request = await widget.service.getRequestById(widget.requestId);
    _request = request;
    return request;
  }

  Future<bool> _confirmAction({required bool accept}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Aceitar proposta?' : 'Recusar proposta?'),
        content: Text(
          accept
              ? 'Os livros envolvidos serão reservados para a troca.'
              : 'A proposta será marcada como recusada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  accept ? const Color(0xFF416956) : const Color(0xFFB11217),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(accept ? 'Aceitar' : 'Recusar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _respond({required bool accept}) async {
    final request = _request;
    if (request == null || _isSubmitting) return;

    final confirmed = await _confirmAction(accept: accept);
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final updated = accept
          ? await widget.service.acceptRequest(request.id)
          : await widget.service.rejectRequest(request.id);

      if (!mounted) return;
      setState(() {
        _request = updated;
        _requestFuture = Future<TradeRequest>.value(updated);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Proposta aceita com sucesso.'
                : 'Proposta recusada com sucesso.',
          ),
        ),
      );
    } on TradeRequestServiceException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível concluir a operação.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6EA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<TradeRequest>(
        future: _requestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _DetailsErrorState(
              onRetry: () {
                setState(() => _requestFuture = _loadRequest());
              },
            );
          }

          final request = _request ?? snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RequestExchangeHeader(request: request),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                        child: Text(
                          'Livros disponíveis',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OfferedBooksCarousel(books: request.offeredBooks),
                      if (!request.isPending)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Status da solicitação',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OfferStatusBadge(
                                status: request.status,
                                expand: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (request.isPending)
                TradeRequestActionBar(
                  isLoading: _isSubmitting,
                  onReject: () => _respond(accept: false),
                  onAccept: () => _respond(accept: true),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 14),
            const Text(
              'Não foi possível carregar esta solicitação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
