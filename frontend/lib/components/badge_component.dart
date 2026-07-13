import 'package:flutter/material.dart';

  /// Builds a visual badge to represent the item's condition/status.
  Widget buildBadge(String status, BuildContext context) {
    Color bgColor;
    String label;

    switch (status.toLowerCase()) {
      case 'new':
        // case 'novo':
        bgColor = const Color(0xFF24523C);
        label = 'Novo';
      case 'used':
        // case 'muito bom':
        bgColor = const Color(0xFF416956);
        label = 'Muito bom';
      case 'good':
        // case 'bom':
        bgColor = const Color(0xFFDB8F44);
        label = 'Bom';
      case 'worn':
        // case 'desgastado':
        bgColor = const Color(0xFF7B2518);
        label = 'Desgastado';
      default:
        bgColor = Theme.of(context).colorScheme.primary;
        label = status.isNotEmpty ? status : 'Novo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

