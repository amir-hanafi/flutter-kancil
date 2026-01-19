import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    await DBHelper.saveStoreProfile({
      "name": nameCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "logo": null,
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async{
        
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Registrasi Toko")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
      
                const SizedBox(height: 20),
                const Icon(Icons.store, size: 90, color: Colors.grey),
                const SizedBox(height: 20),
      
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nama Toko"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Nama toko wajib diisi" : null,
                ),
      
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Alamat"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Alamat wajib diisi" : null,
                ),
      
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Nomor Telepon"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Nomor telepon wajib diisi" : null,
                ),
      
                const SizedBox(height: 30),
      
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Simpan & Masuk"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
