import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/inventory/data/repositories/inventory_repository_impl.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/inventory/presentation/screens/main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, InventoryProvider>(
          create: (context) => InventoryProvider(InventoryRepositoryImpl()),
          update: (context, auth, inventory) {
            // Re-initialize inventory when login status changes
            if (auth.isLoggedIn && inventory != null) {
              inventory.init();
            }
            return inventory!;
          },
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoggedIn) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
