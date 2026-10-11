import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/crypto_coin.dart';

enum MarketFailureKind { jaringan, timeout, respons, data }

/// Kesalahan yang aman untuk ditampilkan UI, dengan kategori untuk penanganan.
class MarketApiException implements Exception {
  const MarketApiException(this.kind, this.message, {this.statusCode});

  final MarketFailureKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Satu-satunya lapisan aplikasi yang melakukan permintaan HTTP.
class CoinGeckoService {
  CoinGeckoService({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('api.coingecko.com', '/api/v3/coins/markets');
  final http.Client _client;
  final Duration timeout;

  /// Meminta sepuluh koin teratas. API juga menyertakan sparkline tujuh hari.
  Future<List<CryptoCoin>> fetchTopCoins({required String currency}) async {
    final normalizedCurrency = currency.trim().toLowerCase();
    if (!RegExp(r'^[a-z]{3,5}$').hasMatch(normalizedCurrency)) {
      throw const MarketApiException(
        MarketFailureKind.data,
        'Mata uang yang dipilih tidak valid.',
      );
    }

    final uri = _baseUri.replace(queryParameters: {
      'vs_currency': normalizedCurrency,
      'order': 'market_cap_desc',
      'per_page': '10',
      'page': '1',
      'sparkline': 'true',
      'price_change_percentage': '24h',
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const MarketApiException(
        MarketFailureKind.timeout,
        'Permintaan terlalu lama. Periksa koneksi internet lalu coba lagi.',
      );
    } on http.ClientException {
      throw const MarketApiException(
        MarketFailureKind.jaringan,
        'Tidak dapat terhubung ke layanan data. Periksa koneksi internet Anda.',
      );
    } catch (error) {
      if (error is MarketApiException) rethrow;
      throw const MarketApiException(
        MarketFailureKind.jaringan,
        'Terjadi gangguan saat menghubungi layanan data. Coba lagi.',
      );
    }

    if (response.statusCode != 200) {
      throw MarketApiException(
        MarketFailureKind.respons,
        response.statusCode == 429
            ? 'Layanan sedang membatasi permintaan. Tunggu sebentar lalu coba lagi.'
            : 'Layanan data mengembalikan kesalahan (${response.statusCode}). Coba lagi nanti.',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Respons bukan daftar koin.');
      }
      final coins = decoded
          .whereType<Map<String, dynamic>>()
          .map(CryptoCoin.fromJson)
          .toList(growable: false);
      if (coins.isEmpty) {
        throw const FormatException('Respons tidak berisi data koin.');
      }
      return List.unmodifiable(coins);
    } on FormatException {
      throw const MarketApiException(
        MarketFailureKind.data,
        'Format data dari layanan tidak dapat dibaca. Silakan coba lagi.',
      );
    } catch (_) {
      throw const MarketApiException(
        MarketFailureKind.data,
        'Data pasar tidak lengkap atau tidak valid. Silakan coba lagi.',
      );
    }
  }
}
