//  SIMPLE SHOPPING CART


// Ketentuan diskon (konstanta)
const int batasDiskonBesar = 500000;
const int batasDiskonKecil = 200000;
const int persenDiskonBesar = 10;
const int persenDiskonKecil = 5;

// Function untuk mengolah perhitungan 

// Menghitung subtotal satu produk (harga x jumlah)
int hitungSubtotalProduk(int harga, int jumlah) {
  return harga * jumlah;
}

// Menentukan persentase diskon berdasarkan total belanja
int tentukanPersenDiskon(int totalBelanja) {
  if (totalBelanja >= batasDiskonBesar) {
    return persenDiskonBesar;
  } else if (totalBelanja >= batasDiskonKecil) {
    return persenDiskonKecil;
  } else {
    return 0;
  }
}

// Menghitung nominal diskon dalam rupiah
int hitungNominalDiskon(int totalBelanja, int persen) {
  return totalBelanja * persen ~/ 100;
}

// Mengubah angka menjadi format rupiah, contoh: 556000 -> Rp556.000
String formatRupiah(int angka) {
  String teks = angka.toString();
  String hasil = '';
  int hitung = 0;

  for (int i = teks.length - 1; i >= 0; i--) {
    hasil = teks[i] + hasil;
    hitung++;
    if (hitung % 3 == 0 && i != 0) {
      hasil = '.' + hasil;
    }
  }
  return 'Rp$hasil';
}

// Program utama 
void main() {
  // Data produk disimpan dalam List berisi Map
  List<Map<String, dynamic>> keranjang = [
    {'nama': 'Buku Tulis',  'harga': 5000,   'jumlah': 10},
    {'nama': 'Pulpen',      'harga': 3000,   'jumlah': 12},
    {'nama': 'Tas Ransel',  'harga': 185000, 'jumlah': 1},
    {'nama': 'Botol Minum', 'harga': 45000,  'jumlah': 2},
    {'nama': 'Kalkulator',  'harga': 120000, 'jumlah': 1},
    {'nama': 'Flashdisk',   'harga': 75000,  'jumlah': 1},
  ];

  int subtotal = 0;
  int totalItem = 0;

  print('=============== SIMPLE SHOPPING CART ===============\n');
  print('No  Produk         Harga        Qty  Subtotal');
  print('----------------------------------------------------');

  // Loop untuk menampilkan setiap produk dan menjumlahkan subtotal
  for (int i = 0; i < keranjang.length; i++) {
    Map<String, dynamic> produk = keranjang[i];

    String nama = produk['nama'];
    int harga = produk['harga'];
    int jumlah = produk['jumlah'];
    int subtotalProduk = hitungSubtotalProduk(harga, jumlah);

    subtotal += subtotalProduk;
    totalItem += jumlah;

    print('${(i + 1).toString().padRight(4)}'
        '${nama.padRight(15)}'
        '${formatRupiah(harga).padRight(13)}'
        '${jumlah.toString().padRight(5)}'
        '${formatRupiah(subtotalProduk)}');
  }

  // Perhitungan diskon dan total
  int persenDiskon = tentukanPersenDiskon(subtotal);
  int nominalDiskon = hitungNominalDiskon(subtotal, persenDiskon);
  int totalBayar = subtotal - nominalDiskon;

  print('----------------------------------------------------');
  print('Total item      : $totalItem barang');
  print('Subtotal        : ${formatRupiah(subtotal)}');

  if (persenDiskon > 0) {
    print('Diskon ($persenDiskon%)    : -${formatRupiah(nominalDiskon)}');
  } else {
    print('Diskon          : Rp0 (belanja minimal '
        '${formatRupiah(batasDiskonKecil)} untuk dapat diskon)');
  }

  print('Total bayar     : ${formatRupiah(totalBayar)}');
  print('====================================================');
}