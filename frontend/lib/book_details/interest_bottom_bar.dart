import 'package:flutter/material.dart';

class InterestBottomBar extends StatelessWidget {
  final bool isOwner;
  final bool isPending; // Novo estado adicionado
  final VoidCallback onInterestPressed;

  const InterestBottomBar({
    super.key,
    required this.isOwner,
    this.isPending = false,
    required this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1. Define o texto do botão com base no estado atual
    String buttonText = 'Tenho Interesse';
    if (isPending) {
      buttonText = 'Proposta já enviada';
    }

    // 2. Define se o botão deve estar bloqueado
    final bool isDisabled = isOwner || isPending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onInterestPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF416956),
            disabledBackgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
