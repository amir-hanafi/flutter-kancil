// Ganti import qr_flutter -> tidak perlu lagi
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kancil/database/db_helper.dart';
import 'cart_page.dart';
import 'qr_settings.dart';
import 'package:flutter/foundation.dart';


class PaymentPage extends StatefulWidget {
  final List<CartItem> cart;
  final int total;

  const PaymentPage({super.key, required this.cart, required this.total});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _processing = false;

  Future<void> _completeTransaction() async {
  setState(() => _processing = true);

  List<Map<String, dynamic>> transactionItems = [];

  for (var item in widget.cart) {
    final product = await DBHelper.getProductById(item.productId);
    if (product == null) continue;

    transactionItems.add({
      "productId": item.productId,
      "name": item.name,
      "price": item.price,
      "qty": item.qty,
      "type": item.type,
    });

    int currentStock = product['stock_qty'] ?? 0;
    int newStock = currentStock - item.qty;
    if (newStock < 0) newStock = 0;
    await DBHelper.updateStock(item.productId, newStock);

    // parent–child sync
    if (product['is_parent'] == 1) {
      int packSize = product['pack_size'] ?? 1;
      List<Map<String, dynamic>> children = await DBHelper.getChildProducts(item.productId);
      for (var c in children) {
        int childNewStock = c['stock_qty'] - (item.qty * packSize);
        if (childNewStock < 0) childNewStock = 0;
        await DBHelper.updateStock(c['id'], childNewStock);
      }
    }

    if (product['parent_id'] != null) {
      final parent = await DBHelper.getProductById(product['parent_id']);
      if (parent != null) {
        int packSize = parent['pack_size'] ?? 1;
        List<Map<String, dynamic>> siblings = await DBHelper.getChildProducts(parent['id']);
        int minChildStock = siblings.map((s) => s['stock_qty']).reduce((a, b) => a < b ? a : b);
        int newParentStock = minChildStock ~/ packSize;
        await DBHelper.updateStock(parent['id'], newParentStock);
      }
    }
  }

  // Simpan transaksi ke DB
  await DBHelper.insertTransaction(widget.total, transactionItems);

  setState(() => _processing = false);

  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi selesai!")));

  Navigator.popUntil(context, (route) => route.isFirst);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.cart.length,
                itemBuilder: (context, index) {
                  final item = widget.cart[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text("Rp ${item.price} x ${item.qty}"),
                    trailing: Text("Rp ${item.price * item.qty}"),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              "Total: Rp ${widget.total}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("Scan QR berikut untuk membayar:"),
            const SizedBox(height: 10),
            // Tampilkan gambar QR dari assets
            FutureBuilder<String?>(
              future: QRSettings.getQRPath(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("QR belum diatur");
                }

                final path = snapshot.data!;
                return kIsWeb
                    ? Image.network(path, width: 200, height: 200)
                    : Image.file(File(path), width: 200, height: 200);
              },
            ),
            const SizedBox(height: 20),
            _processing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _completeTransaction,
                    child: const Text("Selesai"),
                  ),
          ],
        ),
      ),
    );
  }
}
