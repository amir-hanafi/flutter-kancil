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

  try {
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

      int currentStock = (product['stock_qty'] as num?)?.toInt() ?? 0;
      int newStock = currentStock - item.qty;
      if (newStock < 0) newStock = 0;
      await DBHelper.updateStock(item.productId, newStock);

      // parent
      if (product['is_parent'] == 1) {
        int packSize = (product['pack_size'] as num?)?.toInt() ?? 1;
        List<Map<String, dynamic>> children =
            await DBHelper.getChildProducts(item.productId);

        for (var c in children) {
          int childStock = (c['stock_qty'] as num?)?.toInt() ?? 0;
          int childNewStock = childStock - (item.qty * packSize);
          if (childNewStock < 0) childNewStock = 0;
          await DBHelper.updateStock(c['id'], childNewStock);
        }
      }

      // child → parent
      if (product['parent_id'] != null) {
        final parent = await DBHelper.getProductById(product['parent_id']);
        if (parent != null) {
          int packSize = (parent['pack_size'] as num?)?.toInt() ?? 1;
          List<Map<String, dynamic>> siblings =
              await DBHelper.getChildProducts(parent['id']);

          int minChildStock = siblings
              .map((s) => (s['stock_qty'] as num?)?.toInt() ?? 0)
              .reduce((a, b) => a < b ? a : b);

          int newParentStock = minChildStock ~/ packSize;
          await DBHelper.updateStock(parent['id'], newParentStock);
        }
      }
    }

    await DBHelper.insertTransaction(widget.total, transactionItems);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Transaksi selesai!")));

    Navigator.popUntil(context, (route) => route.isFirst);
  } catch (e, s) {
    debugPrint("PAYMENT ERROR: $e");
    debugPrint("$s");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi error: $e")),
      );
      setState(() => _processing = false);
    }
  }
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
