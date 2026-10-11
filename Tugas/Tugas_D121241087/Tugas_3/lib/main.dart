import 'package:flutter/material.dart';

import 'ui/screens/market_screen.dart';

void main() {
  runApp(const CryptoMarketApp());
}

class CryptoMarketApp extends StatelessWidget {
  const CryptoMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750A4);
    return MaterialApp(
      title: 'Pasar Kripto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F6FA),
      cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const MarketScreen(),
    );
  }
}
