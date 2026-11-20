//  STUDENT GRADE TRACKER


// Konstanta (variable yang nilainya tetap)
const int totalPertemuan = 16;      // jumlah pertemuan dalam 1 semester
const double minNilaiLulus = 60.0;  // nilai akhir minimal untuk lulus
const double minKehadiran = 75.0;   // persentase kehadiran minimal (%)

// Function untuk mengolah data

// Menghitung nilai akhir dengan bobot: Tugas 30%, UTS 30%, UAS 40%
double hitungNilaiAkhir(double tugas, double uts, double uas) {
  return (tugas * 0.3) + (uts * 0.3) + (uas * 0.4);
}

// Mengubah jumlah kehadiran menjadi persentase
double hitungPersentaseKehadiran(int jumlahHadir) {
  return (jumlahHadir / totalPertemuan) * 100;
}

// Menentukan grade berdasarkan nilai akhir
String tentukanGrade(double nilai) {
  if (nilai >= 85) {
    return 'A';
  } else if (nilai >= 75) {
    return 'B';
  } else if (nilai >= 60) {
    return 'C';
  } else if (nilai >= 50) {
    return 'D';
  } else {
    return 'E';
  }
}

// Menentukan status kelulusan berdasarkan nilai dan kehadiran
String tentukanStatus(double nilai, double kehadiran) {
  bool nilaiCukup = nilai >= minNilaiLulus;
  bool hadirCukup = kehadiran >= minKehadiran;

  if (nilaiCukup && hadirCukup) {
    return 'LULUS';
  } else if (!nilaiCukup && !hadirCukup) {
    return 'TIDAK LULUS (nilai & kehadiran kurang)';
  } else if (!hadirCukup) {
    return 'TIDAK LULUS (kehadiran kurang)';
  } else {
    return 'TIDAK LULUS (nilai kurang)';
  }
}

// Program utama
void main() {
  // Data mahasiswa disimpan dalam List berisi Map
  List<Map<String, dynamic>> daftarMahasiswa = [
    {'nama': 'Andi',  'tugas': 88.0, 'uts': 82.0, 'uas': 90.0, 'hadir': 15},
    {'nama': 'Budi',  'tugas': 75.0, 'uts': 70.0, 'uas': 68.0, 'hadir': 14},
    {'nama': 'Citra', 'tugas': 92.0, 'uts': 88.0, 'uas': 85.0, 'hadir': 11},
    {'nama': 'Dewi',  'tugas': 50.0, 'uts': 45.0, 'uas': 55.0, 'hadir': 13},
    {'nama': 'Eko',   'tugas': 80.0, 'uts': 78.0, 'uas': 82.0, 'hadir': 16},
    {'nama': 'Fajar', 'tugas': 40.0, 'uts': 35.0, 'uas': 30.0, 'hadir': 9},
  ];

  int jumlahLulus = 0;
  double totalNilaiKelas = 0;

  print('=========== STUDENT GRADE TRACKER ===========\n');

  // Loop untuk memproses setiap mahasiswa
  for (int i = 0; i < daftarMahasiswa.length; i++) {
    Map<String, dynamic> mhs = daftarMahasiswa[i];

    String nama = mhs['nama'];
    double nilaiAkhir = hitungNilaiAkhir(
      mhs['tugas'] as double,
      mhs['uts'] as double,
      mhs['uas'] as double,
    );
    double kehadiran = hitungPersentaseKehadiran(mhs['hadir'] as int);
    String grade = tentukanGrade(nilaiAkhir);
    String status = tentukanStatus(nilaiAkhir, kehadiran);

    // Akumulasi untuk ringkasan kelas
    totalNilaiKelas += nilaiAkhir;
    if (status == 'LULUS') {
      jumlahLulus++;
    }

    print('${i + 1}. $nama');
    print('   Nilai Akhir : ${nilaiAkhir.toStringAsFixed(1)}');
    print('   Kehadiran   : ${mhs['hadir']}/$totalPertemuan '
        '(${kehadiran.toStringAsFixed(1)}%)');
    print('   Grade       : $grade');
    print('   Status      : $status\n');
  }

  // Ringkasan kelas
  int jumlahMahasiswa = daftarMahasiswa.length;
  double rataRata = totalNilaiKelas / jumlahMahasiswa;
  int jumlahTidakLulus = jumlahMahasiswa - jumlahLulus;

  print('================= RINGKASAN =================');
  print('Jumlah mahasiswa : $jumlahMahasiswa');
  print('Rata-rata kelas  : ${rataRata.toStringAsFixed(2)}');
  print('Lulus            : $jumlahLulus');
  print('Tidak lulus      : $jumlahTidakLulus');
}