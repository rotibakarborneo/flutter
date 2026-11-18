import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class MiniMetric extends StatelessWidget {
  const MiniMetric({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: BorneoColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: BorneoColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
