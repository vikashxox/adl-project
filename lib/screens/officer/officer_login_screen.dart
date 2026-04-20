import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/app_session.dart';

class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _officerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String _officerType = 'field'; // 'field' or 'admin'

  @override
  void dispose() {
    _officerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_officerIdController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      if (_officerType == 'admin') {
        AppSession.setAdmin();
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        AppSession.setOfficer(_officerIdController.text);
        Navigator.pushReplacementNamed(context, '/officer-dashboard');
      }
    }
  }

  bool get _canSubmit => _officerIdController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
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
                  label: const Text('Back', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 16),
                const Text('Officer Login',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Text('Secure access for state agency officers',
                    style: TextStyle(color: Colors.green[100], fontSize: 13)),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user, size: 40, color: AppTheme.green600),
                  ),
                  const SizedBox(height: 24),

                  // Officer Type Toggle
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Officer Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Field Officer',
                          selected: _officerType == 'field',
                          selectedColor: AppTheme.green600,
                          onTap: () => setState(() => _officerType = 'field'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeButton(
                          label: 'Admin',
                          selected: _officerType == 'admin',
                          selectedColor: AppTheme.purple600,
                          onTap: () => setState(() => _officerType = 'admin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Officer ID
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Officer ID',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _officerIdController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter your officer ID',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.gray400),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.gray400),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?',
                          style: TextStyle(fontSize: 12, color: AppTheme.green600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _canSubmit ? AppGradients.greenHeader : null,
                      color: _canSubmit ? null : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _handleSubmit : null,
                      style: AppTheme.elevatedOnGradient(),
                      child: const Text('Secure Login'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.verified_user, color: AppTheme.amber600, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Security Notice',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF78350F))),
                              const SizedBox(height: 16),
                              Text(
                                'Your login activity is monitored for security purposes. Never share your credentials with anyone.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
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

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          border: Border.all(color: selected ? selectedColor : AppTheme.gray200, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.gray700,
          ),
        ),
      ),
    );
  }
}
