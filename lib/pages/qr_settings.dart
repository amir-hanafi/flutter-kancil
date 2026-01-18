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

