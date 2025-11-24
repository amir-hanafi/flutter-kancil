import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRSettings {
  static const String qrKey = "qr_image_path";

  // simpan path qr
  static Future<void> setQRPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(qrKey, path);
  }

  // ambil path qr
  static Future<String?> getQRPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(qrKey);
  }
}

void showQRSettingsPopup(BuildContext context) {
  XFile? _pickedFile;
  final ImagePicker picker = ImagePicker();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Atur QR Pembayaran"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedFile != null)
                  Image.file(
                    File(_pickedFile!.path),
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                else
                  const Text("Belum ada gambar dipilih"),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => _pickedFile = picked);
                    }
                  },
                  child: const Text("Pilih Gambar QR"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_pickedFile != null) {
                    await QRSettings.setQRPath(_pickedFile!.path);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      );
    },
  );
}
