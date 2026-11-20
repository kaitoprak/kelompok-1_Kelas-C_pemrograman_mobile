import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/crypto_coin.dart';

class CoinCard extends StatelessWidget {
  const CoinCard({
    super.key,
    required this.coin,
    required this.rank,
    required this.currency,
    required this.range,
  });

  final CryptoCoin coin;
  final int rank;
  final String currency;
  final String range;

  String _money(double? value) {
    if (value == null || !value.isFinite) return '—';
    final digits = currency.toLowerCase() == 'idr' || currency.toLowerCase() == 'jpy'
        ? 0
        : value.abs() < 1
            ? 6
            : 2;
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      name: currency.toUpperCase(),
      decimalDigits: digits,
    );
    return formatter.format(value);
  }

  List<double> get _visiblePrices {
    final points = coin.sparklinePrices;
    if (range == '24j' && points.length > 24) {
      return points.sublist(points.length - 24);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final change = coin.priceChangePercentage24h;
    final positive = change != null && change >= 0;
    final changeColor = positive ? const Color(0xFF15803D) : const Color(0xFFB42318);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('$rank', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                _CoinIcon(imageUrl: coin.imageUrl),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coin.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(coin.symbol, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(coin.currentPrice),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      change == null || !change.isFinite
                          ? '—'
                          : '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(color: change == null ? Colors.grey : changeColor,
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text('Kapitalisasi pasar', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Spacer(),
                Text(_money(coin.marketCap), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: _Sparkline(prices: _visiblePrices, color: changeColor),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(range == '24j' ? 'Pergerakan 24 jam' : 'Pergerakan 7 hari',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: SizedBox(
          width: 38,
          height: 38,
          child: imageUrl.isEmpty
              ? const ColoredBox(color: Color(0xFFEDE7F6), child: Icon(Icons.currency_bitcoin))
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFEDE7F6),
                    child: Icon(Icons.currency_bitcoin),
                  ),
                ),
        ),
      );
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.prices, required this.color});

  final List<double> prices;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (prices.length < 2) {
      return Center(
        child: Text('Grafik belum tersedia', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      );
    }
    return CustomPaint(
      painter: _SparklinePainter(prices: prices, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.prices, required this.color});

  final List<double> prices;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final valid = prices.where((value) => value.isFinite).toList();
    if (valid.length < 2) return;
    final minPrice = valid.reduce((a, b) => a < b ? a : b);
    final maxPrice = valid.reduce((a, b) => a > b ? a : b);
    final spread = maxPrice - minPrice;
    final path = Path();
    for (var i = 0; i < valid.length; i++) {
      final x = i / (valid.length - 1) * size.width;
      final normalized = spread == 0 ? 0.5 : (valid[i] - minPrice) / spread;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.prices != prices || oldDelegate.color != color;
}
