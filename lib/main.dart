import 'package:flutter/material.dart';

void main() {
  runApp(const PakkaHomesApp());
}

class PakkaHomesApp extends StatelessWidget {
  const PakkaHomesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pakka Homes',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A6EBD),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pakka Homes')),
      body: const Center(
        child: Text('Welcome to Pakka Homes'),
      ),
    );
  }
}
