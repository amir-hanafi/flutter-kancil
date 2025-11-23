import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  String barcode = "";

  Future<void> startScan() async {
    try {
      var result = await BarcodeScanner.scan(
        options: ScanOptions(
          useCamera: -1, // default camera belakang
          autoEnableFlash: false,
          android: AndroidOptions(
            useAutoFocus: true,
          ),
        ),
      );

      if (!mounted) return;

      // Jika scan berhasil dan tidak cancel
      if (result.type == ResultType.Barcode) {
        setState(() {
          barcode = result.rawContent;
        });

        // Kembali ke halaman sebelumnya dengan hasil scan
        Navigator.pop(context, barcode);
      }
    } catch (e) {
      // Handle error scan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    startScan(); // langsung scan saat halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Center(
        child: barcode.isEmpty
            ? const Text('Scanning...')
            : Text('Scanned: $barcode'),
      ),
    );
  }
}
