# Crypto Market ID

Aplikasi Flutter satu halaman untuk melihat 10 cryptocurrency teratas berdasarkan kapitalisasi pasar dari CoinGecko Public API.

## Menjalankan

Pastikan Flutter SDK tersedia, lalu jalankan:

```sh
flutter pub get
flutter run
```

API yang digunakan: `GET https://api.coingecko.com/api/v3/coins/markets` dengan `vs_currency`, `order=market_cap_desc`, `per_page=10`, `page=1`, `sparkline=true`, dan `price_change_percentage=24h`. Data grafik berasal dari `sparkline_in_7d` dalam respons yang sama; pilihan 24 jam dan 7 hari mengubah rentang titik yang ditampilkan tanpa permintaan API tambahan. API publik dapat menerapkan pembatasan permintaan.

## Pengujian

Jalankan `flutter test` untuk menguji parsing model dan service, termasuk kegagalan jaringan, timeout, respons HTTP, dan JSON.
