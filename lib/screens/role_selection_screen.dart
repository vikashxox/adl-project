import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/app_session.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Intentionally not clearing session here so back button doesn't log user out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield, size: 48, color: AppTheme.blue600),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loan Tracker',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppTheme.gray800),
                        ),
                        Text(
                          'Select Your Role',
                          style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Role Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Beneficiary',
                          description: 'Access your loan details and submit proof of utilization',
                          icon: Icons.person,
                          gradient: AppGradients.blueHeader,
                          borderColor: AppTheme.blue500,
                          onTap: () => Navigator.pushNamed(context, '/beneficiary-login'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _RoleCard(
                          title: 'State Agency / Officer',
                          description: 'Verify loan utilization and manage beneficiaries',
                          icon: Icons.manage_accounts,
                          gradient: AppGradients.greenHeader,
                          borderColor: AppTheme.green500,
                          onTap: () => Navigator.pushNamed(context, '/officer-login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Powered by Government of India',
                  style: TextStyle(fontSize: 11, color: AppTheme.gray500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _pressed ? widget.borderColor : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.gray800),
              ),
              const SizedBox(height: 16),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.gray600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
