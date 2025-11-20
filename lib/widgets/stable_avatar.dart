import 'package:flutter/material.dart';

class StableAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const StableAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor = const Color(0xff1BA3A1),
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (imageUrl ?? '').trim();
    
    // Always show initials as fallback
    final fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    if (effectiveUrl.isEmpty) {
      return fallbackAvatar;
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          effectiveUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return fallbackAvatar; // Show initials while loading
          },
          errorBuilder: (context, error, stackTrace) {
            return fallbackAvatar; // Show initials on error
          },
        ),
      ),
    );
  }
}