import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class KonversiScreen extends StatefulWidget {
  final double? berat;

  const KonversiScreen({super.key, this.berat});

  @override
  State<KonversiScreen> createState() => _KonversiScreenState();
}

class _KonversiScreenState extends State<KonversiScreen> {
  final _beratController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Data mata uang 
  final _currencies = {
    'IDR': {'symbol': 'Rp', 'flag': '🇮🇩', 'name': 'Indonesian Rupiah'},
    'USD': {'symbol': '\$', 'flag': '🇺🇸', 'name': 'US Dollar'},
    'EUR': {'symbol': '€', 'flag': '🇪🇺', 'name': 'Euro'},
    'JPY': {'symbol': '¥', 'flag': '🇯🇵', 'name': 'Japanese Yen'},
    'GBP': {'symbol': '£', 'flag': '🇬🇧', 'name': 'British Pound'},
    'AUD': {'symbol': 'A\$', 'flag': '🇦🇺', 'name': 'Australian Dollar'},
    'CAD': {'symbol': 'C\$', 'flag': '🇨🇦', 'name': 'Canadian Dollar'},
    'SGD': {'symbol': 'S\$', 'flag': '🇸🇬', 'name': 'Singapore Dollar'},
    'MYR': {'symbol': 'RM', 'flag': '🇲🇾', 'name': 'Malaysian Ringgit'},
  };

  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double? _fromValue;
  double? _toValue;
  List<Map<String, dynamic>> _histori = [];
  Map<String, double> _exchangeRates = {};
  bool _isLoadingRates = false;
  String? _rateError;
  DateTime? _lastRateUpdate;
  bool _isConvertingFromFirst = true;

  @override
  void initState() {
    super.initState();
    _loadHistori();
    _loadExchangeRates();

// Jika berat dikirim dari screen lain, isi otomatis
    if (widget.berat != null && widget.berat! > 0) {
      _beratController.text = widget.berat!.toStringAsFixed(2);
    }
  }

// Fungsi ambil data kurs dari API ExchangeRate
  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
      _rateError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null) {
          setState(() {
            _exchangeRates = rates
                .map((key, value) => MapEntry(key, (value as num).toDouble()));
            _exchangeRates['USD'] = 1.0;
            _lastRateUpdate = DateTime.now();
            _isLoadingRates = false;
          });

          await _saveExchangeRatesCache();


          if (_beratController.text.isNotEmpty) {
            _konversi();
          }
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception(
            'Failed to load exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading exchange rates: $e');
      await _loadExchangeRatesFromCache();

      setState(() {
        _rateError = 'Gagal memuat kurs terbaru, menggunakan data cache';
        _isLoadingRates = false;
      });

      if (_beratController.text.isNotEmpty && _exchangeRates.isNotEmpty) {
        _konversi();
      }
    }
  }

  Future<void> _saveExchangeRatesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'rates': _exchangeRates,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('exchange_rates_cache', jsonEncode(cacheData));
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

// Load kurs dari cache jika gagal ambil dari API
  Future<void> _loadExchangeRatesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('exchange_rates_cache');

      if (cacheJson != null && cacheJson.isNotEmpty) {
        final cacheData = jsonDecode(cacheJson);
        final rates = cacheData['rates'] as Map<String, dynamic>?;
        final timestampStr = cacheData['timestamp'] as String?;

        if (rates != null && timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);

          // Gunakan cache jika tidak lebih dari 24 jam
          if (DateTime.now().difference(timestamp).inHours < 24) {
            setState(() {
              _exchangeRates = rates.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()));
              _lastRateUpdate = timestamp;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error loading cache: $e');
    }

    // Fallback ke rates manual jika cache tidak tersedia
    setState(() {
      _exchangeRates = {
        'USD': 1.0,
        'IDR': 15400.0,
        'EUR': 0.92,
        'JPY': 148.0,
        'GBP': 0.79,
        'AUD': 1.50,
        'CAD': 1.35,
        'SGD': 1.35,
        'MYR': 4.65,
      };
      _lastRateUpdate = DateTime.now();
    });
  }

  Future<void> _refreshExchangeRates() async {
    await _loadExchangeRates();
  }

  Future<void> _loadHistori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historiJson = prefs.getString('histori_konversi');

      if (historiJson != null && historiJson.isNotEmpty) {
        final decoded = jsonDecode(historiJson) as List?;

        if (decoded != null) {
          setState(() {
            _histori = decoded.map<Map<String, dynamic>>((e) {
              return {
                'berat': e['berat'] ?? 0.0,
                'fromCurrency': e['fromCurrency'] ?? 'IDR',
                'toCurrency': e['toCurrency'] ?? 'USD',
                'fromValue': e['fromValue'] ?? 0.0,
                'toValue': e['toValue'] ?? 0.0,
                'tanggal': e['tanggal'] != null
                    ? DateTime.parse(e['tanggal'])
                    : DateTime.now(),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _histori = [];
      });
    }
  }

  Future<void> _saveHistori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_histori
          .map((e) => {
                'berat': e['berat'],
                'fromCurrency': e['fromCurrency'],
                'toCurrency': e['toCurrency'],
                'fromValue': e['fromValue'],
                'toValue': e['toValue'],
                'tanggal': (e['tanggal'] as DateTime).toIso8601String(),
              })
          .toList());
      await prefs.setString('histori_konversi', encoded);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> _hapusHistori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('histori_konversi');
      setState(() {
        _histori.clear();
      });
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  double _convertCurrency(double amount, String from, String to) {
    if (from == to) return amount;
    if (_exchangeRates.isEmpty) return amount;

    final fromRate = _exchangeRates[from] ?? 1.0;
    final toRate = _exchangeRates[to] ?? 1.0;

    
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

// Proses konversi berdasarkan berat dan kurs
  void _konversi() {
    if (!_formKey.currentState!.validate()) return;
    if (_exchangeRates.isEmpty) return;
    if (_beratController.text.isEmpty) return;

    final beratText = _beratController.text.trim();
    final berat = double.tryParse(beratText);

    if (berat == null || berat <= 0) return;

    final hargaPerKgIDR = 20000.0;
    final totalIDR = berat * hargaPerKgIDR;

    final fromAmount = _convertCurrency(totalIDR, 'IDR', _fromCurrency);
    final toAmount = _convertCurrency(totalIDR, 'IDR', _toCurrency);

    setState(() {
      _fromValue = fromAmount;
      _toValue = toAmount;

      _histori.insert(0, {
        'berat': berat,
        'fromCurrency': _fromCurrency,
        'toCurrency': _toCurrency,
        'fromValue': fromAmount,
        'toValue': toAmount,
        'tanggal': DateTime.now(),
      });

      if (_histori.length > 10) _histori.removeLast();
    });

    _saveHistori();
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;

      final tempValue = _fromValue;
      _fromValue = _toValue;
      _toValue = tempValue;
    });

    if (_beratController.text.isNotEmpty && _exchangeRates.isNotEmpty) {
      _konversi();
    }
  }

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  String _formatCurrency(double? value, String currency) {
    if (value == null) return '0';

    if (currency == 'JPY') {
      return NumberFormat('#,##0').format(value);
    } else {
      return NumberFormat('#,##0.00').format(value);
    }
  }

  Widget _buildCurrencyCard(String currency, double? value, bool isFrom) {
    final currencyData = _currencies[currency];
    if (currencyData == null) return const SizedBox.shrink();

    final formattedValue = _formatCurrency(value, currency);
    final symbol = currencyData['symbol'] ?? '';
    final flag = currencyData['flag'] ?? '🌍';
    final name = currencyData['name'] ?? currency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFrom
              ? [Colors.blue.shade400, Colors.blue.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isFrom ? Colors.blue : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                currency,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol $formattedValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateStatus() {
    if (_isLoadingRates) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Memuat kurs mata uang...',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    if (_rateError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _rateError!,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
              ),
            ),
            GestureDetector(
              onTap: _refreshExchangeRates,
              child:
                  Icon(Icons.refresh, size: 16, color: Colors.amber.shade600),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCurrencyDropdown(String selectedCurrency, bool isFrom) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCurrency,
          isExpanded: true,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isFrom) {
                  _fromCurrency = val;
                } else {
                  _toCurrency = val;
                }
              });
              if (_exchangeRates.isNotEmpty &&
                  _beratController.text.isNotEmpty) {
                _konversi();
              }
            }
          },
          items: _currencies.keys.map((currency) {
            final data = _currencies[currency]!;
            final flag = data['flag'] ?? '🌍';
            final symbol = data['symbol'] ?? '';

            return DropdownMenuItem(
              value: currency,
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(currency),
                  const SizedBox(width: 4),
                  Text(
                    symbol,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshExchangeRates,
            tooltip: 'Refresh Kurs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExchangeRateStatus(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Harga dasar: Rp 20,000 per kg | Kurs real-time dari API',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            double.tryParse(value) != null &&
                            _exchangeRates.isNotEmpty) {
                          _konversi();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exchangeRates.isEmpty ? null : _konversi,
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
            if (_fromValue != null && _toValue != null) ...[
              const SizedBox(height: 16),
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
                      'Konversi Mata Uang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCurrencyDropdown(_fromCurrency, true),
                    const SizedBox(height: 8),
                    _buildCurrencyCard(_fromCurrency, _fromValue, true),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _swapCurrencies,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(
                            Icons.swap_vert,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ke',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCurrencyDropdown(_toCurrency, false),
                    const SizedBox(height: 8),
                    _buildCurrencyCard(_toCurrency, _toValue, false),
                    if (_lastRateUpdate != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Kurs update: ${DateFormat('dd MMM HH:mm').format(_lastRateUpdate!)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_histori.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                      final fromCurrency =
                          _currencies[item['fromCurrency'] ?? 'IDR'];
                      final toCurrency =
                          _currencies[item['toCurrency'] ?? 'USD'];

                      final fromSymbol =
                          fromCurrency?['symbol'] ?? '';
                      final toSymbol = toCurrency?['symbol'] ?? '';
                      final fromFlag = fromCurrency?['flag'] ?? '🌍';
                      final toFlag = toCurrency?['flag'] ?? '🌍';

                      final fromFormatted = _formatCurrency(
                          item['fromValue'], item['fromCurrency'] ?? 'IDR');
                      final toFormatted = _formatCurrency(
                          item['toValue'], item['toCurrency'] ?? 'USD');

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
                                    '${item['berat'] ?? 0} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '$fromFlag $fromSymbol $fromFormatted → $toFlag $toSymbol $toFormatted',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM, HH:mm').format(
                                        item['tanggal'] ?? DateTime.now()),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
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
