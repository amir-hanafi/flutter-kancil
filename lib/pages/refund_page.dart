import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';

class RefundPage extends StatefulWidget { 
  final int transactionId;

  const RefundPage({super.key, required this.transactionId});

  @override
  State<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  List<Map<String, dynamic>> items = [];
  Map<int, int> refundQty = {};
  List<Map<String, dynamic>> refundItems = [];
  String reason = "rusak"; // rusak | batal
  bool loading = true;

  int refundTotal = 0;

  int getRefundTotal() {
    int total = 0;
    for (var item in refundItems) {
      total += (item['price'] as num).toInt() * (item['qty'] as num).toInt();
    }
    return total;
  }


  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final raw = await DBHelper.getTransactionItems(widget.transactionId);

    items = raw.map((e) {
      return {
        ...e,
        "refund_qty": 0,
      };
    }).toList();

    setState(() => loading = false);
  }


  Future<void> _processRefund() async {
  List<Map<String, dynamic>> refundItems = [];
  List<Map<String, dynamic>> remainingItems = [];

  // ================= LOOP ITEM =================
  for (var item in items) {
    int refundQty = (item['refund_qty'] ?? 0);
    int originalQty = (item['qty'] as num).toInt();
    int leftQty = originalQty - refundQty;

    final productId = (item['product_id'] as num).toInt();
    final price = (item['price'] as num).toInt();

    // ===== refund items (hanya untuk stok & validasi) =====
    if (refundQty > 0) {
      refundItems.add({
        "productId": productId,
        "name": item['name'],
        "qty": refundQty,
        "price": price,
      });

      // ========== STOK ==========
      if (reason == "batal") {
        final product = await DBHelper.getProductById(productId);
        if (product != null) {
          int currentStock = (product['stock_qty'] ?? 0);
          await DBHelper.updateStock(productId, currentStock + refundQty);
        }
      }
    }

    // ===== remaining items (INI yang jadi transaksi baru) =====
    if (leftQty > 0) {
      remainingItems.add({
        "productId": productId,
        "name": item['name'],
        "qty": leftQty,
        "price": price,
        "type": item['type'],
      });
    }
  }

  if (refundItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pilih minimal 1 barang untuk refund")),
    );
    return;
  }

  // ================= HITUNG TOTAL BARU =================
  int newTotal = 0;
  for (var item in remainingItems) {
    newTotal += (item['price'] as int) * (item['qty'] as int);
  }

  // ================= TANDAI TRANSAKSI LAMA =================
  await DBHelper.markTransactionRefund(widget.transactionId);

  // ================= BUAT TRANSAKSI BARU (SISA) =================
  await DBHelper.insertRefundTransaction(
    widget.transactionId,
    newTotal,
    remainingItems,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Refund berhasil diproses")),
  );

  Navigator.pop(context, true);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Refund Transaksi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Barang:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ...items.map((e) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e['name']),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (e['refund_qty'] > 0) {
                                  setState(() => e['refund_qty']--);
                                }
                              },
                            ),
                            Text("${e['refund_qty']}"),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (e['refund_qty'] < e['qty']) {
                                  setState(() => e['refund_qty']++);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    );
                  }),


                  const SizedBox(height: 12),
                  Text(
                    "Total refund: Rp $refundTotal",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  const Text("Konfirmasi refund",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: reason,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Alasan refund",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "rusak",
                        child: Text("Barang rusak (stok tidak kembali)"),
                      ),
                      DropdownMenuItem(
                        value: "batal",
                        child: Text("Tidak jadi dibeli (stok dikembalikan)"),
                      ),
                    ],
                    onChanged: (v) => setState(() => reason = v!),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Konfirmasi refund"),
                            content: const Text("Yakin ingin melakukan refund transaksi ini?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Ya, refund"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _processRefund();
                        }
                      },
                      child: const Text("Selesaikan refund"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
