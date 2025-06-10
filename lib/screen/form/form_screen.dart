import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator untuk mengambil lokasi pengguna
import 'package:geocoding/geocoding.dart'; // Import geocoding untuk mengubah koordinat menjadi alamat lengkap
import '../../services/api_service.dart';
import '../form/form_list_screen.dart';
import '../konversi/konversi_ongkir_screen.dart';
import '../map_picker_screen.dart';

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaPengirim = TextEditingController();
  final TextEditingController lokasiPengirim = TextEditingController();
  final TextEditingController waktuPengiriman = TextEditingController();
  final TextEditingController phonePengirim = TextEditingController();
  final TextEditingController berat = TextEditingController();
  final TextEditingController deskripsi = TextEditingController();
  final TextEditingController namaPenerima = TextEditingController();
  final TextEditingController lokasiPenerima = TextEditingController();
  final TextEditingController phonePenerima = TextEditingController();

  File? selectedImage;

  // Fungsi untuk mengirim data form ke server
  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      bool success = await ApiService.kirimFormLengkap(
        namaPengirim.text,
        lokasiPengirim.text,
        waktuPengiriman.text,
        phonePengirim.text,
        berat.text,
        deskripsi.text,
        namaPenerima.text,
        lokasiPenerima.text,
        phonePenerima.text,
        selectedImage,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Form terkirim' : 'Gagal mengirim'),
      ));

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FormListScreen()),
        );
      }
    }
  }

// Fungsi untuk memilih gambar dari galeri
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // Fungsi untuk mendeteksi lokasi pengguna dan mengisi otomatis lokasiPengirim
  Future<void> _deteksiLokasiSaya() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Izin lokasi ditolak')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Konversi koordinat menjadi alamat lengkap
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final alamatLengkap =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";

        setState(() {
          lokasiPengirim.text = alamatLengkap;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendeteksi lokasi: $e')),
      );
    }
  }

  void _bukaKonversi() {
    if (berat.text.isNotEmpty) {
      final beratValue = double.tryParse(berat.text);
      if (beratValue != null && beratValue > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KonversiScreen(berat: beratValue),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Masukkan berat yang valid')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Isi berat terlebih dahulu')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Color.fromARGB(255, 8, 36, 121), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: Color.fromARGB(255, 8, 36, 121).withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Color.fromARGB(255, 8, 36, 121), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Color.fromARGB(255, 8, 36, 121)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 249, 230),
      appBar: AppBar(
        title: Text('Form Pengiriman',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 8, 36, 121),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle('Informasi Pengirim'),
              TextFormField(
                controller: namaPengirim,
                decoration: _inputDecoration('Nama Pengirim'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: lokasiPengirim,
                readOnly: true,
                decoration: _inputDecoration('Lokasi Pengirim'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MapPickerScreen()),
                  );
                  if (result != null && result is String) {
                    setState(() => lokasiPengirim.text = result);
                  }
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _deteksiLokasiSaya,
                  icon: Icon(Icons.my_location,
                      color: Color.fromARGB(255, 26, 134, 158)),
                  label: Text('Deteksi Lokasi Saya',
                      style: TextStyle(color: Color.fromARGB(255, 8, 36, 121))),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: waktuPengiriman,
                readOnly: true,
                decoration: _inputDecoration('Waktu Pengiriman'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final combined = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      waktuPengiriman.text = combined.toUtc().toIso8601String();
                    }
                  }
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: phonePengirim,
                decoration: _inputDecoration('No. HP Pengirim'),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (!RegExp(r'^\d+$').hasMatch(val)) return 'Hanya angka';
                  if (val.length < 11) return 'Minimal 11 digit';
                  return null;
                },
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Informasi Paket'),
              TextFormField(
                controller: berat,
                decoration: _inputDecoration('Berat Barang (kg)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: deskripsi,
                decoration: _inputDecoration('Deskripsi Barang'),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Informasi Penerima'),
              TextFormField(
                controller: namaPenerima,
                decoration: _inputDecoration('Nama Penerima'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: lokasiPenerima,
                readOnly: true,
                decoration: _inputDecoration('Lokasi Penerima'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MapPickerScreen()),
                  );
                  if (result != null && result is String) {
                    setState(() => lokasiPenerima.text = result);
                  }
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: phonePenerima,
                decoration: _inputDecoration('No. HP Penerima'),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (!RegExp(r'^\d+$').hasMatch(val)) return 'Hanya angka';
                  if (val.length < 11) return 'Minimal 11 digit';
                  return null;
                },
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: Icon(Icons.upload_file, color: Colors.white),
                  label: Text('Upload Bukti Pengiriman',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 8, 36, 121),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              if (selectedImage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File terpilih: ${selectedImage!.path.split('/').last}',
                          style:
                              TextStyle(color: Colors.green[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.attach_money,
                          color: Color.fromARGB(255, 8, 36, 121)),
                      onPressed: _bukaKonversi,
                      label: Text("Cek Ongkir",
                          style: TextStyle(
                              color: Color.fromARGB(255, 8, 36, 121),
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 204, 127),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: submitForm,
                      label: Text("Kirim Form",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 8, 36, 121),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: 16, top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 8, 36, 121),
            Color.fromARGB(255, 26, 134, 158),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 8, 36, 121).withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getSectionIcon(title),
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Informasi Pengirim':
        return Icons.person_outline;
      case 'Informasi Paket':
        return Icons.inventory_2_outlined;
      case 'Informasi Penerima':
        return Icons.person_pin_circle_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
