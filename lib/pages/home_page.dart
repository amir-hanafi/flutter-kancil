import 'package:flutter/material.dart';
import 'package:kancil/pages/list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda"),
      ),

      body: Column(
        children: [

          // ====== "SEARCH BAR" PALSU (BUTTON) ======
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.assignment, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      "Lihat produk...",
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ====== ISI BERANDA (SCROLL) ======
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Produk terlaris bulan ini",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("Area grafik / banner")),
                  ),

                  const SizedBox(height: 50),
                  const Divider(),
                  const SizedBox(height: 30),

                  const Text(
                    "Produk ditambahkan / dikeluarkan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("Area konten beranda")),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Stok Produk yang kosong",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("Area konten beranda")),
                  ),

                  // 👉 nanti kalau kamu mau tambah banyak widget, tinggal tambah di sini
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
