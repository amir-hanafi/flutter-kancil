// lib/pages/edit_product_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kancil/database/db_helper.dart';

class EditProductPage extends StatefulWidget {
  final int productId;
  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  bool _loading = true;

  // controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _packSizeCtrl = TextEditingController();

  // image
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // product type: "none", "parent", "child"
  String _type = "none";
  int? _selectedParentId;

  List<Map<String, dynamic>> _parentProducts = [];

  Map<String, dynamic>? _product; // raw product data

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    // load parent list first (fast) and product
    final parents = await DBHelper.getOnlyParents();
    final prod = await DBHelper.getProductById(widget.productId);

    // fill controllers and state
    if (prod != null) {
      _product = prod;
      _nameCtrl.text = prod['name'] ?? '';
      _descCtrl.text = prod['description'] ?? '';
      _priceCtrl.text = (prod['price'] ?? 0).toString();
      _barcodeCtrl.text = prod['barcode'] ?? '';
      _packSizeCtrl.text = prod['pack_size'] != null ? prod['pack_size'].toString() : '';

      final bool isParent = (prod['is_parent'] ?? 0) == 1;
      final bool isChild = prod['parent_id'] != null;

      if (isParent) {
        _type = "parent";
      } else if (isChild) {
        _type = "child";
        _selectedParentId = prod['parent_id'] as int?;
      } else {
        _type = "none";
      }

      // load image only if path exists
      final imgPath = prod['image'] as String?;
      if (imgPath != null && imgPath.isNotEmpty) {
        // do not load file object; just keep path for preview
        // image preview will call Image.file when needed
      }
    }

    _parentProducts = parents;

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _imageFile = picked;
    });
  }

  Future<void> _save() async {
    // basic validation
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama produk wajib diisi")));
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harga wajib diisi")));
      return;
    }

    if (_type == "parent" && _packSizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pack size wajib untuk parent")));
      return;
    }

    if (_type == "child" && _selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih parent untuk child")));
      return;
    }

    final int isParentVal = _type == "parent" ? 1 : 0;
    final int? parentIdVal = _type == "child" ? _selectedParentId : null;
    final int? packSizeVal = _type == "parent" ? (int.tryParse(_packSizeCtrl.text) ?? 0) : null;

    // image path: if user picked new image use that path, else keep existing path
    String? imagePath;
    if (_imageFile != null) {
      imagePath = _imageFile!.path;
    } else if (_product != null && _product!['image'] != null) {
      imagePath = _product!['image'] as String?;
    }

    final updated = <String, dynamic>{
      "name": _nameCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": int.tryParse(_priceCtrl.text.trim()) ?? 0,
      "barcode": _barcodeCtrl.text.trim(),
      "image": imagePath ?? "",
      "is_parent": isParentVal,
      "parent_id": parentIdVal,
      "pack_size": packSizeVal,
      // note: we DO NOT update stock_qty here
    };

    await DBHelper.updateProduct(widget.productId, updated);

    // return true so previous page can refresh
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _barcodeCtrl.dispose();
    _packSizeCtrl.dispose();
    super.dispose();
  }

  Widget _imagePreview() {
    final existing = _product != null ? (_product!['image'] as String? ?? "") : "";
    if (_imageFile != null) {
      if (kIsWeb) {
        return Image.network(_imageFile!.path, height: 150, fit: BoxFit.cover);
      }
      return Image.file(File(_imageFile!.path), height: 150, fit: BoxFit.cover);
    } else if (existing.isNotEmpty) {
      return Image.file(File(existing), height: 150, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80));
    } else {
      return const Icon(Icons.image, size: 80);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Produk")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
  onTap: _pickImage,
  child: Container(
    width: double.infinity,
    height: 200,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade400),
    ),
    child: _imageFile != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(
                _imageFile!.path,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(_imageFile!.path),
                fit: BoxFit.cover,
              ),
      )
    : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          SizedBox(height: 6),
          Text(
            "Tap untuk memilih gambar",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),

  ),
),


          const SizedBox(height: 16),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: "Nama Produk", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: "Deskripsi (opsional)", border: OutlineInputBorder()),
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: "Harga", border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _barcodeCtrl,
            decoration: const InputDecoration(labelText: "Barcode", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),

          const Text("Tipe Produk"),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _type,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: "none", child: Text("None (produk biasa)")),
              DropdownMenuItem(value: "parent", child: Text("Parent (pack)")),
              DropdownMenuItem(value: "child", child: Text("Child (satuan)")),
            ],
            onChanged: (v) {
              setState(() {
                _type = v ?? "none";
                if (_type != "child") _selectedParentId = null;
                if (_type != "parent") _packSizeCtrl.text = "";
              });
            },
          ),

          const SizedBox(height: 12),

          // jika child => pilih parent
          if (_type == "child") ...[
            const Text("Pilih Parent:"),
            const SizedBox(height: 6),
            DropdownButton<int>(
              value: _selectedParentId,
              isExpanded: true,
              hint: const Text("Pilih parent product"),
              items: _parentProducts.map((p) {
                return DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['name'] as String));
              }).toList(),
              onChanged: (v) => setState(() => _selectedParentId = v),
            ),
            const SizedBox(height: 12),
          ],

          // jika parent => pack size
          if (_type == "parent") ...[
            TextField(
              controller: _packSizeCtrl,
              decoration: const InputDecoration(labelText: "Isi pack (pack size)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  label: const Text("Batal"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text(
            "Catatan: stok tidak bisa diedit di halaman ini. Gunakan fitur Masuk / Keluar barang atau proses transaksi untuk mengubah stok.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ]),
      ),
    );
  }
}
