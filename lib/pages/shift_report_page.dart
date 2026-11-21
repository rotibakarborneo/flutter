import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/network/employee_repository.dart';

class ShiftReportPage extends StatefulWidget {
  const ShiftReportPage({super.key, required this.session});
  final AppSession session;

  @override
  State<ShiftReportPage> createState() => _ShiftReportPageState();
}

class _ShiftReportPageState extends State<ShiftReportPage> {
  final _delivered = TextEditingController();
  final _leftover = TextEditingController();
  final _damaged = TextEditingController();
  final _expense = TextEditingController();
  final _deposit = TextEditingController();
  final _float = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _delivered,
      _leftover,
      _damaged,
      _expense,
      _deposit,
      _float,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  double _double(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  Future<void> _submit() async {
    try {
      await EmployeeRepository.live().saveReport(
        widget.session,
        delivered: _int(_delivered),
        leftover: _int(_leftover),
        damaged: _int(_damaged),
        expense: _double(_expense),
        deposit: _double(_deposit),
        floatCash: _double(_float),
        note: _note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan shift berhasil dikirim')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laporan Shift')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_delivered, 'Roti diantar'),
        _field(_leftover, 'Roti sisa'),
        _field(_damaged, 'Roti rusak / bonus'),
        _field(_expense, 'Pengeluaran', number: true),
        _field(_deposit, 'Setor uang', number: true),
        _field(_float, 'Sisa modal', number: true),
        _field(_note, 'Catatan', number: true, multiline: true),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: BorneoColors.red,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Kirim Laporan Shift'),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool multiline = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: multiline
          ? TextInputType.multiline
          : (number ? TextInputType.number : TextInputType.number),
      maxLines: multiline ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: BorneoColors.card,
      ),
    ),
  );
}
