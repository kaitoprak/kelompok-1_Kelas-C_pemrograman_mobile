import 'dart:async';
import 'dart:convert';

import 'package:crypto_market_id/services/coin_gecko_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CoinGeckoService', () {
    test('mengirim parameter pilihan dan mengembalikan data koin', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode([
          {
            'id': 'bitcoin',
            'name': 'Bitcoin',
            'symbol': 'btc',
            'image': 'https://example.com/btc.png',
            'current_price': 65000,
            'market_cap': 1200000,
            'price_change_percentage_24h': 2.5,
            'sparkline_in_7d': {'price': [1, 2]},
          }
        ]), 200);
      });
      final service = CoinGeckoService(client: client);

      final coins = await service.fetchTopCoins(currency: 'IDR');

      expect(requestedUri.path, '/api/v3/coins/markets');
      expect(requestedUri.queryParameters['vs_currency'], 'idr');
      expect(requestedUri.queryParameters['order'], 'market_cap_desc');
      expect(requestedUri.queryParameters['per_page'], '10');
      expect(requestedUri.queryParameters['sparkline'], 'true');
      expect(requestedUri.queryParameters['price_change_percentage'], '24h');
      expect(coins.single.name, 'Bitcoin');
      expect(coins.single.currentPrice, 65000);
      client.close();
    });

    test('menolak kode mata uang yang tidak valid tanpa request', () async {
      final service = CoinGeckoService(client: MockClient((_) async => http.Response('[]', 200)));

      await expectLater(
        service.fetchTopCoins(currency: 'US D'),
        throwsA(isA<MarketApiException>().having(
          (error) => error.kind,
          'kind',
          MarketFailureKind.data,
        )),
      );
    });

    test('mengelompokkan kegagalan jaringan', () async {
      final client = MockClient((_) async => throw http.ClientException('offline'));
      final service = CoinGeckoService(client: client);

      await expectLater(
        service.fetchTopCoins(currency: 'usd'),
        throwsA(isA<MarketApiException>().having(
          (error) => error.kind,
          'kind',
          MarketFailureKind.jaringan,
        )),
      );
      client.close();
    });

    test('membedakan timeout', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      final service = CoinGeckoService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        service.fetchTopCoins(currency: 'usd'),
        throwsA(isA<MarketApiException>().having(
          (error) => error.kind,
          'kind',
          MarketFailureKind.timeout,
        )),
      );
      client.close();
    });

    test('menangani status HTTP non-200 dan rate limit', () async {
      for (final status in [500, 429]) {
        final client = MockClient((_) async => http.Response('gagal', status));
        final service = CoinGeckoService(client: client);
        await expectLater(
          service.fetchTopCoins(currency: 'usd'),
          throwsA(isA<MarketApiException>()
              .having((error) => error.kind, 'kind', MarketFailureKind.respons)
              .having((error) => error.statusCode, 'statusCode', status)),
        );
        client.close();
      }
    });

    test('menangani JSON rusak atau respons kosong', () async {
      for (final body in ['{rusak', '[]']) {
        final client = MockClient((_) async => http.Response(body, 200));
        final service = CoinGeckoService(client: client);
        await expectLater(
          service.fetchTopCoins(currency: 'usd'),
          throwsA(isA<MarketApiException>().having(
            (error) => error.kind,
            'kind',
            MarketFailureKind.data,
          )),
        );
        client.close();
      }
    });
  });
}
