import 'package:flutter/material.dart';

class InterestBottomBar extends StatelessWidget {
  final bool isOwner;
  final bool isPending; // Novo estado adicionado
  final VoidCallback onInterestPressed;

  const InterestBottomBar({
    super.key,
    required this.isOwner,
    this.isPending = false, // Valor padrão como false para não quebrar telas antigas
    required this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
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
          // O botão fica cinza/desabilitado se passarmos null
          onPressed: isDisabled ? null : onInterestPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}