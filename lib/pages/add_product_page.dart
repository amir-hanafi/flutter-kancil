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

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  /// 🔥 GANTI BARCODE MENGGUNAKAN MOBILE_SCANNER
  Future<void> _scanBarcode() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ScanBarcodePage(),
    ),
  );

  if (result != null && result is String) {
    setState(() {
      _barcodeController.text = result;
    });
  }
}


  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _descController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      "name": _nameController.text,
      "description": _descController.text,
      "price": int.parse(_priceController.text),
      "image": _imageFile!.path,
      "barcode": _barcodeController.text,
    };

    await DBHelper.insertProduct(data);

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk berhasil disimpan!")),
    );

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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
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
