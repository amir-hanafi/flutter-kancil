// lib/pages/other.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/edit_profile_page.dart';
import 'package:kancil/pages/product_data_page.dart';


class OtherPage extends StatefulWidget {
  const OtherPage({super.key});

  @override
  State<OtherPage> createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  Map<String, dynamic>? store;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    store = await DBHelper.getStoreProfile();
    setState(() {});
  }

  Widget _infoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.edit, size: 12,),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );

                if (res == true) {
                  _loadStore(); // fungsi refresh profil di OtherPage
                }
              },
            ),

          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value.isEmpty ? "-" : value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = store?['name'] ?? "";
    final address = store?['address'] ?? "";
    final phone = store?['phone'] ?? "";
    final logo = store?['logo'];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            // HEADER
            Container(
              height: 120,
              color: Colors.cyanAccent,
            ),

            const SizedBox(height: 20),

            // FOTO TOKO
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: ClipOval(
                child: logo != null && logo.toString().isNotEmpty
                    ? Image.file(File(logo), fit: BoxFit.cover)
                    : const Icon(Icons.store, size: 60, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _infoBox("Nama toko", name),
                  const SizedBox(height: 14),
                  _infoBox("Alamat toko", address),
                  const SizedBox(height: 14),
                  _infoBox("Nomor telepon", phone),

                  const SizedBox(height: 24),
                  const Divider(),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Pengaturan",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),

                  const SizedBox(height: 12),

                  InkWell(
                  onTap: () {
                    // Navigasi ke halaman product_data.dart
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductDataPage(), // pastikan nama class sesuai
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("Data produk"),
                  ),
                ),


                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("Data transaksi"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
