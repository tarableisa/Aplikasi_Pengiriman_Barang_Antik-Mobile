import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:proyekakhir_173/models/form_model.dart';
import 'package:proyekakhir_173/services/session_manager.dart';

class ApiService {
  static String? sessionCookie;
  static const String baseUrl =
      'https://api-pengirimanbarang-589948883802.us-central1.run.app';

  // ✅ LOGIN
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print('Login status: ${response.statusCode}');
    print('Set-Cookie header: ${response.headers['set-cookie']}');

    if (response.statusCode == 200) {
      final rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        final match = RegExp(r'connect\.sid=([^;]+)').firstMatch(rawCookie);
        if (match != null) {
          sessionCookie = 'connect.sid=${match.group(1)}';
          print('Session berhasil disimpan: $sessionCookie');
          await SessionManager.saveSession(sessionCookie!);
          return true;
        }
      }
    }

    print('Login gagal');
    return false;
  }

  // ✅ LOGOUT
  static Future<void> logout() async {
    sessionCookie = null;
    await SessionManager.clearSession();
  }

  // ✅ INIT SESSION
  static Future<void> initSession() async {
    sessionCookie = await SessionManager.getSession();
    print('Session di-load dari storage: $sessionCookie');
  }

  // ✅ KIRIM FORM
  static Future<bool> kirimFormLengkap(
    String namaPengirim,
    String lokasiPengirim,
    String waktuPengiriman,
    String phonePengirim,
    String berat,
    String deskripsi,
    String namaPenerima,
    String lokasiPenerima,
    String phonePenerima,
    File? buktiPengiriman,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/form');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Cookie'] = sessionCookie ?? ''
        ..fields['namaPengirim'] = namaPengirim
        ..fields['lokasiPengirim'] = lokasiPengirim
        ..fields['waktuPengiriman'] = waktuPengiriman
        ..fields['phonenumberPengirim'] = phonePengirim
        ..fields['berat'] = berat
        ..fields['deskripsi'] = deskripsi
        ..fields['namaPenerima'] = namaPenerima
        ..fields['lokasiPenerima'] = lokasiPenerima
        ..fields['phonenumberPenerima'] = phonePenerima;

      print('SessionCookie saat kirim form: $sessionCookie');

      if (buktiPengiriman != null) {
        if (buktiPengiriman.lengthSync() > 5 * 1024 * 1024) {
          print("Ukuran file terlalu besar (maksimum 5MB)");
          return false;
        }

        request.files.add(await http.MultipartFile.fromPath(
          'bukti_pengiriman',
          buktiPengiriman.path,
        ));
        print('File bukti: ${buktiPengiriman.path}');
      }

      final response = await request.send().timeout(Duration(seconds: 10));

      final responseBody = await response.stream.bytesToString();
      print('Status kirim form: ${response.statusCode}');
      print('Response body: $responseBody');

      return response.statusCode == 200;
    } on TimeoutException {
      print('Timeout saat mengirim form');
      return false;
    } catch (e) {
      print('Error kirim form: $e');
      return false;
    }
  }

  // ✅ AMBIL SEMUA FORM
  static Future<List<FormModel>> getForms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/form'),
        headers: {'Cookie': sessionCookie ?? ''},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List jsonData = jsonDecode(response.body);
        print('Jumlah data form: ${jsonData.length}');
        return jsonData.map((e) => FormModel.fromJson(e)).toList();
      } else {
        print('Gagal fetch form: ${response.statusCode}');
        return [];
      }
    } on TimeoutException {
      print('Request timeout saat fetch form');
      return [];
    } catch (e) {
      print('Error saat getForms: $e');
      return [];
    }
  }

  // ✅ UPDATE FORM
  static Future<bool> updateForm(
    String formId,
    FormModel form,
    File? buktiPengiriman,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/form/$formId');
      final request = http.MultipartRequest('PUT', uri)
        ..headers['Cookie'] = sessionCookie ?? ''
        ..fields['namaPengirim'] = form.namaPengirim ?? ''
        ..fields['lokasiPengirim'] = form.lokasiPengirim
        ..fields['waktuPengiriman'] = form.waktuPengiriman.toIso8601String()
        ..fields['phonenumberPengirim'] = form.phonePengirim
        ..fields['berat'] = form.berat.toString()
        ..fields['deskripsi'] = form.deskripsi
        ..fields['namaPenerima'] = form.namaPenerima ?? ''
        ..fields['lokasiPenerima'] = form.lokasiPenerima
        ..fields['phonenumberPenerima'] = form.phonePenerima;

      if (buktiPengiriman != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'bukti_pengiriman',
          buktiPengiriman.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Status update form: ${response.statusCode}');
      print('Response body: $responseBody');

      return response.statusCode == 200;
    } catch (e) {
      print('Error saat update form: $e');
      return false;
    }
  }

  // ✅ REGISTER
  static Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response.statusCode == 200;
  }
}
