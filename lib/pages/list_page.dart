import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/out_of_stock_page.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';  

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DBHelper.getProducts();
    setState(() {
      _allProducts = data;
      _filteredProducts = List.from(_allProducts); // untuk search
      isLoading = false;
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts
          .where((p) => p['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
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
      appBar: AppBar(
        title: const Text("Daftar Produk"),
        actions: [
            IconButton(
              icon: const Icon(Icons.warning_amber), // icon yang mau ditampilkan
              onPressed: () {
                // aksi saat icon ditekan, misal pindah halaman
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OutOfStockPage(), // ganti dengan halaman tujuan
                  ),
                );
              }, // optional, muncul saat hover/long press
            ),
          ],
        
        ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Cari Produk",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text("Belum ada produk"))
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (_, index) {
                            final p = _filteredProducts[index];

                            return Card(
                              margin: const EdgeInsets.all(8),
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
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailPage(productId: p["id"]),
                                    ),
                                  );

                                  if (result == true) {
                                    loadProducts();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
