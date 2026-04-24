import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthProvider>().login(
            _emailController.text,
            _passwordController.text,
          );

      if (success && mounted) {
        // MainScreen is shown via AuthWrapper automatically
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login Gagal. Periksa kembali akun Anda.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna Cream/Beige
    const Color primaryCream = Color(0xFFD2B48C); // Tan / Deep Cream untuk elemen aktif
    const Color lightCream = Color(0xFFFFFDD0);    // Cream terang
    const Color softBeige = Color(0xFFF5F5DC);     // Beige lembut
    
    // Warna nuansa cokelat untuk blobs tetap dipertahankan namun disesuaikan
    const Color brownBlob1 = Color(0xFF8B4513); 
    const Color brownBlob2 = Color(0xFFA0522D); 
    const Color brownBlob3 = Color(0xFFDEB887); // BurlyWood

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Off-white/Creamy background
      body: Stack(
        children: [
          // 1. Background Blobs
          Positioned(
            left: -80,
            top: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: brownBlob1.withOpacity(0.15), 
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -100,
            top: 140,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: brownBlob2.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: brownBlob3.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Global Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. Floating Decorations
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Transform.rotate(
              angle: -3 * 3.14159 / 180,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: primaryCream.withOpacity(0.2)),
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),

          // 4. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Logo/Icon dengan warna Cream
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryCream, Color(0xFFC19A6B)], // Latte gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCream.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.cookie, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TOKO GROSIR KUE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: Colors.brown.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk penerimaan barang',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: Color(0xFF3E2723), // Dark brown text
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Akses panel admin untuk mencatat bon supplier dan stok masuk harian.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.brown.shade700.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Login Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Login Admin',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2723),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildInputLabel('Email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _buildInputDecoration(
                                  hint: 'admin@toko.com',
                                  icon: Icons.mail_outline,
                                  color: primaryCream,
                                ),
                                validator: (value) => (value == null || !value.contains('@'))
                                    ? 'Masukkan email yang valid'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildInputLabel('Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _buildInputDecoration(
                                  hint: 'Masukkan password',
                                  icon: Icons.lock_outline,
                                  color: primaryCream,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: primaryCream,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value == null || value.length < 4)
                                    ? 'Password minimal 4 karakter'
                                    : null,
                              ),
                              const SizedBox(height: 30),
                              Consumer<AuthProvider>(
                                builder: (context, auth, child) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryCream,
                                        foregroundColor: Colors.white,
                                        elevation: 6,
                                        shadowColor: primaryCream.withOpacity(0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Masuk',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5D4037),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required Color color,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.brown.shade200, fontSize: 15),
      prefixIcon: Icon(icon, size: 22, color: color.withOpacity(0.7)),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      filled: true,
      fillColor: const Color(0xFFFFFFF0), // Ivory/Cream white
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.brown.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.brown.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}

