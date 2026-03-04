import 'package:flutter/material.dart';
import 'screens/pos_screen.dart';

void main() {
  runApp(const CaisseApp());
}

class CaisseApp extends StatelessWidget {
  const CaisseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caisse POC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PosScreen(),
    );
  }
}
