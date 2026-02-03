import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../home/pages/admin_home_page.dart';
import '../../home/pages/guru_home_page.dart';
import '../../home/pages/siswa_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loading = true;
    });

    try {
      final role = await _authService.loginAndGetRole(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Widget target;
      switch (role?.toLowerCase()) {
        case 'admin':
          target = const AdminHomePage();
          break;
        case 'guru':
          target = const GuruHomePage();
          break;
        case 'siswa':
          target = const SiswaHomePage();
          break;
        default:
          throw Exception('Role tidak dikenali');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target),
      );
    } catch (e) {
      final message = e.toString().toLowerCase();

      setState(() {
        if (message.contains('email') || message.contains('user-not-found')) {
          _emailError = 'Email salah';
        } else if (message.contains('password') ||
            message.contains('wrong-password')) {
          _passwordError = 'Password salah';
        } else {
          _passwordError = 'Gagal login, coba lagi';
        }
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // LEFT BACKGROUND (VISUAL)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF00ACC1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // RIGHT LOGIN FORM
          Expanded(
            flex: 2,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APP NAME',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // EMAIL
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText: _emailError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PASSWORD
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: _passwordError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // REMEMBER ME (UI ONLY)
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            }),
                          Text('Remember me'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
