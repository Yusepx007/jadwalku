import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/jadwal_model.dart';
import '../utils/constants.dart';
import '../utils/notification_helper.dart';

class TambahJadwalScreen extends StatefulWidget {
  final Jadwal? jadwal;
  const TambahJadwalScreen({super.key, this.jadwal});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  late TextEditingController _matkulCtrl;
  late TextEditingController _dosenCtrl;
  late TextEditingController _ruanganCtrl;
  late TextEditingController _pengingatCtrl;

  String _selectedHari = 'Senin';
  String _selectedSemester = 'Semester 1';
  String _selectedWarna = '#2DD4BF';
  TimeOfDay _jamMulai = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 9, minute: 40);
  bool _aktifNotif = true;
  int _pengingatMenit = 15;
  bool _isLoading = false;

  bool get _isEdit => widget.jadwal != null;

  @override
  void initState() {
    super.initState();
    final j = widget.jadwal;
    _matkulCtrl = TextEditingController(text: j?.mataKuliah ?? '');
    _dosenCtrl = TextEditingController(text: j?.dosen ?? '');
    _ruanganCtrl = TextEditingController(text: j?.ruangan ?? '');
    _pengingatMenit = j?.pengingatMenit ?? 15;
    _pengingatCtrl = TextEditingController(text: _pengingatMenit.toString());
    if (j != null) {
      _selectedHari = j.hari;
      _selectedSemester = j.semester;
      _selectedWarna = j.warna;
      _aktifNotif = j.aktifNotif;
      final mp = j.jamMulai.split(':');
      final sp = j.jamSelesai.split(':');
      _jamMulai = TimeOfDay(hour: int.parse(mp[0]), minute: int.parse(mp[1]));
      _jamSelesai = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
    }
  }

  @override
  void dispose() {
    _matkulCtrl.dispose();
    _dosenCtrl.dispose();
    _ruanganCtrl.dispose();
    _pengingatCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: AppColors.bgCard,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isMulai ? _jamMulai = picked : _jamSelesai = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final menitVal = int.tryParse(_pengingatCtrl.text.trim()) ?? 15;

    final jadwal = Jadwal(
      id: widget.jadwal?.id,
      mataKuliah: _matkulCtrl.text.trim(),
      dosen: _dosenCtrl.text.trim(),
      ruangan: _ruanganCtrl.text.trim(),
      hari: _selectedHari,
      jamMulai: _fmt(_jamMulai),
      jamSelesai: _fmt(_jamSelesai),
      semester: _selectedSemester,
      warna: _selectedWarna,
      aktifNotif: _aktifNotif,
      pengingatMenit: menitVal,
    );

    try {
      if (_isEdit) {
        await _db.updateJadwal(jadwal);
        // Batalkan notifikasi lama lalu jadwalkan ulang jika perlu
        if (jadwal.id != null) {
          await NotificationHelper.cancelNotification(jadwal.id!);
        }
        if (_aktifNotif) {
          await NotificationHelper.scheduleWeeklyNotification(jadwal);
        }
      } else {
        final newId = await _db.insertJadwal(jadwal);
        // Jadwalkan notifikasi dengan id yang baru
        if (_aktifNotif) {
          final jadwalWithId = jadwal.copyWith(id: newId);
          await NotificationHelper.scheduleWeeklyNotification(jadwalWithId);
        }
      }
    } catch (_) {
      // Notifikasi gagal tidak boleh crash app
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  }

  Future<void> _delete() async {
    if (widget.jadwal?.id == null) return;
    setState(() => _isLoading = true);
    try {
      await _db.deleteJadwal(widget.jadwal!.id!);
      await NotificationHelper.cancelNotification(widget.jadwal!.id!);
    } catch (_) {}
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primary.withAlpha(40)),
        ),
        title: Text('Hapus Jadwal?',
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Jadwal "${widget.jadwal?.mataKuliah}" akan dihapus permanen.',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Hapus',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewCard(),
                        const SizedBox(height: 24),
                        _buildSection('Informasi Mata Kuliah', Icons.book_rounded),
                        const SizedBox(height: 12),
                        _buildTextField(_matkulCtrl, 'Nama Mata Kuliah',
                            Icons.book_outlined, (v) => v!.isEmpty ? 'Wajib diisi' : null),
                        const SizedBox(height: 10),
                        _buildTextField(_dosenCtrl, 'Nama Dosen',
                            Icons.person_outline_rounded, (v) => v!.isEmpty ? 'Wajib diisi' : null),
                        const SizedBox(height: 10),
                        _buildTextField(_ruanganCtrl, 'Ruangan / Kelas',
                            Icons.location_on_outlined, (v) => v!.isEmpty ? 'Wajib diisi' : null),
                        const SizedBox(height: 24),
                        _buildSection('Waktu & Hari', Icons.schedule_rounded),
                        const SizedBox(height: 12),
                        _buildHariSelector(),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildTimeTile(true)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTimeTile(false)),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Semester', Icons.school_rounded),
                        const SizedBox(height: 12),
                        _buildSemesterDropdown(),
                        const SizedBox(height: 24),
                        _buildSection('Warna Label', Icons.palette_rounded),
                        const SizedBox(height: 12),
                        _buildColorPicker(),
                        const SizedBox(height: 20),
                        _buildNotifToggle(),
                        const SizedBox(height: 28),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Badge edit/tambah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: Text(
              _isEdit ? 'Edit' : 'Baru',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          if (_isEdit) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showDeleteConfirmDialog,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withAlpha(80)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final color = _hexToColor(_selectedWarna);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color, color.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: color.withAlpha(100), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.book_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _matkulCtrl.text.isEmpty ? 'Nama Mata Kuliah' : _matkulCtrl.text,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _dosenCtrl.text.isEmpty ? 'Nama Dosen' : _dosenCtrl.text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.schedule_rounded, '${_fmt(_jamMulai)} – ${_fmt(_jamSelesai)}'),
              _chip(Icons.room_rounded,
                  _ruanganCtrl.text.isEmpty ? 'Ruangan' : _ruanganCtrl.text),
              _chip(Icons.calendar_today_rounded, _selectedHari),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            )),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(30), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildHariSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.hariList.map((hari) {
        final isSelected = _selectedHari == hari;
        final color = AppColors.hariColors[hari] ?? AppColors.primary;
        return GestureDetector(
          onTap: () => setState(() => _selectedHari = hari),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : color.withAlpha(60),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withAlpha(80), blurRadius: 8)]
                  : [],
            ),
            child: Text(
              hari,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeTile(bool isMulai) {
    final t = isMulai ? _jamMulai : _jamSelesai;
    return GestureDetector(
      onTap: () => _pickTime(isMulai),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withAlpha(40), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMulai ? 'Jam Mulai' : 'Jam Selesai',
              style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textHint),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isMulai ? Icons.play_circle_outline_rounded : Icons.stop_circle_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _fmt(t),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(40), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSemester,
          isExpanded: true,
          dropdownColor: AppColors.bgCardLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
          items: AppConstants.semesterList
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSemester = v!),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.cardColors.map((hex) {
        final color = _hexToColor(hex);
        final isSelected = _selectedWarna == hex;
        return GestureDetector(
          onTap: () => setState(() => _selectedWarna = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withAlpha(160), blurRadius: 10, spreadRadius: 1)]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  String get _pengingatText {
    final text = _pengingatCtrl.text.trim();
    if (text.isEmpty) return 'Tentukan waktu pengingat';
    final val = int.tryParse(text);
    if (val == null || val < 0) return 'Input menit tidak valid';
    if (val == 0) return 'Tepat waktu saat kuliah dimulai';
    if (val == 60) return '1 jam sebelum kuliah dimulai';
    if (val % 60 == 0) {
      final jam = val ~/ 60;
      return '$jam jam sebelum kuliah dimulai';
    }
    return '$val menit sebelum kuliah dimulai';
  }

  Widget _buildNotifToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _aktifNotif ? AppColors.primary.withAlpha(80) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _aktifNotif
                      ? AppColors.primary.withAlpha(30)
                      : AppColors.textHint.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _aktifNotif
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: _aktifNotif ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengingat Notifikasi',
                        style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(_pengingatText,
                        style: GoogleFonts.poppins(
                            color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: _aktifNotif,
                onChanged: (v) => setState(() => _aktifNotif = v),
                activeThumbColor: Colors.black,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.textHint,
                inactiveTrackColor: AppColors.bgSurface,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.primary.withAlpha(30);
                  }
                  return Colors.transparent;
                }),
              ),
            ],
          ),
          if (_aktifNotif) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.primary.withAlpha(30),
            ),
            const SizedBox(height: 16),
            Text(
              'Waktu Pengingat (Menit Sebelum Mulai):',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pengingatCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (val) {
                final n = int.tryParse(val.trim());
                if (n != null && n >= 0) {
                  setState(() {
                    _pengingatMenit = n;
                  });
                } else {
                  setState(() {});
                }
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return 'Masukkan angka menit yang valid';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Contoh: 15',
                hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.bgCardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary.withAlpha(20), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await NotificationHelper.showTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                            Text('Mengirimkan notifikasi tes...',
                                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  'Uji Coba Notifikasi (Kirim Sekarang)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withAlpha(20),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _save,
              splashColor: Colors.white.withAlpha(40),
              highlightColor: Colors.white.withAlpha(20),
              child: SizedBox(
                height: 56,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_circle_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal',
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
