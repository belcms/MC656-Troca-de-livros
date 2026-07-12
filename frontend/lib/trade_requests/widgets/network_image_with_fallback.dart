import 'package:flutter/material.dart';

class NetworkImageWithFallback extends StatelessWidget {
  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.backgroundColor = const Color(0xFFE8E8E8),
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: backgroundColor,
        child: url == null || url.isEmpty
            ? _Fallback(icon: fallbackIcon)
            : Image.network(
                url,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _Fallback(icon: fallbackIcon),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        size: 36,
        color: const Color(0xFF777777),
      ),
    );
  }
}
