double hitungSubtotal(double harga, int jumlah) {
  return harga * jumlah;
}

double hitungDiskon(double subtotal) {
  if (subtotal >= 500000) {
    return subtotal * 0.10;
  } else if (subtotal >= 300000) {
    return subtotal * 0.05; 
  } else {
    return 0;
  }
}

double hitungTotal(double subtotal, double diskon) {
  return subtotal - diskon;
}

void main() {
  List<Map<String, dynamic>> produk = [
    {
      "nama": "Keyboard",
      "harga": 250000.0,
      "jumlah": 1,
    },
    {
      "nama": "Mouse",
      "harga": 150000.0,
      "jumlah": 2,
    },
    {
      "nama": "Headset",
      "harga": 200000.0,
      "jumlah": 1,
    },
  ];

  double subtotal = 0;

  print("==========================================");
  print("          SIMPLE SHOPPING CART");
  print("==========================================");

  for (var item in produk) {
    String nama = item["nama"];
    double harga = item["harga"];
    int jumlah = item["jumlah"];

    double subtotalProduk = hitungSubtotal(harga, jumlah);

    subtotal += subtotalProduk;

    print("\nProduk    : $nama");
    print("Harga     : Rp${harga.toStringAsFixed(0)}");
    print("Jumlah    : $jumlah");
    print("Subtotal  : Rp${subtotalProduk.toStringAsFixed(0)}");
    print("------------------------------------------");
  }

  double diskon = hitungDiskon(subtotal);

  double total = hitungTotal(subtotal, diskon);

  print("\n==========================================");
  print("Subtotal        : Rp${subtotal.toStringAsFixed(0)}");
  print("Diskon          : Rp${diskon.toStringAsFixed(0)}");
  print("Total Pembayaran: Rp${total.toStringAsFixed(0)}");
  print("==========================================");
}