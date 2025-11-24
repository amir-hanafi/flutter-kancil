import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kancil/database/db_helper.dart';

class OutOfStockPage extends StatefulWidget {
  const OutOfStockPage({super.key});

  @override
  State<OutOfStockPage> createState() => _OutOfStockPageState();
}

class _OutOfStockPageState extends State<OutOfStockPage> {
  List<Map<String, dynamic>> _outOfStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadOutOfStockProducts();
  }

  Future<void> _loadOutOfStockProducts() async {
    final allProducts = await DBHelper.getProducts();
    _outOfStockProducts =
        allProducts.where((p) => (p['stock_qty'] ?? 0) <= 0).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Produk Stok Kosong")),
      body: _outOfStockProducts.isEmpty
          ? const Center(child: Text("Semua produk tersedia"))
          : ListView.builder(
              itemCount: _outOfStockProducts.length,
              itemBuilder: (context, index) {
                final product = _outOfStockProducts[index];
                final type = product['is_parent'] == 1
                    ? "Parent"
                    : (product['parent_id'] != null ? "Child" : "Produk Biasa");

                return Card(
                  child: ListTile(
                    leading: product['image'] != null
                        ? Image.file(
                            File(product['image']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(product['name']),
                    subtitle: Text("$type • Stok: ${product['stock_qty']}"),
                  ),
                );
              },
            ),
    );
  }
}
