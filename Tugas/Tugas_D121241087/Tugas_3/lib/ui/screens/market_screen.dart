import 'package:flutter/material.dart';

import '../../models/crypto_coin.dart';
import '../../services/coin_gecko_service.dart';
import '../widgets/coin_card.dart';
import '../widgets/market_header.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, this.service});

  final CoinGeckoService? service;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late final CoinGeckoService _service = widget.service ?? CoinGeckoService();
  List<CryptoCoin> _coins = const [];
  String _currency = 'usd';
  String _range = '24j';
  bool _loading = true;
  MarketApiException? _error;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchTopCoins(currency: _currency);
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _coins = result;
        _loading = false;
      });
    } on MarketApiException catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _error = const MarketApiException(
          MarketFailureKind.data,
          'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
        );
        _loading = false;
      });
    }
  }

  void _changeCurrency(String currency) {
    if (currency == _currency) return;
    setState(() => _currency = currency);
    _loadCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCoins,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: MarketHeader(
                  currency: _currency,
                  onCurrencyChanged: _changeCurrency,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Aset teratas',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '24j', label: Text('24 jam')),
                          ButtonSegment(value: '7h', label: Text('7 hari')),
                        ],
                        selected: {_range},
                        onSelectionChanged: (selection) =>
                            setState(() => _range = selection.first),
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading && _coins.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat data pasar…'),
                      ],
                    ),
                  ),
                )
              else if (_error != null && _coins.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorPanel(message: _error!.message, onRetry: _loadCoins),
                )
              else ...[
                if (_loading)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MaterialBanner(
                        content: Text(_error!.message),
                        actions: [
                          TextButton(onPressed: _loadCoins, child: const Text('Coba lagi')),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: _coins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => CoinCard(
                      coin: _coins[index],
                      rank: index + 1,
                      currency: _currency,
                      range: _range,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('Data belum dapat dimuat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
}
