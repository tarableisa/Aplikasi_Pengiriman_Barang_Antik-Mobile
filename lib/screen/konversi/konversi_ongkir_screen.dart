import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KonversiScreen extends StatefulWidget {
  final double? berat;

  const KonversiScreen({super.key, this.berat});

  @override
  State<KonversiScreen> createState() => _KonversiScreenState();
}

class _KonversiScreenState extends State<KonversiScreen> {
  final _beratController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _kurs = {
    'USD': {'rate': 0.000064, 'symbol': '\$', 'flag': '🇺🇸'},
    'EUR': {'rate': 0.000059, 'symbol': '€', 'flag': '🇪🇺'},
    'JPY': {'rate': 0.0099, 'symbol': '¥', 'flag': '🇯🇵'},
    'IDR': {'rate': 1.0, 'symbol': 'Rp', 'flag': '🇮🇩'},
  };

  String _selectedCurrency = 'USD';
  double? _convertedValue;
  List<Map<String, dynamic>> _histori = [];

  @override
  void initState() {
    super.initState();
    _loadHistori();

    if (widget.berat != null && widget.berat! > 0) {
      _beratController.text = widget.berat!.toStringAsFixed(2);
      Future.microtask(_konversi);
    }
  }

  Future<void> _loadHistori() async {
    final prefs = await SharedPreferences.getInstance();
    final historiJson = prefs.getString('histori_konversi');
    if (historiJson != null) {
      final decoded = jsonDecode(historiJson) as List;
      setState(() {
        _histori = decoded.map<Map<String, dynamic>>((e) {
          return {
            'berat': e['berat'],
            'mataUang': e['mataUang'],
            'hasil': e['hasil'],
            'tanggal': DateTime.parse(e['tanggal']),
          };
        }).toList();
      });
    }
  }

  Future<void> _saveHistori() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_histori
        .map((e) => {
              'berat': e['berat'],
              'mataUang': e['mataUang'],
              'hasil': e['hasil'],
              'tanggal': (e['tanggal'] as DateTime).toIso8601String(),
            })
        .toList());
    await prefs.setString('histori_konversi', encoded);
  }

  Future<void> _hapusHistori() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('histori_konversi');
    setState(() {
      _histori.clear();
    });
  }

  void _konversi() {
    if (!_formKey.currentState!.validate()) return;

    final berat = double.parse(_beratController.text);
    final hargaPerKgIDR = 20000;
    final totalIDR = berat * hargaPerKgIDR;
    final rate = _kurs[_selectedCurrency]?['rate'] as double? ?? 1.0;
    final hasil = totalIDR * rate;

    setState(() {
      _convertedValue = hasil;
      _histori.insert(0, {
        'berat': berat,
        'mataUang': _selectedCurrency,
        'hasil': hasil,
        'tanggal': DateTime.now(),
      });
      if (_histori.length > 10) _histori.removeLast(); // Batasi histori
    });
    _saveHistori();
  }

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  Widget _buildCurrencyCard() {
    if (_convertedValue == null) return const SizedBox.shrink();

    final currency = _kurs[_selectedCurrency];
    if (currency == null) return const SizedBox.shrink();

    final formatter = NumberFormat('#,##0.00');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currency['flag'] as String? ?? '🌍',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estimasi Ongkir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${currency['symbol'] as String? ?? ''} ${formatter.format(_convertedValue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _selectedCurrency,
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
          'Konversi Ongkir',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Pengiriman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _beratController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Berat Barang',
                        suffixText: 'kg',
                        prefixIcon: const Icon(Icons.scale, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Berat harus diisi';
                        }
                        final berat = double.tryParse(value);
                        if (berat == null || berat <= 0) {
                          return 'Masukkan angka positif';
                        }
                        return null;
                      },
                      onEditingComplete: _konversi,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mata Uang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _selectedCurrency = val!);
                            _konversi();
                          },
                          items: _kurs.keys.map((currency) {
                            final data = _kurs[currency]!;
                            return DropdownMenuItem(
                              value: currency,
                              child: Row(
                                children: [
                                  Text(
                                    data['flag'] as String? ?? '🌍',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(currency),
                                  const Spacer(),
                                  Text(
                                    data['symbol'] as String? ?? '',
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _konversi,
                        icon: const Icon(Icons.calculate, color: Colors.white),
                        label: const Text(
                          'Hitung Estimasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Result Card
            _buildCurrencyCard(),

            // History Section
            if (_histori.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                          'Histori Terakhir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _hapusHistori,
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
                    ...(_histori.take(5).map((item) {
                      final currencyData = _kurs[item['mataUang']];
                      final symbol = currencyData?['symbol'] as String? ?? '';
                      final flag = currencyData?['flag'] as String? ?? '🌍';

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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_shipping,
                                color: Colors.blue.shade400,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['berat']} kg → $symbol ${NumberFormat('#,##0.00').format(item['hasil'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM, HH:mm')
                                        .format(item['tanggal']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
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
