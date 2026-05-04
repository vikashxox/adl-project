import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/connectivity_service.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/beneficiary/beneficiary_login_screen.dart';
import 'screens/beneficiary/beneficiary_dashboard_screen.dart';
import 'screens/beneficiary/gps_camera_upload_screen.dart';
import 'screens/beneficiary/submission_success_screen.dart';
import 'screens/beneficiary/pending_uploads_screen.dart';
import 'screens/beneficiary/history_screen.dart';
import 'screens/officer/officer_login_screen.dart';
import 'screens/officer/officer_dashboard_screen.dart';
import 'screens/officer/verification_detail_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_data_entry_screen.dart';
import 'screens/admin/admin_export_report_screen.dart';
import 'screens/admin/admin_beneficiaries_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/admin_uploads_screen.dart';
import 'widgets/upload_debug_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Load .env first — CloudinaryService reads from it at upload time
  try {
    await dotenv.load(fileName: '.env');
    print('dotenv loaded');
  } catch (e) {
    print('dotenv load error: $e');
  }

  // Step 2: Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized');
  } catch (e) {
    print('Firebase init error: $e');
    return;
  }

  // Step 3: Start connectivity monitor for offline auto-sync
  ConnectivityService().initialize();

  runApp(const LoanTrackerApp());
}

class LoanTrackerApp extends StatelessWidget {
  const LoanTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/beneficiary-login': (context) => const BeneficiaryLoginScreen(),
        '/beneficiary-dashboard': (context) => const BeneficiaryDashboardScreen(),
        '/gps-camera-upload': (context) => const GpsCameraUploadScreen(),
        '/submission-success': (context) => const SubmissionSuccessScreen(),
        '/pending-uploads': (context) => const PendingUploadsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/officer-login': (context) => const OfficerLoginScreen(),
        '/officer-dashboard': (context) => const OfficerDashboardScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-data-entry': (context) => const AdminDataEntryScreen(),
        '/admin-export-report': (context) => const AdminExportReportScreen(),
        '/admin-beneficiaries': (context) => const AdminBeneficiariesScreen(),
        '/admin-settings': (context) => const AdminSettingsScreen(),
        '/officer-uploads': (context) => const AdminUploadsScreen(allowReviewActions: true),
        '/upload-debug': (context) => const UploadDebugWidget(),
      },
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/verification-detail/')) {
          final id = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => VerificationDetailScreen(id: id),
          );
        }
        return null;
      },
    );
  }
}
