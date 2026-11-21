import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/network/employee_repository.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key, required this.session});
  final AppSession session;

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final Map<String, int> _cart = {};
  final _products = const [
    ('Roti Cokelat', 10000),
    ('Roti Keju', 12000),
    ('Roti Srikaya', 10000),
    ('Roti Pisang', 11000),
  ];

  int get total => _cart.entries.fold(
    0,
    (sum, item) =>
        sum +
        item.value *
            _products.firstWhere((product) => product.$1 == item.key).$2,
  );

  String rupiah(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => '.')}';

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final items = _cart.entries.map((entry) {
      final product = _products.firstWhere((item) => item.$1 == entry.key);
      return {'nama': entry.key, 'qty': entry.value, 'harga': product.$2};
    }).toList();

    try {
      final id = await EmployeeRepository.live().saveCashier(
        widget.session,
        items,
        'TUNAI',
      );
      if (!mounted) return;
      setState(_cart.clear);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Transaksi berhasil: $id')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kasir')),
    body: Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final qty = _cart[product.$1] ?? 0;
              return Container(
                decoration: BoxDecoration(
                  color: BorneoColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BorneoColors.stroke),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bakery_dining,
                      size: 54,
                      color: BorneoColors.gold,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.$1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      rupiah(product.$2),
                      style: const TextStyle(color: BorneoColors.muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: qty == 0
                              ? null
                              : () => setState(() {
                                  final next = qty - 1;
                                  if (next == 0) {
                                    _cart.remove(product.$1);
                                  } else {
                                    _cart[product.$1] = next;
                                  }
                                }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _cart[product.$1] = qty + 1),
                          icon: const Icon(
                            Icons.add_circle,
                            color: BorneoColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: BorneoColors.card,
            border: Border(top: BorderSide(color: BorneoColors.stroke)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(color: BorneoColors.muted),
                    ),
                    Text(
                      rupiah(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _cart.isEmpty ? null : _checkout,
                style: FilledButton.styleFrom(
                  backgroundColor: BorneoColors.gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Bayar Sekarang'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
