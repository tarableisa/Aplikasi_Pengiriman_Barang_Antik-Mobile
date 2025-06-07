import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/form_model.dart';
import 'form_detail_screen.dart';

class FormListScreen extends StatefulWidget {
  @override
  _FormListScreenState createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen> {
  List<FormModel> forms = [];
  List<FormModel> filteredForms = [];
  bool isLoading = true;
  bool isError = false;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchForms();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (searchController.text.isEmpty) {
        filteredForms = forms;
        isSearching = false;
      } else {
        isSearching = true;
        filteredForms = forms.where((form) {
          final namaPenerima = form.namaPenerima ?? '';
          final searchText = searchController.text;
          return namaPenerima.toLowerCase().contains(searchText.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> fetchForms() async {
    final start = DateTime.now();
    try {
      final data = await ApiService.getForms();
      final end = DateTime.now();
      print('Waktu fetchForms: ${end.difference(start).inMilliseconds} ms');
      setState(() {
        forms = data;
        filteredForms = data;
        isLoading = false;
        isError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      print('Error fetchForms: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Convert UTC to local timezone
    DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

    // Format with proper padding
    String day = localDateTime.day.toString().padLeft(2, '0');
    String month = localDateTime.month.toString().padLeft(2, '0');
    String year = localDateTime.year.toString();
    String hour = localDateTime.hour.toString().padLeft(2, '0');
    String minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // Alternative method with more detailed formatting
  String _formatDateTimeDetailed(DateTime dateTime) {
    // Convert UTC to local timezone
    DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

    List<String> monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];

    String day = localDateTime.day.toString();
    String month = monthNames[localDateTime.month];
    String year = localDateTime.year.toString();
    String hour = localDateTime.hour.toString().padLeft(2, '0');
    String minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Daftar Form Pengiriman',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama penerima...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
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
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Search Results Counter
          if (isSearching)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Text(
                    'Ditemukan ${filteredForms.length} hasil pencarian',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchForms,
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue[600],
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat data...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : isError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Gagal memuat data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Periksa koneksi internet Anda',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    isLoading = true;
                                    isError = false;
                                  });
                                  fetchForms();
                                },
                                icon: Icon(Icons.refresh),
                                label: Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredForms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSearching
                                        ? Icons.search_off
                                        : Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    isSearching
                                        ? 'Tidak ada hasil pencarian'
                                        : 'Belum ada data form',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    isSearching
                                        ? 'Coba gunakan kata kunci lain'
                                        : 'Form pengiriman akan muncul di sini',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: filteredForms.length,
                              itemBuilder: (ctx, i) {
                                final form = filteredForms[i];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FormDetailScreen(form: form),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() {
                                          isLoading = true;
                                          isError = false;
                                        });
                                        fetchForms();
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header with shipping icon
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.local_shipping,
                                                  color: Colors.blue[600],
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${form.namaPengirim} → ${form.namaPenerima}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.grey[800],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.scale,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '${form.berat} kg',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 12),

                                          // Location info
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: [
                                                _buildLocationRow(
                                                  Icons.my_location,
                                                  'Pengirim',
                                                  form.lokasiPengirim,
                                                  Colors.green,
                                                ),
                                                SizedBox(height: 8),
                                                _buildLocationRow(
                                                  Icons.location_on,
                                                  'Penerima',
                                                  form.lokasiPenerima,
                                                  Colors.red,
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: 12),

                                          // Time info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                _formatDateTime(
                                                    form.waktuPengiriman),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'WIB',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Spacer(),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey[400],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String location, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
