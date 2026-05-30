import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jadwal_model.dart';

/// Database helper berbasis SharedPreferences agar bekerja di semua platform
/// (web, Android, iOS, desktop) tanpa perlu sqflite.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _key = 'jadwal_list';

  // ─── Ambil semua jadwal ──────────────────────────────────────────────────
  Future<List<Jadwal>> getAllJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
    final list = decoded
        .map((e) => Jadwal.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Sort: hari → jam_mulai
    const hariOrder = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    list.sort((a, b) {
      final ha = hariOrder.indexOf(a.hari);
      final hb = hariOrder.indexOf(b.hari);
      if (ha != hb) return ha.compareTo(hb);
      return a.jamMulai.compareTo(b.jamMulai);
    });

    return list;
  }

  // ─── Ambil jadwal berdasarkan hari ──────────────────────────────────────
  Future<List<Jadwal>> getJadwalByHari(String hari) async {
    final all = await getAllJadwal();
    return all.where((j) => j.hari == hari).toList();
  }

  // ─── Tambah jadwal baru ─────────────────────────────────────────────────
  Future<int> insertJadwal(Jadwal jadwal) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllJadwal();

    // Generate id baru
    final newId = list.isEmpty
        ? 1
        : list.map((j) => j.id ?? 0).reduce(max) + 1;

    final newJadwal = jadwal.copyWith(id: newId);
    list.add(newJadwal);
    await _saveList(prefs, list);
    return newId;
  }

  // ─── Update jadwal ──────────────────────────────────────────────────────
  Future<int> updateJadwal(Jadwal jadwal) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllJadwal();

    final idx = list.indexWhere((j) => j.id == jadwal.id);
    if (idx == -1) return 0;
    list[idx] = jadwal;
    await _saveList(prefs, list);
    return 1;
  }

  // ─── Hapus jadwal ───────────────────────────────────────────────────────
  Future<int> deleteJadwal(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllJadwal();

    final before = list.length;
    list.removeWhere((j) => j.id == id);
    await _saveList(prefs, list);
    return before - list.length;
  }

  // ─── Hitung jumlah jadwal ───────────────────────────────────────────────
  Future<int> countJadwal() async {
    final list = await getAllJadwal();
    return list.length;
  }

  // ─── Simpan list ke SharedPreferences ──────────────────────────────────
  Future<void> _saveList(SharedPreferences prefs, List<Jadwal> list) async {
    // Pastikan id selalu disertakan saat serialisasi
    final encoded = list.map((j) {
      final map = j.toMap();
      if (j.id != null) map['id'] = j.id;
      return map;
    }).toList();
    await prefs.setString(_key, jsonEncode(encoded));
  }

  // ─── Reset / hapus semua data (untuk testing) ──────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
