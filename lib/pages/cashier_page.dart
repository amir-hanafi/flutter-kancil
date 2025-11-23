import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'scan_barcode_page.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<Map<String, dynamic>> _cart = [];
  int totalPrice = 0;
  bool _isScanning = false;

  Future<void> scanBarcode() async {
    setState(() => _isScanning = true);

    final code = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanBarcodePage(),
      ),
    );

    if (code != null && code is String) {
      final product = await DBHelper.getProductByBarcode(code);

      if (product != null) {
        setState(() {
          _cart.add(product);
          totalPrice += product["price"] as int;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk tidak ditemukan di database")),
        );
      }
    }

    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kasir")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : scanBarcode,
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return ListTile(
                  title: Text(item["name"]),
                  subtitle: Text(item["description"]),
                  trailing: Text("Rp ${item["price"]}"),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Text(
              "Total: Rp $totalPrice",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
