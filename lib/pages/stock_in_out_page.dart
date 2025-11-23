import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';

class StockInOutPage extends StatefulWidget {
  final VoidCallback onSuccess;

  const StockInOutPage({super.key, required this.onSuccess});

  @override
  State<StockInOutPage> createState() => _StockInOutPageState();
}

class _StockInOutPageState extends State<StockInOutPage> {
  List<Map<String, dynamic>> _products = [];

  int? _selectedProductId;
  Map<String, dynamic>? _selectedProduct;

  final TextEditingController _qtyController = TextEditingController();

  String _mode = "in"; // in = masuk, out = keluar
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _products = await DBHelper.getProducts();
    setState(() {});
  }

  void _onProductSelected(int? value) {
    setState(() {
      _selectedProductId = value;
      _selectedProduct =
          _products.firstWhere((p) => p['id'] == value, orElse: () => {});
    });
  }

  Future<void> _processStock() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pilih produk terlebih dahulu.")));
      return;
    }

    if (_qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Masukkan jumlah.")));
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Jumlah tidak valid.")));
      return;
    }

    int currentStock = _selectedProduct!['stock_qty'] ?? 0;
    int parentId = _selectedProduct!['parent_id'] ?? 0;
    bool isParent = _selectedProduct!['is_parent'] == 1;

    setState(() => _loading = true);

    // =========== BARANG MASUK ============
    if (_mode == "in") {
      int newStock = currentStock + qty;

      // jika produk adalah parent → child ikut naik
      if (isParent) {
        int packSize = _selectedProduct!['pack_size'] ?? 0;

        // ambil list child dari parent
        List<Map<String, dynamic>> children =
            await DBHelper.getChildProducts(_selectedProductId!);

        for (var c in children) {
          int childNewStock = c['stock_qty'] + (qty * packSize);
          await DBHelper.updateStock(c['id'], childNewStock);
        }
      }

      await DBHelper.updateStock(_selectedProductId!, newStock);
    }

    // =========== BARANG KELUAR ============
    // BARANG KELUAR
    else {
      if (qty > currentStock) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Stok tidak mencukupi.")));
        return;
      }

      int newStock = currentStock - qty;

      // Jika produk adalah parent → child ikut turun
      if (isParent) {
        int packSize = _selectedProduct!['pack_size'] ?? 1;

        // ambil list child
        List<Map<String, dynamic>> children =
            await DBHelper.getChildProducts(_selectedProductId!);

        for (var c in children) {
          int currentChildStock = c['stock_qty'];
          int newChildStock = currentChildStock - (qty * packSize);

          // jangan negatif
          if (newChildStock < 0) newChildStock = 0;

          await DBHelper.updateStock(c['id'], newChildStock);
        }
      }

      // Jika produk adalah child → sync ke parent
      else if (!isParent && parentId != 0) {
        Map<String, dynamic>? parent = await DBHelper.getProductById(parentId);

        if (parent != null) {
          int packSize = parent['pack_size'] ?? 1;

          // total child yang tersisa
          int totalChildStock = newStock;

          // hitung stok pack parent berdasarkan sisa child
          int newParentStock = totalChildStock ~/ packSize;

          // update stok parent
          await DBHelper.updateStock(parentId, newParentStock);
        }
      }

      await DBHelper.updateStock(_selectedProductId!, newStock);
    }


    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Stok berhasil diperbarui.")));
    
    widget.onSuccess(); // ← pindah ke ListPage (index 0)

  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barang Masuk / Keluar")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PILIH PRODUK
            DropdownButton<int>(
              value: _selectedProductId,
              isExpanded: true,
              hint: const Text("Pilih Produk"),
              items: _products.map((p) {
                return DropdownMenuItem(
                  value: p['id'] as int,
                  child: Text("${p['name']}  (stok: ${p['stock_qty']})"),
                );
              }).toList(),
              onChanged: _onProductSelected,
            ),

            const SizedBox(height: 20),

            // INFO STOK
            if (_selectedProduct != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Stok Sekarang: ${_selectedProduct!['stock_qty']}"),
                  if (_selectedProduct!['is_parent'] == 1)
                    Text("Isi per pack: ${_selectedProduct!['pack_size']}"),
                ],
              ),

            const SizedBox(height: 20),

            // INPUT JUMLAH
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: "Jumlah"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // MODE MASUK / KELUAR
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

            const SizedBox(height: 20),

            // BUTTON SIMPAN
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _processStock,
                    child: const Text("Simpan"),
                  ),
          ],
        ),
      ),
    );
  }
}
