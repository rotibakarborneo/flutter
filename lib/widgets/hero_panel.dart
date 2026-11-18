import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/utils/printer_helper.dart';
import 'package:flutter/cupertino.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.value,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? value;

  @override
  Widget build(BuildContext context) => Card(
    color: BorneoColors.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, size: 36, color: BorneoColors.gold),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: BorneoColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: BorneoColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: BorneoColors.muted,
                    fontSize: 12,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    value!,
                    style: const TextStyle(
                      color: BorneoColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
