import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Ganti import shake dengan sensors_plus
import 'dart:async';
import 'dart:math';
import '../services/api_service.dart';
import '../models/form_model.dart';
import 'auth/login_screen.dart';
import 'form/form_screen.dart';
import 'form/form_list_screen.dart';
import 'konversi/konversi_ongkir_screen.dart';
import 'konversi/konversi_waktu_screen.dart';
import 'profil/profil_screen.dart';
import 'form/form_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;

  // Ganti ShakeDetector dengan StreamSubscription untuk accelerometer
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 12.0; // Threshold untuk mendeteksi shake
  DateTime? _lastShakeTime; // Untuk cooldown

  final List<Widget> _screens = [
    Container(), // Tab Home akan dibangun manual
    const KonversiScreen(),
    const KonversiWaktuScreen(),
    const ProfilScreen(),
  ];

  List<FormModel> forms = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    // Tambahkan observer untuk lifecycle
    WidgetsBinding.instance.addObserver(this);
    fetchForms();

    // Inisialisasi accelerometer listener
    _initAccelerometer();
  }

  @override
  void dispose() {
    // Hapus observer saat dispose
    WidgetsBinding.instance.removeObserver(this);

    // Cancel accelerometer subscription
    _accelerometerSubscription?.cancel();

    super.dispose();
  }

  // Method untuk inisialisasi accelerometer
  void _initAccelerometer() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      // Hanya aktif shake logout di home tab
      if (_currentIndex == 0) {
        _detectShake(event);
      }
    });
  }

  // Method untuk mendeteksi shake gesture
  void _detectShake(AccelerometerEvent event) {
    // Hitung total acceleration dari ketiga axis
    double acceleration =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Jika acceleration melebihi threshold
    if (acceleration > _shakeThreshold) {
      DateTime now = DateTime.now();

      // Cooldown 2 detik untuk mencegah multiple trigger
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > Duration(seconds: 2)) {
        _lastShakeTime = now;
        print('Shake detected! Acceleration: $acceleration'); // Debug
        _showLogoutDialog();
      }
    }
  }

  // Method untuk menampilkan dialog logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.vibration,
                size: 48,
                color: Colors.orange,
              ),
              SizedBox(height: 12),
              Text(
                'Anda melakukan shake gesture.\nYakin ingin logout?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Ya, Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method ini dipanggil ketika app lifecycle berubah
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data ketika app kembali ke foreground
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      fetchForms();
    }
  }

  Future<void> fetchForms() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      final data = await ApiService.getForms();

      if (mounted) {
        setState(() {
          forms = data;
          isLoading = false;
          isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    }
  }

  // Method untuk refresh data secara manual
  Future<void> refreshData() async {
    await fetchForms();
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = ['Home', 'Konversi Ongkir', 'Konversi Waktu', 'Profil'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5), // Cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F), // Navy
        elevation: 0,
        title: Row(
          children: [
            Text(
              tabTitles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Tambahkan indikator shake di home tab
            if (_currentIndex == 0) ...[
              SizedBox(width: 8),
              Icon(
                Icons.vibration,
                color: Colors.white70,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Shake to logout',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        leading: _currentIndex == 0
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          // Tambahkan tombol refresh di home tab
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
              onPressed: refreshData,
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _currentIndex == 0 ? buildDrawer() : null,
      body: _currentIndex == 0 ? buildHomeTab() : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6A5AE0),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh data ketika kembali ke home tab
          if (index == 0) {
            fetchForms();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Ongkir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Waktu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A5AE0), Color(0xFFB69DF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.local_shipping, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Form Pengiriman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kelola pengiriman Anda',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note, color: Color(0xFF6A5AE0)),
            title: const Text(
              'Isi Form Baru',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Buat pengiriman baru'),
            onTap: () async {
              Navigator.pop(context); // Tutup drawer

              // Gunakan await dan then untuk memastikan refresh
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormScreen()),
              ).then((result) {
                // Refresh data setelah kembali dari form, regardless of result
                print('Kembali dari FormScreen dengan result: $result');
                fetchForms();
              });
            },
          ),
          const Divider(),
          // Tambahkan ListTile untuk Daftar Pengiriman
          ListTile(
            leading: const Icon(Icons.list_alt, color: Color(0xFF6A5AE0)),
            title: const Text(
              'Daftar Pengiriman',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Lihat semua ${forms.length} pengiriman'),
            onTap: () async {
              Navigator.pop(context); // Tutup drawer

              // Navigate to FormListScreen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormListScreen()),
              );

              // Refresh data setelah kembali dari FormListScreen
              if (result == true) {
                print('Kembali dari FormListScreen dengan result: $result');
                fetchForms();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Color(0xFF6A5AE0)),
            title: const Text(
              'Riwayat Pengiriman',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${forms.length} pengiriman'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              _showFormListDialog();
            },
          ),
          const Divider(),
          // Tambahkan info shake gesture
          ListTile(
            leading: const Icon(Icons.vibration, color: Colors.orange),
            title: const Text(
              'Shake Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Goyang HP untuk logout cepat'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showFormListDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pengiriman',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: forms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada data form',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Silakan isi form pengiriman\nterlebih dahulu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: forms.length,
                        itemBuilder: (ctx, i) {
                          final form = forms[i];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFECECFF),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF6A5AE0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${form.namaPengirim} → ${form.namaPenerima}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Berat: ${form.berat} kg',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '${form.lokasiPengirim} → ${form.lokasiPenerima}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                form.buktiPengiriman != null
                                    ? Icons.image
                                    : Icons.image_not_supported,
                                color: form.buktiPengiriman != null
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              onTap: () {
                                Navigator.pop(context); // Tutup dialog
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FormDetailScreen(form: form),
                                  ),
                                ).then((result) {
                                  // Refresh data setelah kembali dari detail
                                  print(
                                      'Kembali dari FormDetailScreen dengan result: $result');
                                  fetchForms();
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHomeTab() {
    return RefreshIndicator(
      onRefresh: fetchForms,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeroSection(),
            const SizedBox(height: 24),
            buildWelcomeSection(),
            const SizedBox(height: 24),
            buildQuickActions(),
            const SizedBox(height: 24),
            buildRecentFormsPreview(),
          ],
        ),
      ),
    );
  }

  Widget buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A5AE0), Color(0xFFB69DF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Selamat datang!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola pengiriman Anda dengan mudah dan efisien.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Pengiriman',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Pengiriman',
                  forms.length.toString(),
                  Icons.local_shipping,
                  const Color(0xFF6A5AE0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Dengan Bukti',
                  forms
                      .where((f) => f.buktiPengiriman != null)
                      .length
                      .toString(),
                  Icons.image,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Isi Form Baru',
                  Icons.edit_note,
                  const Color(0xFF6A5AE0),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FormScreen()),
                    ).then((result) {
                      // Refresh data setelah kembali dari form
                      print(
                          'Kembali dari FormScreen (Quick Action) dengan result: $result');
                      fetchForms();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Lihat Riwayat',
                  Icons.list_alt,
                  Colors.orange,
                  () => _showFormListDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentFormsPreview() {
    final recentForms = forms.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengiriman Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (forms.isNotEmpty)
                TextButton(
                  onPressed: () => _showFormListDialog(),
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          recentForms.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada pengiriman',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentForms.map((form) {
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFECECFF),
                          radius: 20,
                          child: Icon(
                            Icons.local_shipping,
                            color: Color(0xFF6A5AE0),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${form.namaPengirim} → ${form.namaPenerima}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Berat: ${form.berat} kg',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          form.buktiPengiriman != null
                              ? Icons.image
                              : Icons.image,
                          color: form.buktiPengiriman != null
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormDetailScreen(form: form),
                            ),
                          ).then((result) {
                            // Refresh data setelah kembali dari detail
                            print(
                                'Kembali dari FormDetailScreen (Recent) dengan result: $result');
                            fetchForms();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
