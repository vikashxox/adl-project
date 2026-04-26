import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/app_theme.dart';

class AdminExportReportScreen extends StatefulWidget {
  const AdminExportReportScreen({super.key});

  @override
  State<AdminExportReportScreen> createState() => _AdminExportReportScreenState();
}

class _AdminExportReportScreenState extends State<AdminExportReportScreen> {
  final String _format = 'csv';
  bool _isExporting = false;
  bool _exported = false;
  String? _error;
  String? _savedPath;

  DateTime? _startDate;
  DateTime? _endDate;

  String get _dateText {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';
    }
    return 'Select Date Range';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.green600,
              onPrimary: Colors.white,
              onSurface: AppTheme.gray800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _exported = false;
        _error = null;
        _savedPath = null;
      });
    }
  }

  Future<void> _handleExport() async {
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Please select a date range first.');
      return;
    }

    setState(() { _error = null; _exported = false; _isExporting = true; _savedPath = null; });
    try {
      final snap = await FirebaseFirestore.instance.collection('beneficiaries').get();
      
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);

      List<Map<String, dynamic>> filtered = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['disbursedDate'] != null) {
          createdAt = DateTime.tryParse(data['disbursedDate']);
        }
        
        if (createdAt != null && createdAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && createdAt.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          filtered.add(data);
        }
      }

      if (filtered.isEmpty) {
        setState(() => _error = 'No records found for this date range.');
        return;
      }

      StringBuffer csv = StringBuffer();
      csv.writeln('Name,Phone,Address,District,Loan Amount,Loan Purpose,Assigned Officer,Status,Created At');
      
      for (var b in filtered) {
        final name = (b['name'] ?? '').toString().replaceAll(',', ' ');
        final phone = (b['phone'] ?? '').toString().replaceAll(',', ' ');
        final address = (b['address'] ?? '').toString().replaceAll(',', ' ');
        final district = (b['district'] ?? '').toString().replaceAll(',', ' ');
        final loanAmount = (b['loanAmount'] ?? 0).toString();
        final purpose = (b['loanPurpose'] ?? '').toString().replaceAll(',', ' ');
        final officer = (b['assignedOfficer'] ?? '').toString().replaceAll(',', ' ');
        final status = (b['status'] ?? '').toString();
        
        String dateStr = '';
        if (b['createdAt'] != null) {
          dateStr = DateFormat('yyyy-MM-dd HH:mm').format((b['createdAt'] as Timestamp).toDate());
        }
        
        csv.writeln('$name,$phone,$address,$district,$loanAmount,$purpose,$officer,$status,$dateStr');
      }

      Directory? dir;
      File? file;
      final fileName = 'report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (Platform.isAndroid) {
        // Try saving to the public Download directory first so the user can see it easily
        try {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          file = File('${dir.path}/$fileName');
          await file.writeAsString(csv.toString());
        } catch (e) {
          // If permission denied or other error, fallback to app-specific external storage
          dir = await getExternalStorageDirectory();
          if (dir != null) {
            file = File('${dir.path}/$fileName');
            await file.writeAsString(csv.toString());
          }
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');
        await file.writeAsString(csv.toString());
      }
      
      if (file == null) {
        throw Exception("Could not determine directory to save file.");
      }

      setState(() {
        _exported = true;
        _savedPath = file!.path;
      });
    } catch (e) {
      setState(() => _error = 'Failed to export report: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
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
                  icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
                  label: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.file_download, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Tools', style: TextStyle(color: Colors.green[100], fontSize: 11)),
                        const Text('Export Report',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Report Period
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Report period', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              border: Border.all(color: AppTheme.green600),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range, color: AppTheme.green600, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_dateText,
                                      style: const TextStyle(fontSize: 14, color: AppTheme.green600, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Format Selection
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select format',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                        const SizedBox(height: 16),
                        _formatOption('csv', Icons.table_chart, 'CSV Spreadsheet'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleExport,
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'Export CSV Report',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: AppTheme.elevatedSolid(AppTheme.green600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status messages
                  if (_exported && _savedPath != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.green600, size: 18),
                              SizedBox(width: 10),
                              Text('Report downloaded successfully!',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Saved to:\n$_savedPath',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFECACA)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.red600, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppTheme.red600))),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: child,
    );
  }

  Widget _formatOption(String value, IconData icon, String label) {
    final selected = _format == value;
    return GestureDetector(
      onTap: () {}, // Only CSV is supported now
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : Colors.white,
          border: Border.all(color: selected ? AppTheme.green600 : AppTheme.gray200, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppTheme.green600 : AppTheme.gray500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: selected ? AppTheme.green600 : AppTheme.gray700,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.green600, size: 18),
          ],
        ),
      ),
    );
  }
}

