class Jadwal {
  int? id;
  String mataKuliah;
  String dosen;
  String ruangan;
  String hari;
  String jamMulai;
  String jamSelesai;
  String semester;
  String warna; // hex color string
  bool aktifNotif;

  Jadwal({
    this.id,
    required this.mataKuliah,
    required this.dosen,
    required this.ruangan,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.semester,
    this.warna = '#6C63FF',
    this.aktifNotif = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mata_kuliah': mataKuliah,
      'dosen': dosen,
      'ruangan': ruangan,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'semester': semester,
      'warna': warna,
      'aktif_notif': aktifNotif ? 1 : 0,
    };
  }

  factory Jadwal.fromMap(Map<String, dynamic> map) {
    return Jadwal(
      id: map['id'],
      mataKuliah: map['mata_kuliah'],
      dosen: map['dosen'],
      ruangan: map['ruangan'],
      hari: map['hari'],
      jamMulai: map['jam_mulai'],
      jamSelesai: map['jam_selesai'],
      semester: map['semester'],
      warna: map['warna'] ?? '#6C63FF',
      aktifNotif: map['aktif_notif'] == 1,
    );
  }

  Jadwal copyWith({
    int? id,
    String? mataKuliah,
    String? dosen,
    String? ruangan,
    String? hari,
    String? jamMulai,
    String? jamSelesai,
    String? semester,
    String? warna,
    bool? aktifNotif,
  }) {
    return Jadwal(
      id: id ?? this.id,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      dosen: dosen ?? this.dosen,
      ruangan: ruangan ?? this.ruangan,
      hari: hari ?? this.hari,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      semester: semester ?? this.semester,
      warna: warna ?? this.warna,
      aktifNotif: aktifNotif ?? this.aktifNotif,
    );
  }
}
