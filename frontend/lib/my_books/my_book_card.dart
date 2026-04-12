import 'package:flutter/material.dart';

class MyBookCard extends StatelessWidget {
  final String title;
  final int publishYear;
  final String photo;
  final String status;
  final VoidCallback? onEdit;

  const MyBookCard({
    super.key,
    required this.title,
    required this.publishYear,
    required this.photo,
    required this.status,
    this.onEdit,
  });

  Color _statusColor(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'disponivel':
        return const Color(0xFF24523C);
      case 'reserved':
      case 'reservado':
        return const Color(0xFF723A00);
      case 'traded':
      case 'trocado':
        return const Color(0xFF7B2518);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel() {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponivel';
      case 'reserved':
        return 'Reservado';
      case 'traded':
        return 'Trocado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                //aspectRatio: 1 / 1.6,
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photo,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1F1F1),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '$publishYear',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
