import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {Key? key}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      title,
      style: const TextStyle(
        color: BorneoColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
