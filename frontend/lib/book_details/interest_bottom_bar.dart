import 'package:flutter/material.dart';

class InterestBottomBar extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onInterestPressed;

  const InterestBottomBar({
    super.key,
    required this.isOwner,
    required this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Evita padding extra na parte superior do botão
        child: ElevatedButton(
          // O botão fica cinza/desabilitado automaticamente se passar null
          onPressed: isOwner ? null : onInterestPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Tenho Interesse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}