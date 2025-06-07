import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' show sin, cos, sqrt, asin, pi;
import '../../models/form_model.dart';
import 'edit_form_screen.dart';
import '../konversi/konversi_waktu_screen.dart';

class FormDetailScreen extends StatefulWidget {
  final FormModel form;

  const FormDetailScreen({super.key, required this.form});

  @override
  State<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends State<FormDetailScreen>
    with TickerProviderStateMixin {
  GoogleMapController? mapController;
  LatLng? startLatLng;
  LatLng? endLatLng;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double? distanceKm;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutBack));

    _loadMapData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    try {
      List<Location> pengirim =
          await locationFromAddress(widget.form.lokasiPengirim);
      List<Location> penerima =
          await locationFromAddress(widget.form.lokasiPenerima);

      if (pengirim.isNotEmpty && penerima.isNotEmpty) {
        startLatLng = LatLng(pengirim[0].latitude, pengirim[0].longitude);
        endLatLng = LatLng(penerima[0].latitude, penerima[0].longitude);

        distanceKm = _calculateDistance(
          startLatLng!.latitude,
          startLatLng!.longitude,
          endLatLng!.latitude,
          endLatLng!.longitude,
        );

        setState(() {
          markers = {
            Marker(
              markerId: MarkerId('pengirim'),
              position: startLatLng!,
              infoWindow: InfoWindow(title: 'Lokasi Pengirim'),
            ),
            Marker(
              markerId: MarkerId('penerima'),
              position: endLatLng!,
              infoWindow: InfoWindow(title: 'Lokasi Penerima'),
            ),
          };

          polylines = {
            Polyline(
              polylineId: PolylineId('route'),
              points: [startLatLng!, endLatLng!],
              color: Colors.deepPurple,
              width: 4,
            ),
          };
        });
      }
    } catch (e) {
      print('Gagal mengambil lokasi: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 300,
          child: startLatLng != null && endLatLng != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: startLatLng!,
                    zoom: 12,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[200]!, Colors.grey[300]!],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProofImage() {
    if (widget.form.buktiPengiriman == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          widget.form.buktiPengiriman!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.error, color: Colors.grey, size: 48),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                'Detail Pengiriman',
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
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          'Informasi Pengirim', Icons.person_outline),
                      _buildInfoCard(
                        title: 'Nama Pengirim',
                        value: widget.form.namaPengirim ?? 'Tidak tersedia',
                        icon: Icons.person,
                        color: Colors.blue,
                      ),
                      _buildInfoCard(
                        title: 'Lokasi Pengirim',
                        value: widget.form.lokasiPengirim,
                        icon: Icons.location_on,
                        color: Colors.green,
                      ),
                      _buildInfoCard(
                        title: 'No. HP Pengirim',
                        value: widget.form.phonePengirim,
                        icon: Icons.phone,
                        color: Colors.orange,
                      ),
                      _buildInfoCard(
                        title: 'Waktu Pengiriman',
                        value: widget.form.waktuPengiriman.toString(),
                        icon: Icons.schedule,
                        color: Colors.purple,
                      ),
                      _buildSectionHeader(
                          'Informasi Penerima', Icons.person_pin),
                      _buildInfoCard(
                        title: 'Nama Penerima',
                        value: widget.form.namaPenerima ?? 'Tidak tersedia',
                        icon: Icons.person,
                        color: Colors.blue,
                      ),
                      _buildInfoCard(
                        title: 'Lokasi Penerima',
                        value: widget.form.lokasiPenerima,
                        icon: Icons.location_on,
                        color: Colors.green,
                      ),
                      _buildInfoCard(
                        title: 'No. HP Penerima',
                        value: widget.form.phonePenerima,
                        icon: Icons.phone,
                        color: Colors.orange,
                      ),
                      _buildSectionHeader(
                          'Detail Paket', Icons.inventory_2_outlined),
                      _buildInfoCard(
                        title: 'Berat Paket',
                        value: '${widget.form.berat} kg',
                        icon: Icons.scale,
                        color: Colors.red,
                      ),
                      _buildInfoCard(
                        title: 'Deskripsi',
                        value: widget.form.deskripsi,
                        icon: Icons.description,
                        color: Colors.teal,
                      ),
                      if (distanceKm != null)
                        _buildInfoCard(
                          title: 'Jarak Pengiriman',
                          value: '${distanceKm!.toStringAsFixed(2)} km',
                          icon: Icons.straighten,
                          color: Colors.indigo,
                        ),
                      if (widget.form.buktiPengiriman != null) ...[
                        _buildSectionHeader(
                            'Bukti Pengiriman', Icons.camera_alt),
                        _buildProofImage(),
                      ],
                      _buildSectionHeader('Peta Rute', Icons.map),
                      _buildMapCard(),
                      _buildSectionHeader('Aksi', Icons.settings),
                      _buildActionButton(
                        text: 'Edit Form',
                        icon: Icons.edit,
                        color: Colors.deepPurple,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditFormScreen(
                                  form: widget.form, formId: widget.form.id),
                            ),
                          );
                          if (result == true) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                      _buildActionButton(
                        text: 'Konversi Waktu Pengiriman',
                        icon: Icons.access_time,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KonversiWaktuScreen(
                                waktuPengiriman: widget.form.waktuPengiriman
                                    .toIso8601String(),
                              ),
                            ),
                          );
                        },
                      ),
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
