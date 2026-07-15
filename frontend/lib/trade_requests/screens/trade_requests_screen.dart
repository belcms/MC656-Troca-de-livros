import 'package:flutter/material.dart';

import '../models/trade_request.dart';
import '../services/api_trade_request_service.dart';
import '../services/trade_request_service.dart';
import '../widgets/trade_request_card.dart';
import 'trade_request_details_screen.dart';

class TradeRequestsScreen extends StatefulWidget {
  const TradeRequestsScreen({super.key, this.service});

  final TradeRequestService? service;

  @override
  State<TradeRequestsScreen> createState() => _TradeRequestsScreenState();
}

class _TradeRequestsScreenState extends State<TradeRequestsScreen> {
  late final TradeRequestService _service;
  late Future<List<TradeRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ApiTradeRequestService();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = _service.getReceivedRequests();
  }

  Future<void> _refresh() async {
    setState(_loadRequests);
    await _requestsFuture;
  }

  Future<void> _openDetails(TradeRequest request) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            TradeRequestDetailsScreen(requestId: request.id, service: _service),
      ),
    );

    if (mounted) {
      setState(_loadRequests);
    }
  }

  @override
  void dispose() {
    if (widget.service == null && _service is ApiTradeRequestService) {
      _service.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Text(
                'Solicitações de troca',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TradeRequest>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: _errorMessage(snapshot.error),
                      onRetry: () => setState(_loadRequests),
                    );
                  }

                  final requests = snapshot.data ?? const <TradeRequest>[];
                  if (requests.isEmpty) {
                    return const _EmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 3,
                        thickness: 3,
                        color: Color(0xFFFFF6EA),
                      ),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return TradeRequestCard(
                          request: request,
                          onTap: () => _openDetails(request),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is TradeRequestServiceException) {
      return error.message;
    }
    return 'Não foi possível carregar as solicitações.';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 64, color: Color(0xFF777777)),
            SizedBox(height: 16),
            Text(
              'Você ainda não recebeu solicitações de troca.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
            Text(message, textAlign: TextAlign.center),
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
