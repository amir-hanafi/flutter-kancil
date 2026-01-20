import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'cart_page.dart';
import 'package:kancil/pages/succes_transaction_page.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cart;
  final int total;

  const PaymentPage({
    super.key,
    required this.cart,
    required this.total,
  });

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

        // Update stok produk utama
        int currentStock = (product['stock_qty'] as num?)?.toInt() ?? 0;
        int newStock = currentStock - item.qty;
        if (newStock < 0) newStock = 0;
        await DBHelper.updateStock(item.productId, newStock);

        // Jika produk adalah parent, update semua child
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

        // Jika produk adalah child, update parent
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

      // Simpan transaksi
      await DBHelper.insertTransaction(widget.total, transactionItems);

      if (!mounted) return;

      // Pindah ke halaman sukses transaksi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SuccessTransactionPage(),
        ),
      );
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
      appBar: AppBar(
        title: const Text("Pembayaran"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // List produk di keranjang
            Expanded(
              child: ListView.builder(
                itemCount: widget.cart.length,
                itemBuilder: (context, index) {
                  final item = widget.cart[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text("Rp ${item.price} x ${item.qty}"),
                    trailing: Text(
                      "Rp ${item.price * item.qty}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // Total
            Text(
              "Total: Rp ${widget.total}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Selesai
            _processing
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _completeTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Selesai",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
