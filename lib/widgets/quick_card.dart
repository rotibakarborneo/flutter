import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class QuickCard extends StatelessWidget {
  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BorneoColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: accent),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: BorneoColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BorneoColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
