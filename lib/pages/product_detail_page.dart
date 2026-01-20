import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/edit_product_page.dart';

import 'stock_in_out_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  List<Map<String, dynamic>> childProducts = [];

  // ================= UI HELPERS =================

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  // ================= LIFECYCLE =================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    product = await DBHelper.getProductById(widget.productId);

    if (product != null) {
      childProducts = await DBHelper.getChildProducts(widget.productId);
    } else {
      childProducts = [];
    }

    if (mounted) setState(() {});
  }

  // ================= STOCK SHEET =================

  void _showStockDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StockInOutSheet(
            product: product!,
            onSuccess: () async {
              await loadData();
            },
          ),
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isParent = (product!['is_parent'] ?? 0) == 1;

    // ===== hitung stok child =====
    int totalChildStock = 0;
    for (var c in childProducts) {
      final raw = c['stock_qty'] ?? 0;
      totalChildStock +=
          (raw is num) ? raw.toInt() : int.parse(raw.toString());
    }

    final packSizeRaw = product!['pack_size'] ?? 1;
    final int packSize = (packSizeRaw is num)
        ? packSizeRaw.toInt()
        : int.parse(packSizeRaw.toString());

    final int totalPack =
        isParent ? (packSize > 0 ? (totalChildStock ~/ packSize) : 0) : 0;

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditProductPage(productId: product!['id']),
                  ),
                );

                if (!mounted) return;
                if (result == true) {
                  await loadData();
                }
              } else if (value == 'delete') {
                if (isParent && childProducts.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Hapus child terlebih dahulu sebelum menghapus parent.',
                      ),
                    ),
                  );
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Hapus Produk"),
                    content: const Text("Yakin ingin menghapus produk ini?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Hapus"),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await DBHelper.deleteProduct(product!['id'] as int);
                if (!mounted) return;
                Navigator.pop(context, true);
              } else if (value == 'stock') {
                _showStockDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
              PopupMenuItem(
                value: 'stock',
                child: Text('Masuk / Kurangi Stok'),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // ================= GAMBAR =================
          if (product!['image'] != null &&
              (product!['image'] as String).isNotEmpty) ...[
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

          // ================= CARD FULL =================
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== INFO =====
                      infoRow("Nama Produk:", product!['name'] ?? '-'),
                      infoRow("Harga:", "Rp. ${product!['price'] ?? 0}"),

                      if (isParent) ...[
                        infoRow("Pack Size:", packSize.toString()),
                        infoRow(
                            "Stok Satuan:", totalChildStock.toString()),
                        infoRow("Stok Pack:", totalPack.toString()),
                      ] else ...[
                        finalStockWidget(product!),
                      ],

                      // ===== DESKRIPSI CARD =====
                      if ((product!['description'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: childProducts.isEmpty
                              ? const Center(
                                  child: Text("Belum ada produk satuan."),
                                )
                              : ListView.builder(
                                  itemCount: childProducts.length,
                                  itemBuilder: (context, i) {
                                    final c = childProducts[i];
                                    final rawStock =
                                        c['stock_qty'] ?? 0;
                                    final int cStock =
                                        (rawStock is num)
                                            ? rawStock.toInt()
                                            : int.parse(
                                                rawStock.toString());

                                    return ListTile(
                                      title: Text(c['name'] ?? ''),
                                      subtitle: Text("Stok: $cStock"),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailPage(
                                              productId:
                                                  c['id'] as int,
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
