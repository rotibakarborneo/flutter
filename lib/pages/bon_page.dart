import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

class BonPage extends StatelessWidget {
  const BonPage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bon'),
      backgroundColor: BorneoColors.background,
    ),
    body: const Center(child: Text('Bon page placeholder')),
  );
}
