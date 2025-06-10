import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <- Tambahkan ini
import 'package:proyekakhir_173/services/api_service.dart';
import 'package:proyekakhir_173/services/notification_service.dart';
import 'package:proyekakhir_173/screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables dari file .env
  await dotenv.load(fileName: ".env");

  // Inisialisasi API dan notifikasi
  await ApiService.initSession();
  NotificationService.initialize();
  NotificationService.requestPermissionIfNeeded();
  NotificationService.showDailyReminderNotification();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pengiriman Barang',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
