import 'package:flutter/material.dart';

class TradeRequestActionBar extends StatelessWidget {
  const TradeRequestActionBar({
    super.key,
    required this.isLoading,
    required this.onReject,
    required this.onAccept,
  });

  final bool isLoading;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 14, 32, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF6EA),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : onReject,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB11217),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text('Recusar proposta'),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF416956),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Aceitar proposta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
