import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KonversiWaktuScreen extends StatefulWidget {
  final String? waktuPengiriman;

  const KonversiWaktuScreen({Key? key, this.waktuPengiriman}) : super(key: key);

  @override
  State<KonversiWaktuScreen> createState() => _KonversiWaktuScreenState();
}

class _KonversiWaktuScreenState extends State<KonversiWaktuScreen> {
  DateTime? selectedDateTime;
  String? zonaTujuan = 'WIB';
  String? hasilKonversi;
  List<Map<String, String>> riwayat = [];

// Data zona waktu lengkap dengan offset
  final Map<String, Map<String, dynamic>> zonaWaktu = {
    'WIB': {
      'offset': 7,
      'name': 'Waktu Indonesia Barat',
      'flag': '🇮🇩',
      'icon': Icons.wb_sunny
    },
    'WITA': {
      'offset': 8,
      'name': 'Waktu Indonesia Tengah',
      'flag': '🇮🇩',
      'icon': Icons.wb_sunny_outlined
    },
    'WIT': {
      'offset': 9,
      'name': 'Waktu Indonesia Timur',
      'flag': '🇮🇩',
      'icon': Icons.wb_twilight
    },
    'London': {
      'offset': 1,
      'name': 'London Time',
      'flag': '🇬🇧',
      'icon': Icons.cloud
    },
  };

  @override
  void initState() {
    super.initState();
    if (widget.waktuPengiriman != null) {
      selectedDateTime = DateTime.parse(widget.waktuPengiriman!);
    } else {
      selectedDateTime = DateTime.now();
    }
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('riwayat_konversi_waktu') ?? [];
    setState(() {
      riwayat =
          list.map((e) => Map<String, String>.from(json.decode(e))).toList();
      if (riwayat.length > 8)
        riwayat = riwayat.take(8).toList(); // Batasi histori
    });
  }

  Future<void> _simpanRiwayat(
      String waktuAwal, String hasil, String zona) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('riwayat_konversi_waktu') ?? [];

    final item = {
      'awal': waktuAwal,
      'hasil': hasil,
      'zona': zona,
      'timestamp': DateTime.now().toIso8601String(),
    };

    list.insert(0, json.encode(item)); // Insert di awal
    if (list.length > 8) list.removeLast(); // Batasi maksimal 8

    await prefs.setStringList('riwayat_konversi_waktu', list);
    _loadRiwayat();
  }

  Future<void> _hapusRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('riwayat_konversi_waktu');
    setState(() {
      riwayat = [];
    });
  }

// Fungsi untuk memilih tanggal dan waktu
  void _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.deepPurple,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Colors.deepPurple,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        _konversiWaktu();
      }
    }
  }

  // Proses konversi waktu ke zona yang dipilih
  void _konversiWaktu() {
    if (selectedDateTime == null || zonaTujuan == null) return;

    final zona = zonaWaktu[zonaTujuan!];
    if (zona == null) return;

    final dtUtc = selectedDateTime!.toUtc();
    final offset = Duration(hours: zona['offset'] as int);
    final konversi = dtUtc.add(offset);
    final formatted = DateFormat('dd MMM yyyy, HH:mm').format(konversi);
    final awal =
        DateFormat('dd MMM yyyy, HH:mm').format(selectedDateTime!.toLocal());

    setState(() {
      hasilKonversi = formatted;
    });

    _simpanRiwayat(awal, formatted, zonaTujuan!);
  }

  Widget _buildTimeDisplayCard() {
    final currentTime = selectedDateTime ?? DateTime.now();
    final zona = zonaWaktu[zonaTujuan!];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                zona?['icon'] as IconData? ?? Icons.access_time,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                zona?['flag'] as String? ?? '🌍',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                zonaTujuan ?? 'WIB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasilKonversi ??
                DateFormat('dd MMM yyyy, HH:mm').format(currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            zona?['name'] as String? ?? 'Waktu Indonesia Barat',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Konversi Waktu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waktu Pengiriman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Time Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.deepPurple.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDateTime != null
                                ? DateFormat('dd MMM yyyy, HH:mm')
                                    .format(selectedDateTime!)
                                : 'Belum dipilih',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _pickDateTime,
                          icon: Icon(
                            Icons.edit,
                            color: Colors.deepPurple.shade400,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Time Zone Selector
                  const Text(
                    'Zona Waktu Tujuan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: zonaTujuan,
                        isExpanded: true,
                        onChanged: (val) {
                          setState(() => zonaTujuan = val);
                          _konversiWaktu();
                        },
                        items: zonaWaktu.keys.map((zona) {
                          final data = zonaWaktu[zona]!;
                          return DropdownMenuItem(
                            value: zona,
                            child: Row(
                              children: [
                                Text(
                                  data['flag'] as String,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  data['icon'] as IconData,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    zona,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  'UTC+${data['offset']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time Display Card
            _buildTimeDisplayCard(),

            // History Section
            if (riwayat.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
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
                          'Riwayat Konversi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: riwayat.isEmpty ? null : _hapusRiwayat,
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          label: const Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...riwayat.take(5).map((item) {
                      final zona = zonaWaktu[item['zona']];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                zona?['icon'] as IconData? ?? Icons.access_time,
                                color: Colors.deepPurple.shade400,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['awal']} → ${item['hasil']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Zona: ${item['zona']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              zona?['flag'] as String? ?? '⏰',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
