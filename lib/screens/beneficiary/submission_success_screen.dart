import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final referenceId = 'REF2026${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Success Icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.green500.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.greenHeader,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // Success text
                const Text(
                  'Submission Successful!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppTheme.gray800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your proof of utilization has been submitted successfully and is pending verification.',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Reference Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Reference ID',
                          style: TextStyle(fontSize: 11, color: AppTheme.gray600)),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => AppGradients.blueGreen.createShader(bounds),
                        child: Text(
                          referenceId,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referenceId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reference ID copied!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Reference ID'),
                        style: AppTheme.elevatedMuted(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // What happens next
                _buildInfoBox(
                  color: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  title: 'What happens next?',
                  titleColor: const Color(0xFF1E3A5F),
                  items: [
                    'State officer will review your submission',
                    'AI validation will verify the uploaded proof',
                    "You'll be notified of the status within 3-5 days",
                  ],
                  itemColor: const Color(0xFF1D4ED8),
                ),
                const SizedBox(height: 16),

                _buildInfoBox(
                  color: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  title: 'Track your submission',
                  titleColor: const Color(0xFF14532D),
                  description: 'View the status anytime from your dashboard using the reference ID above.',
                  itemColor: const Color(0xFF15803D),
                ),
                const SizedBox(height: 24),

                // Buttons
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.blueHeader,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppTheme.blue600.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text('Return to Dashboard', style: TextStyle(color: Colors.white)),
                    style: AppTheme.elevatedOnGradient(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/gps-camera-upload'),
                  style: AppTheme.elevatedSecondaryOutlined(),
                  child: const Text('Submit Another Proof'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Keep your reference ID safe for future correspondence',
                  style: TextStyle(fontSize: 11, color: AppTheme.gray500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required Color color,
    required Color borderColor,
    required String title,
    required Color titleColor,
    List<String>? items,
    String? description,
    required Color itemColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
          const SizedBox(height: 16),
          if (items != null)
            for (final item in items)
              Text('• $item', style: TextStyle(fontSize: 11, color: itemColor, height: 1.6)),
          if (description != null)
            Text(description, style: TextStyle(fontSize: 11, color: itemColor)),
        ],
      ),
    );
  }
}
