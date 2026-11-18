import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    color: BorneoColors.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: BorneoColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: BorneoColors.muted),
      ),
    ),
  );
}
