import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/jadwal_model.dart';
import '../utils/constants.dart';

class JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JadwalCard({
    super.key,
    required this.jadwal,
    required this.onEdit,
    required this.onDelete,
  });

  Color _hexToColor(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(jadwal.warna);
    final hariColor = AppColors.hariColors[jadwal.hari] ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(jadwal.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.42,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppColors.bgSurface,
              foregroundColor: AppColors.primary,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              padding: EdgeInsets.zero,
            ),
            SlidableAction(
              onPressed: (_) => _showDeleteDialog(context),
              backgroundColor: const Color(0xFF2A1A1A),
              foregroundColor: Colors.redAccent,
              icon: Icons.delete_rounded,
              label: 'Hapus',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(50), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Accent bar dengan gradient
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [color, color.withAlpha(100)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                jadwal.mataKuliah,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Hari badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: hariColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: hariColor.withAlpha(100), width: 1),
                              ),
                              child: Text(
                                jadwal.hari,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: hariColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Menu Tiga Titik untuk Edit & Hapus
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit();
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context);
                                }
                              },
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 100),
                              color: AppColors.bgCardLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.primary.withAlpha(40),
                                  width: 1,
                                ),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_rounded,
                                          color: AppColors.primary, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_rounded,
                                          color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hapus',
                                        style: GoogleFonts.poppins(
                                          color: Colors.redAccent,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Dosen
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                jadwal.dosen,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Chips row
                        Row(
                          children: [
                            _chip(Icons.schedule_rounded,
                                '${jadwal.jamMulai} – ${jadwal.jamSelesai}', color),
                            const SizedBox(width: 6),
                            _chip(Icons.room_rounded, jadwal.ruangan, color),
                            const Spacer(),
                            // Notif indicator
                            if (jadwal.aktifNotif)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Semester badge
                        Text(
                          jadwal.semester,
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
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
          'Jadwal "${jadwal.mataKuliah}" akan dihapus permanen.',
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
              onDelete();
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
}
