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
      appBar: AppBar(title: Text(product!['name'] ?? 'Detail Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar produk jika ada
            if (product!['image'] != null && (product!['image'] as String).isNotEmpty)
              Center(
                child: Image.file(
                  File(product!['image'] as String),
                  height: 150,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
              ),

            const SizedBox(height: 16),

            Text("Nama: ${product!['name'] ?? '-'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("Harga: Rp ${product!['price'] ?? 0}"),
            const SizedBox(height: 6),

            if ((product!['description'] ?? '').toString().isNotEmpty)
              Text("Deskripsi: ${product!['description']}"),
            const SizedBox(height: 12),

            if (isParent) ...[
              Text("Pack Size: $packSize"),
              const SizedBox(height: 6),
              Text("Stok Satuan (total child): $totalChildStock"),
              Text("Stok Pack: $totalPack"),
            ] else ...[
              finalStockWidget(product!),
            ],

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductPage(productId: product!['id']),
                      ),
                    );

                    if (!mounted) return;

                    if (result == true) {
                      await loadData(); // refresh ulang data dari database
                    }
                  },

                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Hapus"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    // Jika parent dan punya child => minta konfirmasi + blok jika masih ada child
                    if (isParent && childProducts.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hapus child terlebih dahulu sebelum menghapus parent.')),
                      );
                      return;
                    }
                    await DBHelper.deleteProduct(product!['id'] as int);
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (isParent) ...[
              const Text("Produk Satuan:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: childProducts.isEmpty
                    ? const Text("Belum ada produk satuan untuk pack ini.")
                    : ListView.builder(
                        itemCount: childProducts.length,
                        itemBuilder: (context, i) {
                          final c = childProducts[i];
                          final rawStock = c['stock_qty'] ?? 0;
                          final int cStock = (rawStock is num) ? rawStock.toInt() : int.parse(rawStock.toString());
                          return ListTile(
                            title: Text(c['name'] ?? ''),
                            subtitle: Text("Stok: $cStock"),
                            onTap: () {
                              // buka detail child (opsional)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(productId: c['id'] as int),
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
    );
  }

  Widget finalStockWidget(Map<String, dynamic> product) {
    final raw = product['stock_qty'] ?? 0;
    final int stock = (raw is num) ? raw.toInt() : int.parse(raw.toString());
    final parentId = product['parent_id'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Stok Satuan: $stock"),
        const SizedBox(height: 6),
        if (parentId != null)
          FutureBuilder<Map<String, dynamic>?>(
            future: DBHelper.getProductById(parentId as int),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final p = snap.data!;
              return Text("Parent: ${p['name'] ?? '-'} (pack size: ${p['pack_size'] ?? '-'})");
            },
          ),
      ],
    );
  }
}
