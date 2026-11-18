import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roti_bakar_borneo_flutter/main.dart';

void main() {
  testWidgets('menampilkan halaman masuk', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('Masuk ke Borneo'), findsOneWidget);
    expect(find.text('Akun karyawan'), findsOneWidget);
  });
}
