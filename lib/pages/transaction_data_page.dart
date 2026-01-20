import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kancil/database/db_helper.dart';


class TransactionDataPage extends StatelessWidget {
  const TransactionDataPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Transaksi"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SIMPAN DATA TRANSAKSI
            
            _menuButton(
      text: "Simpan data transaksi (export ke file)",
      onTap: () {
        _showExportTransactionDialog(context);   // ⬅️ masuk ke popup bulan
      },
    ),
    const SizedBox(height: 12),

    _menuButton(
      text: "Restore data transaksi",
      onTap: () {
        _confirmDialog(
          context,
          title: "Restore Transaksi",
          content: "Apakah kamu yakin ingin me-restore data transaksi?",
          onYes: () async {
            Navigator.pop(context);
            await _restoreTransactionFromFile(context);   // ⬅️ restore
          },
        );
      },
    ),
    const SizedBox(height: 12),

    _menuButton(
      text: "Hapus data transaksi",
      color: Colors.red.shade100,
      textColor: Colors.red,
      onTap: () {
        _confirmDialog(
          context,
          title: "Hapus Data Transaksi",
          content: "SEMUA transaksi akan dihapus permanen. Yakin?",
          onYes: () async {
            Navigator.pop(context);
            await _deleteTransactionData(context);       // ⬅️ delete
          },
        );
      },
    ),
          ],
        ),
      ),
    );
  }

  // ================= UI BUTTON =================

  Widget _menuButton({
    required String text,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }

  // ================= POPUP CONFIRM =================

  void _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onYes,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tidak"),
          ),
          ElevatedButton(
            onPressed: onYes,
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showExportTransactionDialog(BuildContext context) async {
  final db = await DBHelper.database();

  final result = await db.rawQuery("""
    SELECT DISTINCT strftime('%Y-%m', date) as ym
    FROM transactions
    ORDER BY ym DESC
  """);

  List<String> months = result.map((e) => e['ym'] as String).toList();
  String? selectedMonth;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Export Data Transaksi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Pilih bulan transaksi"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  hint: const Text("Pilih bulan"),
                  items: months.map((m) {
                    final y = m.split("-")[0];
                    final mo = int.parse(m.split("-")[1]);
                    return DropdownMenuItem(
                      value: m,
                      child: Text("${_monthName(mo)} $y"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedMonth = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tidak"),
              ),
              ElevatedButton(
                onPressed: selectedMonth == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _exportTransactionByMonth(context, selectedMonth!);
                      },
                child: const Text("Ya"),
              ),
            ],
          );
        },
      );
    },
  );
}


  // ================= BACKUP TRANSAKSI =================

  Future<void> _backupTransactionData(BuildContext context) async {
    final db = await DBHelper.database();

    final transactions = await db.query("transactions");
    final transactionItems = await db.query("transaction_items");
    final refunds = await db.query("refunds");

    final Map<String, dynamic> data = {
      "transactions": transactions,
      "transaction_items": transactionItems,
      "refunds": refunds,
    };

    final jsonData = jsonEncode(data);

    // Simpan langsung ke folder Download
    final dir = Directory("/storage/emulated/0/Download");
    final fileName =
        "backup_transactions_${DateTime.now().millisecondsSinceEpoch}.json";
    final file = File("${dir.path}/$fileName");

    await file.writeAsString(jsonData);

    _showSnack(context, "Backup transaksi disimpan di Download/$fileName");
  }

  // ================= DELETE TRANSAKSI =================

  
  String _monthName(int month) {
  const months = [
    "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
  ];
  return months[month];
}
  Future<void> _exportTransactionByMonth(BuildContext context, String ym) async {
  final db = await DBHelper.database();

  final transactions = await db.query(
    "transactions",
    where: "strftime('%Y-%m', date) = ?",
    whereArgs: [ym],
  );

  if (transactions.isEmpty) {
    _showSnack(context, "Tidak ada transaksi di bulan ini");
    return;
  }

  final ids = transactions.map((e) => e['id']).toList();

  final items = await db.query(
    "transaction_items",
    where: "transaction_id IN (${List.filled(ids.length, '?').join(',')})",
    whereArgs: ids,
  );

  final refunds = await db.query(
    "refunds",
    where: "transaction_id IN (${List.filled(ids.length, '?').join(',')})",
    whereArgs: ids,
  );

  final data = {
    "month": ym,
    "transactions": transactions,
    "transaction_items": items,
    "refunds": refunds,
  };

  final file = File("/storage/emulated/0/Download/backup_transaksi_$ym.json");
  await file.writeAsString(jsonEncode(data));

  _showSnack(context, "Backup transaksi bulan $ym berhasil disimpan");
}
  Future<void> _restoreTransactionFromFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null) return;

  final file = File(result.files.single.path!);
  final Map<String, dynamic> data = jsonDecode(await file.readAsString());

  final db = await DBHelper.database();

  await db.transaction((txn) async {
    for (var tx in data['transactions']) {
      await txn.insert("transactions", Map<String, dynamic>.from(tx));
    }
    for (var item in data['transaction_items']) {
      await txn.insert("transaction_items", Map<String, dynamic>.from(item));
    }
    for (var r in data['refunds']) {
      await txn.insert("refunds", Map<String, dynamic>.from(r));
    }
  });

  _showSnack(context, "Restore transaksi berhasil");
}
  Future<void> _deleteTransactionData(BuildContext context) async {
  final db = await DBHelper.database();
  await db.transaction((txn) async {
    await txn.delete("transaction_items");
    await txn.delete("refunds");
    await txn.delete("transactions");
  });

  _showSnack(context, "Semua data transaksi berhasil dihapus");
}


}
