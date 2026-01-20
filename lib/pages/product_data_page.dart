import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kancil/database/db_helper.dart';


class ProductDataPage extends StatelessWidget {
  const ProductDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Produk"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // BACKUP
            _menuButton(
              text: "Backup database produk (export ke file)",
              onTap: () {
                _confirmDialog(
                  context,
                  title: "Backup Database",
                  content: "Apakah kamu yakin ingin membackup database produk?",
                  onYes: () async {
                    Navigator.pop(context);
                    await _backupDatabase(context);
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // RESTORE
            _menuButton(
              text: "Restore database produk",
              onTap: () {
                _confirmDialog(
                  context,
                  title: "Restore Database",
                  content: "Restore akan menambahkan data dari file backup. Lanjutkan?",
                  onYes: () async {
                    Navigator.pop(context);
                    await _restoreDatabase(context);
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // RESET STOCK
            _menuButton(
              text: "Reset semua stok produk",
              onTap: () {
                _confirmDialog(
                  context,
                  title: "Reset Stok",
                  content: "Semua stok produk akan di set ke 0. Lanjutkan?",
                  onYes: () async {
                    Navigator.pop(context);
                    await DBHelper.database().then((db) {
                      db.update("products", {"stock_qty": 0});
                    });
                    _showSnack(context, "Semua stok berhasil di-reset");
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // DELETE ALL PRODUCTS
            _menuButton(
              text: "Hapus semua database produk",
              color: Colors.red.shade100,
              textColor: Colors.red,
              onTap: () {
                _confirmDialog(
                  context,
                  title: "Hapus Database",
                  content: "SEMUA produk akan dihapus permanen. Yakin?",
                  onYes: () async {
                    Navigator.pop(context);
                    await DBHelper.database().then((db) {
                      db.delete("products");
                    });
                    _showSnack(context, "Semua produk berhasil dihapus");
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI WIDGET =================

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

  // ================= BACKUP =================

  Future<void> _backupDatabase(BuildContext context) async {
    final db = await DBHelper.database();
    final products = await db.query("products");

    final jsonData = jsonEncode(products);

    // Simpan ke folder Download
    final dir = Directory("/storage/emulated/0/Download");
    final fileName = "backup_products_${DateTime.now().millisecondsSinceEpoch}.json";
    final file = File("${dir.path}/$fileName");

    await file.writeAsString(jsonData);

    _showSnack(context, "Backup berhasil disimpan di Download/$fileName");
  }

  // ================= RESTORE =================

  Future<void> _restoreDatabase(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final List data = jsonDecode(jsonStr);

    final db = await DBHelper.database();

    await db.transaction((txn) async {
      for (var item in data) {
        await txn.insert("products", Map<String, dynamic>.from(item));
      }
    });

    _showSnack(context, "Restore database produk berhasil");
  }
}
