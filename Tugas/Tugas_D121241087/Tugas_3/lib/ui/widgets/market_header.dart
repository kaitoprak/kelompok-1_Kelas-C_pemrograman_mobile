import 'package:flutter/material.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({
    super.key,
    required this.currency,
    required this.onCurrencyChanged,
  });

  final String currency;
  final ValueChanged<String> onCurrencyChanged;

  static const _currencies = <String, String>{
    'usd': 'USD',
    'idr': 'IDR',
    'eur': 'EUR',
    'gbp': 'GBP',
    'jpy': 'JPY',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pasar Kripto',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currency,
                    dropdownColor: colorScheme.primary,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    items: _currencies.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onCurrencyChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Pantau aset digital teratas berdasarkan kapitalisasi pasar.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                '10 aset teratas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Data CoinGecko',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
