import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/inventory/data/repositories/inventory_repository_impl.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/inventory/presentation/screens/main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(InventoryRepositoryImpl()),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrosirKue Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MainScreen(),
    );
  }
}
