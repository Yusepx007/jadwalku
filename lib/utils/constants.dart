import 'package:flutter/material.dart';

class AppColors {
  // === MINT GREEN PALETTE ===
  static const Color primary = Color(0xFF2DD4BF);       // Teal/mint utama
  static const Color primaryDark = Color(0xFF0F9688);   // Mint gelap
  static const Color primaryLight = Color(0xFF99F6E4);  // Mint terang
  static const Color secondary = Color(0xFF34D399);     // Emerald accent
  static const Color accent = Color(0xFF6EE7B7);        // Mint soft

  // Background dark
  static const Color bgDark = Color(0xFF0A0F0E);        // Hitam kehijauan
  static const Color bgMid = Color(0xFF111A17);
  static const Color bgCard = Color(0xFF162220);        // Card gelap mint
  static const Color bgCardLight = Color(0xFF1C2E2A);   // Card agak terang
  static const Color bgSurface = Color(0xFF1F3330);

  // Text
  static const Color textPrimary = Color(0xFFF0FDFB);
  static const Color textSecondary = Color(0xFF94A3A0);
  static const Color textHint = Color(0xFF4B6B65);

  // Hari colors — tone hijau/teal semua
  static const Map<String, Color> hariColors = {
    'Senin':  Color(0xFF2DD4BF),
    'Selasa': Color(0xFF34D399),
    'Rabu':   Color(0xFF6EE7B7),
    'Kamis':  Color(0xFF10B981),
    'Jumat':  Color(0xFF059669),
    'Sabtu':  Color(0xFF0F9688),
  };

  // Card color palette (mint variants + accent)
  static const List<String> cardColors = [
    '#2DD4BF',
    '#34D399',
    '#10B981',
    '#059669',
    '#0F9688',
    '#6EE7B7',
    '#A7F3D0',
    '#0D9488',
    '#14B8A6',
    '#0891B2',
  ];

  // Gradient utama
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF0F9688)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0F0E), Color(0xFF111A17), Color(0xFF162220)],
  );
}

class AppConstants {
  static const List<String> hariList = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu',
  ];

  static const List<String> semesterList = [
    'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4',
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8',
  ];

  static String getDayOfWeekName() {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[now.weekday - 1];
  }
}
