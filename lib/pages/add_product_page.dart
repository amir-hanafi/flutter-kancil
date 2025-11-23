import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kancil/database/db_helper.dart';
import 'scan_barcode_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  String _productType = "none";


  final TextEditingController _packSizeController = TextEditingController();
  final TextEditingController _stockQtyController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  List<Map<String, dynamic>> _allProducts = [];
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _allProducts = await DBHelper.getProducts();
    setState(() {});
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, harga dan gambar wajib diisi.')),
      );
      return;
    }

    if (_productType == "parent" && _packSizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pack size wajib untuk parent')),
      );
      return;
    }

    if (_productType == "child" && _selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih parent untuk produk child')),
      );
      return;
    }

    final data = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': int.parse(_priceController.text),
      'barcode': _barcodeController.text,
      'image': _imageFile!.path,

      'is_parent': _productType == "parent" ? 1 : 0,
      'parent_id': _productType == "child" ? _selectedParentId : null,
      'pack_size': _productType == "parent"
          ? int.parse(_packSizeController.text)
          : null,
      'stock_qty': _productType == "child"
          ? int.parse(_stockQtyController.text)
          : 0,
    };


    await DBHelper.insertProduct(data);

    Navigator.pop(context, true);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔻 DROPDOWN PARENT
            // PILIH PRODUK PARENT / CHILD
            const Text("Tipe Produk:"),
              DropdownButton<String>(
                value: _productType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "none", child: Text("Produk Biasa")),
                  DropdownMenuItem(value: "parent", child: Text("Produk Parent (Pack)")),
                  DropdownMenuItem(value: "child", child: Text("Produk Child (Satuan)")),
                ],
                onChanged: (v) {
                  setState(() {
                    _productType = v!;
                    _selectedParentId = null;
                  });
                },
              ),


            const SizedBox(height: 10),

            // JIKA CHILD → PILIH PARENT
            if (_productType == "child")
              DropdownButton<int>(
                value: _selectedParentId,
                isExpanded: true,
                hint: const Text("Pilih Parent Produk Pack"),
                items: _allProducts
                    .where((p) => p['is_parent'] == 1)
                    .map((p) {
                  return DropdownMenuItem<int>(
                    value: p['id'],
                    child: Text(p['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedParentId = value);
                },
              ),

            const SizedBox(height: 10),

            // PACK SIZE (UNTUK PARENT)

            if (_productType == "parent")
              TextField(
                controller: _packSizeController,
                decoration: const InputDecoration(labelText: "Isi Pack (pack size)"),
                keyboardType: TextInputType.number,
              ),

            if (_productType == "child")
              TextField(
                controller: _stockQtyController,
                decoration: const InputDecoration(labelText: "Stok Awal"),
                keyboardType: TextInputType.number,
              ),


            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _descController,
              decoration:
                  const InputDecoration(labelText: 'Deskripsi (opsional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _scanBarcode,
                  child: const Text("Scan"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pilih Gambar'),
            ),
            const SizedBox(height: 10),

            if (_imageFile != null)
              Center(
                child: kIsWeb
                    ? Image.network(_imageFile!.path, height: 150)
                    : Image.file(File(_imageFile!.path), height: 150),
              ),

            const SizedBox(height: 20),

            Center(
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Produk"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
