/// Nilai pasar sebuah koin sebagaimana dikirim endpoint CoinGecko markets.
class CryptoCoin {
  const CryptoCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.imageUrl,
    required this.currentPrice,
    required this.marketCap,
    required this.priceChangePercentage24h,
    required this.sparklinePrices,
    required this.lastUpdated,
  });

  final String id;
  final String name;
  final String symbol;
  final String imageUrl;
  final double? currentPrice;
  final double? marketCap;
  final double? priceChangePercentage24h;
  final List<double> sparklinePrices;
  final DateTime? lastUpdated;

  factory CryptoCoin.fromJson(Map<String, dynamic> json) {
    final sparkline = json['sparkline_in_7d'];
    final rawPrices = sparkline is Map<String, dynamic>
        ? sparkline['price']
        : null;
    final prices = rawPrices is List
        ? rawPrices.whereType<num>().map((value) => value.toDouble()).toList()
        : <double>[];
    final updated = json['last_updated'];

    return CryptoCoin(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : 'Tidak diketahui',
      symbol: json['symbol'] is String
          ? (json['symbol'] as String).toUpperCase()
          : '—',
      imageUrl: json['image'] is String ? json['image'] as String : '',
      currentPrice: _numberOrNull(json['current_price']),
      marketCap: _numberOrNull(json['market_cap']),
      priceChangePercentage24h:
          _numberOrNull(json['price_change_percentage_24h']),
      sparklinePrices: List.unmodifiable(prices),
      lastUpdated: updated is String ? DateTime.tryParse(updated) : null,
    );
  }

  static double? _numberOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
