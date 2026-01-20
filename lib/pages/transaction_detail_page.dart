import 'package:flutter/material.dart';
import 'package:kancil/pages/refund_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    List items = transaction['items'] ?? [];

    final bool isRefund = (transaction['is_refund'] ?? 0) == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        actions: [
          if (!isRefund)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == "refund") {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RefundPage(
                        transactionId: (transaction['id'] as num).toInt(),
                      ),
                    ),
                  );

                  // ✅ kalau refund sukses → balik ke history
                  if (res == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "refund",
                  child: Text("Refund transaksi"),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transaksi #${transaction['id']}"),
            const SizedBox(height: 6),

            if (isRefund)
              const Text(
                "STATUS: Hasil Refund",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 10),

            Text(
              "Tanggal: ${transaction['date']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            const Text(
              "Barang:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final int price = (item['price'] as num).toInt();
                  final int qty = (item['qty'] as num).toInt();

                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text("Rp $price x $qty"),
                    trailing: Text(
                      "Rp ${price * qty}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            Text(
              "Total: Rp ${transaction['total']}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
