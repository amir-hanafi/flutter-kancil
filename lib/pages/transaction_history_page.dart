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
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);

    final db = await DBHelper.database();
    final txs = await db.query(
      "transactions",
      orderBy: "id DESC",
    );

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
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index]; // ← benar!

                    return ListTile(
                      title: Text("Transaksi #${tx['id']}"),
                      subtitle: Text(tx['date']),
                      trailing: Text("Rp ${tx['total']}"),
                      onTap: () async {
                        final db = await DBHelper.database();

                        // ambil item transaksi dari database
                        final items = await db.query(
                          "transaction_items",
                          where: "transaction_id = ?",
                          whereArgs: [tx['id']],
                        );

                        // kirim transaksi + item sekaligus
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailPage(
                              transaction: {
                                ...tx,
                                "items": items,   // ← tambahkan daftar item
                              },
                            ),
                          ),
                        );
                      },

                    );
                  },
                ),
    );
  }
}
