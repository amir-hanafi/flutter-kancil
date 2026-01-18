import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';

class StockInOutSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSuccess;

  const StockInOutSheet({
    super.key,
    required this.product,
    required this.onSuccess,
  });

  @override
  State<StockInOutSheet> createState() => _StockInOutSheetState();
}

class _StockInOutSheetState extends State<StockInOutSheet> {
  late Map<String, dynamic> _product;

  final TextEditingController _qtyController = TextEditingController();

  String _mode = "in"; // in = masuk, out = keluar
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _processStock() async {
    if (_qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah.")),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah tidak valid.")),
      );
      return;
    }

    int productId = _product['id'];
    int currentStock = _product['stock_qty'] ?? 0;
    int parentId = _product['parent_id'] ?? 0;
    bool isParent = _product['is_parent'] == 1;

    setState(() => _loading = true);

    // ================= BARANG MASUK =================
    if (_mode == "in") {
      int newStock = currentStock + qty;

      // jika produk adalah parent → child ikut naik
      if (isParent) {
        int packSize = _product['pack_size'] ?? 0;

        List<Map<String, dynamic>> children =
            await DBHelper.getChildProducts(productId);

        for (var c in children) {
          int childNewStock = c['stock_qty'] + (qty * packSize);
          await DBHelper.updateStock(c['id'], childNewStock);
        }
      }

      await DBHelper.updateStock(productId, newStock);
    }

    // ================= BARANG KELUAR =================
    else {
      if (qty > currentStock) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok tidak mencukupi.")),
        );
        return;
      }

      int newStock = currentStock - qty;

      // Jika produk adalah parent → child ikut turun
      if (isParent) {
        int packSize = _product['pack_size'] ?? 1;

        List<Map<String, dynamic>> children =
            await DBHelper.getChildProducts(productId);

        for (var c in children) {
          int currentChildStock = c['stock_qty'];
          int newChildStock = currentChildStock - (qty * packSize);
          if (newChildStock < 0) newChildStock = 0;

          await DBHelper.updateStock(c['id'], newChildStock);
        }
      }

      // Jika produk adalah child → sync ke parent
      else if (!isParent && parentId != 0) {
        Map<String, dynamic>? parent =
            await DBHelper.getProductById(parentId);

        if (parent != null) {
          int packSize = parent['pack_size'] ?? 1;
          int totalChildStock = newStock;
          int newParentStock = totalChildStock ~/ packSize;

          await DBHelper.updateStock(parentId, newParentStock);
        }
      }

      await DBHelper.updateStock(productId, newStock);
    }

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Stok berhasil diperbarui.")),
    );

    widget.onSuccess();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Text(
              "Stok: ${_product['name']}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text("Stok sekarang: ${_product['stock_qty']}"),
            if (_product['is_parent'] == 1)
              Text("Isi per pack: ${_product['pack_size']}"),

            const SizedBox(height: 20),

            // JUMLAH
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(
                labelText: "Jumlah",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            // MODE
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("Barang Masuk"),
                    value: "in",
                    groupValue: _mode,
                    onChanged: (v) => setState(() => _mode = v.toString()),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("Barang Keluar"),
                    value: "out",
                    groupValue: _mode,
                    onChanged: (v) => setState(() => _mode = v.toString()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // SIMPAN
            SizedBox(
              width: double.infinity,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _processStock,
                      child: const Text("Simpan"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
