import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/scan_barcode_page.dart';
import 'package:kancil/pages/transaction_history_page.dart';
import 'payment_page.dart';
import 'qr_settings.dart';

class CartItem {
  final int productId;
  final String name;
  final int price;
  int qty;
  final String type; // parent / child / none

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.type,
  });
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cart = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _allProducts = await DBHelper.getProducts();
    _filteredProducts = List.from(_allProducts);
    setState(() {});
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts
          .where((p) =>
              p['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void addToCart(Map<String, dynamic> product) {
    final existing = cart.indexWhere((e) => e.productId == product['id']);
    int stockQty = product['stock_qty'] ?? 0; // ambil stok dari DB

    if (existing != -1) {
      // cek apakah stok cukup sebelum tambah qty
      if (cart[existing].qty + 1 > stockQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stok tidak mencukupi. Stok tersedia: $stockQty")),
        );
        return;
      }
      setState(() => cart[existing].qty++);
    } else {
      if (stockQty < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok habis, tidak bisa ditambahkan.")),
        );
        return;
      }
      setState(() {
        cart.add(
          CartItem(
            productId: product['id'],
            name: product['name'],
            price: product['price'],
            qty: 1,
            type: product['is_parent'] == 1
                ? "parent"
                : (product['parent_id'] != null ? "child" : "none"),
          ),
        );
      });
    }
  }

  void increaseQty(int index) async {
    // ambil stok terbaru dari DB
    final product = await DBHelper.getProductById(cart[index].productId);
    int stockQty = product?['stock_qty'] ?? 0;

    if (cart[index].qty + 1 > stockQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stok tidak mencukupi. Stok tersedia: $stockQty")),
      );
      return;
    }

    setState(() => cart[index].qty++);
  }

  void decreaseQty(int index) {
    if (cart[index].qty > 1) {
      setState(() => cart[index].qty--);
    } else {
      setState(() => cart.removeAt(index));
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );

    if (result != null && result is String) {
      final product = await DBHelper.getProductByBarcode(result);
      if (product != null) {
        addToCart(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk tidak terdaftar.")),
        );
      }
    }
  }

  int get totalPrice => cart.fold(0, (sum, item) => sum + (item.price * item.qty));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // icon bisa diganti sesuai selera
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Menu"),
                  content: const Text("Pilih aksi:"),
                  actions: [
                    TextButton(
                      onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionHistoryPage(
                          ),
                        ),
                      );
                    },
                      child: const Text("Riwayat Transaksi"),
                    ),

                  ],
                ),
              );
            },
          ),
        ],
        ),
      body: Column(
        children: [
          // SEARCH + SCAN
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Cari Produk",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                )
              ],
            ),
          ),

          // LIST PRODUK UNTUK TAMBAH KE KERANJANG
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final p = _filteredProducts[index];
                final type = p['is_parent'] == 1
                    ? "Parent"
                    : (p['parent_id'] != null ? "Child" : "Produk Biasa");
                return Card(
                  child: ListTile(
                    title: Text(p['name']),
                    subtitle: Text("Rp ${p['price']} • $type"),
                    trailing: ElevatedButton(
                      onPressed: () => addToCart(p),
                      child: const Text("Tambah"),
                    ),
                  ),
                );
              },
            ),
          ),

          // CART
          // CART
if (cart.isNotEmpty)
  SizedBox(
    height: 260, // ✅ tinggi tetap (silakan sesuaikan: 220 - 320 dll)
    child: Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          // LIST CART (SCROLL)
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      "Rp ${item.price} • ${item.type} • Qty: ${item.qty}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => decreaseQty(index),
                          icon: const Icon(Icons.remove),
                        ),
                        Text("${item.qty}"),
                        IconButton(
                          onPressed: () => increaseQty(index),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // TOTAL
          Text(
            "Total: Rp $totalPrice",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(
                      cart: cart,
                      total: totalPrice,
                    ),
                  ),
                );
              },
              child: const Text("Selesaikan Transaksi"),
            ),
          ),
        ],
      ),
    ),
  ),

        ],
      ),
    );
  }
}
