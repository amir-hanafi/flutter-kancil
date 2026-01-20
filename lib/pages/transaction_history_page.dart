import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final db = await DBHelper.database();
    final txs = await db.query("transactions", orderBy: "id DESC");

    setState(() {
      _transactions = txs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text("Belum ada transaksi"))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final bool isRefund = (tx['is_refund'] ?? 0) == 1;
                    final bool isFromRefund = tx['refund_from'] != null;

                    String title;
                    if (isRefund && isFromRefund) {
                      title = "Refund #${tx['id']} (dari #${tx['refund_from']})";
                    } else if (isRefund) {
                      title = "Transaksi #${tx['id']} (REFUND)";
                    } else {
                      title = "Transaksi #${tx['id']}";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration:
                                (!isFromRefund && isRefund) ? TextDecoration.lineThrough : null,
                            color: (!isFromRefund && isRefund) ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(tx['date']),
                        trailing: isRefund
                            ? const Text(
                                "REFUND",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text("Rp ${tx['total']}"),
                        onTap: isFromRefund
                            ? null
                            : () async {
                                final db = await DBHelper.database();
                                final items = await db.query(
                                  "transaction_items",
                                  where: "transaction_id = ?",
                                  whereArgs: [tx['id']],
                                );

                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailPage(
                                      transaction: {
                                        ...tx,
                                        "items": items,
                                      },
                                    ),
                                  ),
                                );

                                if (res == true) {
                                  _loadAll();
                                }
                              },
                      ),
                    );
                  },
                ),
    );
  }
}
