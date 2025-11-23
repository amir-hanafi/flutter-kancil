import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DBHelper.getProducts();
    setState(() {
      products = data;
      isLoading = false;
    });
  }

  Future<void> _delete(int id) async {
    await DBHelper.deleteProduct(id);
    loadProducts();
  }

  Future<void> _goToAddPage() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );

    if (refresh == true) loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Produk")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("Belum ada produk"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (_, index) {
                    final p = products[index];

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: p["image"] != null
                            ? Image.file(
                                File(p["image"]),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),

                        title: Text(p["name"]),
                        subtitle: Text("Rp ${p['price']}"),

                        // ============================
                        //   ON TAP → BUKA DETAIL
                        // ============================
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(productId: p["id"]),
                            ),
                          );

                          if (result == true) {
                            loadProducts(); // refresh list
                          }
                        },

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(p["id"]),
                        ),
                      ),
                    );
                    
                  },
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
