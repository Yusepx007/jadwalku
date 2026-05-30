import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/jadwal_model.dart';
import '../utils/constants.dart';
import '../utils/notification_helper.dart';
import '../widgets/jadwal_card.dart';
import 'tambah_jadwal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<Jadwal> _allJadwal = [];
  List<Jadwal> _filteredJadwal = [];
  String _selectedHari = 'Semua';
  late TabController _tabController;
  bool _isLoading = true;

  final List<String> _tabs = ['Semua', ...AppConstants.hariList];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadJadwal();

    final today = AppConstants.getDayOfWeekName();
    final idx = _tabs.indexOf(today);
    if (idx != -1) {
      _tabController.index = idx;
      _selectedHari = today;
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedHari = _tabs[_tabController.index];
        _filterJadwal();
      });
    }
  }

  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);
    try {
      final jadwal = await _db.getAllJadwal();
      setState(() {
        _allJadwal = jadwal;
        _filterJadwal();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _allJadwal = [];
        _filteredJadwal = [];
        _isLoading = false;
      });
    }
  }

  void _filterJadwal() {
    if (_selectedHari == 'Semua') {
      _filteredJadwal = List.from(_allJadwal);
    } else {
      _filteredJadwal = _allJadwal.where((j) => j.hari == _selectedHari).toList();
    }
  }

  Future<void> _deleteJadwal(Jadwal jadwal) async {
    await _db.deleteJadwal(jadwal.id!);
    // Batalkan notifikasi terjadwal untuk jadwal yang dihapus
    if (jadwal.id != null) {
      try {
        await NotificationHelper.cancelNotification(jadwal.id!);
      } catch (_) {}
    }
    _loadJadwal();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text('Jadwal ${jadwal.mataKuliah} dihapus',
                  style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi ☀️';
    if (h < 15) return 'Selamat Siang 🌤️';
    if (h < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 4),
              _buildStatsRow(),
              const SizedBox(height: 4),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : _filteredJadwal.isEmpty
                        ? _buildEmptyState()
                        : _buildJadwalList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'JadwalKu',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Avatar / logo icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final todayName = AppConstants.getDayOfWeekName();
    final todayCount = _allJadwal.where((j) => j.hari == todayName).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _statCard('📚', '${_allJadwal.length}', 'Total Jadwal'),
          const SizedBox(width: 12),
          _statCard('📅', '$todayCount', 'Hari Ini'),
          const SizedBox(width: 12),
          _statCard('🔔', '${_allJadwal.where((j) => j.aktifNotif).length}', 'Notif Aktif'),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withAlpha(40), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withAlpha(30), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
          insets: const EdgeInsets.symmetric(horizontal: 8),
          borderRadius: BorderRadius.circular(2),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: _tabs.map((h) => Tab(text: h)).toList(),
      ),
    );
  }

  Widget _buildJadwalList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _filteredJadwal.length,
      itemBuilder: (ctx, i) {
        final jadwal = _filteredJadwal[i];
        return JadwalCard(
          jadwal: jadwal,
          onEdit: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TambahJadwalScreen(jadwal: jadwal)),
            );
            _loadJadwal();
          },
          onDelete: () => _deleteJadwal(jadwal),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.5),
            ),
            child: Icon(Icons.event_note_rounded, size: 44,
                color: AppColors.primary.withAlpha(180)),
          ),
          const SizedBox(height: 20),
          Text('Belum ada jadwal',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Tap tombol + di bawah untuk\nmenambahkan jadwal kuliah',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          // Mini arrow indicator
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 32, color: AppColors.primary.withAlpha(130)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(100),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TambahJadwalScreen()),
              );
              _loadJadwal();
            },
            splashColor: Colors.white.withAlpha(40),
            highlightColor: Colors.white.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Tambah Jadwal',
                    style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
