import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/form_model.dart';
import '../../services/api_service.dart';
import '../map_picker_screen.dart';

class EditFormScreen extends StatefulWidget {
  final FormModel form;
  final int formId;

  const EditFormScreen({Key? key, required this.form, required this.formId})
      : super(key: key);

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaPengirim;
  late TextEditingController lokasiPengirim;
  late TextEditingController waktuPengiriman;
  late TextEditingController phonePengirim;
  late TextEditingController berat;
  late TextEditingController deskripsi;
  late TextEditingController namaPenerima;
  late TextEditingController lokasiPenerima;
  late TextEditingController phonePenerima;

  File? selectedImage;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    final f = widget.form;
    namaPengirim = TextEditingController(text: f.namaPengirim ?? '');
    lokasiPengirim = TextEditingController(text: f.lokasiPengirim);
    waktuPengiriman = TextEditingController(
        text: f.waktuPengiriman.toUtc().toIso8601String());
    phonePengirim = TextEditingController(text: f.phonePengirim);
    berat = TextEditingController(text: f.berat.toString());
    deskripsi = TextEditingController(text: f.deskripsi);
    namaPenerima = TextEditingController(text: f.namaPenerima ?? '');
    lokasiPenerima = TextEditingController(text: f.lokasiPenerima);
    phonePenerima = TextEditingController(text: f.phonePenerima);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    namaPengirim.dispose();
    lokasiPengirim.dispose();
    waktuPengiriman.dispose();
    phonePengirim.dispose();
    berat.dispose();
    deskripsi.dispose();
    namaPenerima.dispose();
    lokasiPenerima.dispose();
    phonePenerima.dispose();
    super.dispose();
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
            const SnackBar(content: Text('Izin lokasi ditolak')),
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

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final updatedForm = FormModel(
        id: widget.form.id,
        namaPengirim: namaPengirim.text,
        lokasiPengirim: lokasiPengirim.text,
        waktuPengiriman: DateTime.parse(waktuPengiriman.text),
        phonePengirim: phonePengirim.text,
        berat: double.tryParse(berat.text) ?? 0.0,
        deskripsi: deskripsi.text,
        namaPenerima: namaPenerima.text,
        lokasiPenerima: lokasiPenerima.text,
        phonePenerima: phonePenerima.text,
      );

      final success = await ApiService.updateForm(
        widget.form.id.toString(),
        updatedForm,
        selectedImage,
      );

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Berhasil update' : 'Gagal update'),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 20),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool showDetectButton = false,
  }) {
    return Column(
      children: [
        _buildTextField(
          controller: controller,
          label: label,
          icon: icon,
          validator: validator,
          readOnly: true,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapPickerScreen()),
            );
            if (result != null && result is String) {
              setState(() => controller.text = result);
            }
          },
        ),
        if (showDetectButton)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextButton.icon(
                onPressed: _deteksiLokasiSaya,
                icon: const Icon(Icons.my_location, color: Colors.deepPurple),
                label: const Text(
                  'Deteksi Lokasi Saya',
                  style: TextStyle(color: Colors.deepPurple),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: pickImage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Upload Gambar Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedImage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gambar Baru Dipilih',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          selectedImage!.path.split('/').last,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (widget.form.buktiPengiriman != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Gambar Sebelumnya',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      widget.form.buktiPengiriman!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child:
                                Icon(Icons.error, color: Colors.grey, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : submitForm,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Update Form',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Edit Pengiriman',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          'Informasi Pengirim', Icons.person_outline),
                      _buildTextField(
                        controller: namaPengirim,
                        label: 'Nama Pengirim',
                        icon: Icons.person,
                      ),
                      _buildLocationField(
                        controller: lokasiPengirim,
                        label: 'Lokasi Pengirim',
                        icon: Icons.location_on,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                        showDetectButton: true,
                      ),
                      _buildTextField(
                        controller: waktuPengiriman,
                        label: 'Waktu Pengiriman',
                        icon: Icons.calendar_today,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                        readOnly: true,
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
                              setState(() {
                                waktuPengiriman.text =
                                    combined.toUtc().toIso8601String();
                              });
                            }
                          }
                        },
                      ),
                      _buildTextField(
                        controller: phonePengirim,
                        label: 'No. HP Pengirim',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      _buildSectionHeader(
                          'Detail Paket', Icons.inventory_2_outlined),
                      _buildTextField(
                        controller: berat,
                        label: 'Berat (kg)',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      _buildTextField(
                        controller: deskripsi,
                        label: 'Deskripsi Paket',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      _buildSectionHeader(
                          'Informasi Penerima', Icons.person_pin),
                      _buildTextField(
                        controller: namaPenerima,
                        label: 'Nama Penerima',
                        icon: Icons.person,
                      ),
                      _buildLocationField(
                        controller: lokasiPenerima,
                        label: 'Lokasi Penerima',
                        icon: Icons.location_on,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      _buildTextField(
                        controller: phonePenerima,
                        label: 'No. HP Penerima',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      _buildSectionHeader('Bukti Pengiriman', Icons.camera_alt),
                      _buildImageSection(),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
