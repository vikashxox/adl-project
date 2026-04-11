import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';

class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.loginWithCredentials(
      username: username,
      password: password,
      onError: (msg) {
        if (mounted) setState(() { _error = msg; _loading = false; });
      },
    );

    if (!mounted) return;
    if (result == null) return; // error already set

    if (result.role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/officer-dashboard');
    }
  }

  bool get _canSubmit =>
      _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text('Back',
                      style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 16),
                const Text('Officer Login',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Secure access for state agency officers',
                    style: TextStyle(color: Colors.green[100], fontSize: 13)),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user,
                        size: 40, color: AppTheme.green600),
                  ),
                  const SizedBox(height: 32),

                  // Username
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Username',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray700)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter your username',
                      prefixIcon:
                          Icon(Icons.person_outline, color: AppTheme.gray400),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray700)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppTheme.gray400),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.gray400,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.red600.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.red600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.red600, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Login Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _canSubmit ? AppGradients.greenHeader : null,
                      color: _canSubmit ? null : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _canSubmit && !_loading ? _handleSubmit : null,
                      style: AppTheme.elevatedOnGradient(),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Secure Login'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user,
                            color: AppTheme.amber600, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Security Notice',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF78350F))),
                              SizedBox(height: 6),
                              Text(
                                'Your login activity is monitored for security purposes. '
                                'Never share your credentials with anyone.',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
