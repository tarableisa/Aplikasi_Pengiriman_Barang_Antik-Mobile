import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: const Color.fromARGB(255, 6, 0, 63)),
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
                  decoration: _inputDecoration('Nama Pengirim')),
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
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Informasi Penerima'),
              TextFormField(
                  controller: namaPenerima,
                  decoration: _inputDecoration('Nama Penerima')),
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
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.upload_file),
                label: Text('Upload Bukti Pengiriman',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 8, 36, 121),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Gambar: ${selectedImage!.path.split('/').last}',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.attach_money),
                      onPressed: _bukaKonversi,
                      label: Text("Cek Ongkir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 204, 127),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.send),
                      onPressed: submitForm,
                      label: Text("Kirim Form"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 204, 127),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }
}
