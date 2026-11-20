import 'package:crypto_market_id/models/crypto_coin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CryptoCoin.fromJson', () {
    test('memetakan nilai pasar dan sparkline', () {
      final coin = CryptoCoin.fromJson({
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'btc',
        'image': 'https://example.com/bitcoin.png',
        'current_price': 68000,
        'market_cap': 1300000000000,
        'price_change_percentage_24h': -1.25,
        'sparkline_in_7d': {'price': [10, 11.5, 9]},
        'last_updated': '2025-01-01T00:00:00Z',
      });

      expect(coin.id, 'bitcoin');
      expect(coin.symbol, 'BTC');
      expect(coin.currentPrice, 68000);
      expect(coin.marketCap, 1300000000000);
      expect(coin.priceChangePercentage24h, -1.25);
      expect(coin.sparklinePrices, [10, 11.5, 9]);
      expect(coin.lastUpdated, isNotNull);
      expect(() => coin.sparklinePrices.add(12), throwsUnsupportedError);
    });

    test('menangani nilai hilang, null, dan tipe yang tidak dikenal dengan aman', () {
      final coin = CryptoCoin.fromJson({
        'id': null,
        'name': null,
        'symbol': 42,
        'current_price': null,
        'market_cap': 'bukan angka',
        'price_change_percentage_24h': false,
        'sparkline_in_7d': {'price': [1, null, '2']},
        'last_updated': 'tanggal tidak valid',
      });

      expect(coin.id, isEmpty);
      expect(coin.name, 'Tidak diketahui');
      expect(coin.symbol, '—');
      expect(coin.currentPrice, isNull);
      expect(coin.marketCap, isNull);
      expect(coin.priceChangePercentage24h, isNull);
      expect(coin.sparklinePrices, [1]);
      expect(coin.lastUpdated, isNull);
    });
  });
}
