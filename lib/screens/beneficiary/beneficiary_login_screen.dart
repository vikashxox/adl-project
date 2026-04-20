import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';
import '../../services/app_session.dart';

class BeneficiaryLoginScreen extends StatefulWidget {
  const BeneficiaryLoginScreen({super.key});

  @override
  State<BeneficiaryLoginScreen> createState() => _BeneficiaryLoginScreenState();
}

class _BeneficiaryLoginScreenState extends State<BeneficiaryLoginScreen> {
  bool _isOtpStep = false;
  final _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _mobileController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _handleMobileSubmit() {
    if (_mobileController.text.length == 10) {
      setState(() => _isOtpStep = true);
    }
  }

  void _handleOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _handleOtpSubmit() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      AppSession.setBeneficiary();
      Navigator.pushReplacementNamed(context, '/beneficiary-dashboard');
    }
  }

  bool get _isOtpComplete => _otpControllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header — full-width gradient extending behind the status bar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppGradients.blueHeader),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16, // status bar + extra
              20,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button row
                GestureDetector(
                  onTap: () {
                    if (_isOtpStep) {
                      setState(() => _isOtpStep = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Login to access your loan details',
                  style: TextStyle(
                    color: Colors.blue[100],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isOtpStep ? _buildOtpStep() : _buildMobileStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smartphone, size: 40, color: AppTheme.blue600),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Mobile Number', style: TextStyle(fontSize: 14, color: AppTheme.gray700, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: const InputDecoration(hintText: 'Enter 10-digit mobile number'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter the mobile number registered with your loan account',
          style: TextStyle(fontSize: 11, color: AppTheme.gray500),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _mobileController.text.length == 10 ? AppGradients.blueHeader : null,
            color: _mobileController.text.length == 10 ? null : AppTheme.gray200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: _mobileController.text.length == 10 ? _handleMobileSubmit : null,
            style: AppTheme.elevatedOnGradient(),
            child: const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
          child: const Icon(Icons.lock, size: 40, color: AppTheme.green600),
        ),
        const SizedBox(height: 24),
        const Text('Enter OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: "We've sent a 6-digit code to\n",
            style: const TextStyle(fontSize: 13, color: AppTheme.gray600),
            children: [
              TextSpan(
                text: '+91 ${_mobileController.text}',
                style: const TextStyle(color: AppTheme.gray800, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 46,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gray200, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.blue500, width: 2),
                  ),
                ),
                style: const TextStyle(fontSize: 20),
                onChanged: (value) {
                  _handleOtpChange(index, value);
                  setState(() {});
                },
              ),
            ),
          )),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: const Text('Resend OTP', style: TextStyle(color: AppTheme.blue600, fontSize: 13)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isOtpComplete ? AppGradients.greenHeader : null,
            color: _isOtpComplete ? null : AppTheme.gray200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: _isOtpComplete ? _handleOtpSubmit : null,
            style: AppTheme.elevatedOnGradient(),
            child: const Text('Verify & Login'),
          ),
        ),
      ],
    );
  }
}
