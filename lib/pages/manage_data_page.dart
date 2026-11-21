import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/network/admin_repository.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key, required this.session});
  final AppSession session;

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _wage = TextEditingController(text: '15000');
  String? _branchId;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _wage.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    final password = _password.text;
    final wage = double.tryParse(_wage.text.trim());

    if (name.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        wage == null ||
        _branchId == null) {
      _showMessage('Semua field wajib diisi.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AdminRepository().addEmployee(
        widget.session,
        name: name,
        username: username,
        password: password,
        branchId: _branchId!,
        wage: wage,
      );
      _name.clear();
      _username.clear();
      _password.clear();
      _showMessage('Akun karyawan berhasil dibuat.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tambah Karyawan'),
      backgroundColor: BorneoColors.background,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('cabang').snapshots(),
          builder: (context, snapshot) {
            final branches = snapshot.data?.docs ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama karyawan'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: 'Contoh: budi, menjadi budi@rbb.app',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(labelText: 'Cabang'),
                  items: branches
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            doc.data()['nama_cabang']?.toString() ?? doc.id,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _branchId = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _wage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif per jam',
                    suffixText: 'Rp',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Buat Akun Karyawan'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
