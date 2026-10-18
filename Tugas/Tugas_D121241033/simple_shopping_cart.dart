// SIMPLE SHOPPING CART

// Konstanta batas diskon
const int batasDiskonBesar = 500000;
const int batasDiskonKecil = 200000;
const int diskonBesar = 10;
const int diskonKecil = 5;

// Function menghitung subtotal produk
int hitungSubtotal(int harga, int jumlah) {
  return harga * jumlah;
}

// Function menentukan diskon
int tentukanDiskon(int subtotal) {
  if (subtotal >= batasDiskonBesar) {
    return diskonBesar;
  } else if (subtotal >= batasDiskonKecil) {
    return diskonKecil;
  } else {
    return 0;
  }
}

// Function menghitung nominal diskon
int hitungDiskon(int subtotal, int persen) {
  return subtotal * persen ~/ 100;
}

// Function format rupiah
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

// PROGRAM UTAMA
void main() {

  // Data keranjang belanja
  List<Map<String, dynamic>> keranjang = [
    {'nama': 'Laptop', 'harga': 7500000, 'jumlah': 1},
    {'nama': 'Mouse', 'harga': 150000, 'jumlah': 2},
    {'nama': 'Keyboard', 'harga': 250000, 'jumlah': 1},
    {'nama': 'Headset', 'harga': 175000, 'jumlah': 1},
    {'nama': 'Flashdisk', 'harga': 75000, 'jumlah': 2},
  ];

  int subtotal = 0;
  int totalItem = 0;

  print('========== SIMPLE SHOPPING CART ==========\n');

  print('No  Produk       Harga         Qty  Subtotal');
  print('-------------------------------------------');

  // Menampilkan produk
  for (int i = 0; i < keranjang.length; i++) {

    Map<String, dynamic> produk = keranjang[i];

    String nama = produk['nama'];
    int harga = produk['harga'];
    int jumlah = produk['jumlah'];

    int subtotalProduk = hitungSubtotal(harga, jumlah);

    subtotal += subtotalProduk;
    totalItem += jumlah;

    print(
      '${(i + 1).toString().padRight(4)}'
      '${nama.padRight(13)}'
      '${formatRupiah(harga).padRight(14)}'
      '${jumlah.toString().padRight(5)}'
      '${formatRupiah(subtotalProduk)}'
    );
  }

  // Menghitung diskon
  int persenDiskon = tentukanDiskon(subtotal);
  int nominalDiskon = hitungDiskon(subtotal, persenDiskon);

  int totalBayar = subtotal - nominalDiskon;

  // Menampilkan ringkasan belanja
  print('-------------------------------------------');
  print('Total item      : $totalItem barang');
  print('Subtotal        : ${formatRupiah(subtotal)}');
  print('Diskon          : $persenDiskon%');
  print('Nominal diskon  : ${formatRupiah(nominalDiskon)}');
  print('Total bayar     : ${formatRupiah(totalBayar)}');
  print('===========================================');
}
