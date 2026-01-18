// file: lib/pages/product_detail_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  List<Map<String, dynamic>> childProducts = [];

  Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, textAlign: TextAlign.right),
      ],
    ),
  );
}


  Widget finalStockWidget(Map product) {
  final rawStock = product['stock_qty'] ?? 0;
  final int stock = (rawStock is num)
      ? rawStock.toInt()
      : int.tryParse(rawStock.toString()) ?? 0;

  return infoRow("Stok", stock.toString());
}

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    product = await DBHelper.getProductById(widget.productId);
    // jika product null, childProducts tetap kosong
    if (product != null) {
      childProducts = await DBHelper.getChildProducts(widget.productId);
    } else {
      childProducts = [];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isParent = (product!['is_parent'] ?? 0) == 1;

    // Hitung stok total child (hanya untuk parent)
    int totalChildStock = 0;
    for (var c in childProducts) {
      // pastikan konversi aman ke int
      final raw = c['stock_qty'] ?? 0;
      totalChildStock += (raw is num) ? raw.toInt() : int.parse(raw.toString());
    }

    // packSize: pastikan int dan bukan null/num
    final packSizeRaw = product!['pack_size'] ?? 1;
    final int packSize = (packSizeRaw is num) ? packSizeRaw.toInt() : int.parse(packSizeRaw.toString());

    final int totalPack = isParent ? (packSize > 0 ? (totalChildStock ~/ packSize) : 0) : 0;

  

    return Scaffold(
      appBar: AppBar(
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductPage(productId: product!['id']),
            ),
          );

          if (!mounted) return;
          if (result == true) {
            await loadData();
          }

        } else if (value == 'delete') {
          if (isParent && childProducts.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hapus child terlebih dahulu sebelum menghapus parent.')),
            );
            return;
          }

          await DBHelper.deleteProduct(product!['id'] as int);
          if (!mounted) return;
          Navigator.pop(context, true);
        }
      },

      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Hapus'),
        ),
      ],
    )
  ],
),

      body: Column(
  children: [

    // ================= Gambar =================
    if (product!['image'] != null && (product!['image'] as String).isNotEmpty) ...[
      const SizedBox(height: 8),
      Center(
        child: Image.file(
          File(product!['image'] as String),
          height: 350,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, size: 80),
        ),
      ),
      const SizedBox(height: 8),
    ],

    // ================= CARD FULL HEIGHT =================
    Expanded(
      child: SizedBox(
        width: double.infinity,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ===== INFO PRODUK =====
                infoRow("Nama Produk:", product!['name'] ?? '-'),
                infoRow("Harga:", "Rp. ${product!['price'] ?? 0}"),

                if (isParent) ...[
                  infoRow("Pack Size:", packSize.toString()),
                  infoRow("Stok Satuan:", totalChildStock.toString()),
                  infoRow("Stok Pack:", totalPack.toString()),
                ] else ...[
                  finalStockWidget(product!),
                ],

                if ((product!['description'] ?? '').toString().isNotEmpty) ...[
  const SizedBox(height: 10),

  Card(
    elevation: 1,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          product!['description'],
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
    ),
  ),
],



                // ===== PRODUK SATUAN =====
                if (isParent) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      "Produk Satuan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                  Expanded(
                    child: childProducts.isEmpty
                        ? const Center(child: Text("Belum ada produk satuan."))
                        : ListView.builder(
                            itemCount: childProducts.length,
                            itemBuilder: (context, i) {
                              final c = childProducts[i];
                              final rawStock = c['stock_qty'] ?? 0;
                              final int cStock = (rawStock is num)
                                  ? rawStock.toInt()
                                  : int.parse(rawStock.toString());

                              return ListTile(
                                title: Text(c['name'] ?? ''),
                                subtitle: Text("Stok: $cStock"),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        productId: c['id'] as int,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  ],
),

    );
  }

  

}
