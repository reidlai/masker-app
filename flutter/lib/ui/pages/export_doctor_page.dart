import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_badge.dart';
import '../atoms/shad_button.dart';

class ExportDoctorPage extends StatefulWidget {
  const ExportDoctorPage({super.key});

  @override
  State<ExportDoctorPage> createState() => _ExportDoctorPageState();
}

class _ExportDoctorPageState extends State<ExportDoctorPage> {
  int _selectedFormatIndex = 0; // 0: PDF, 1: FHIR JSON

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Export Physician Report"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: Text(
                            "PHYSICIAN SUMMARY REPORT",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.04,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ShadBadge(
                          label: "Signed",
                          variant: ShadBadgeVariant.normal,
                          icon: Icon(Icons.verified, size: 12, color: AppColors.accentGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportDetailRow("Patient Name", "David Miller"),
                    const SizedBox(height: 8),
                    _buildReportDetailRow("Date Range", "Sep 5, 2026 (Nightly Session)"),
                    const SizedBox(height: 8),
                    _buildReportDetailRow("Apnea Index", "3.2 / hr (Normal Range)"),
                    const SizedBox(height: 8),
                    _buildReportDetailRow("Recorded Events", "2 Obstructive Apnea Events"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Format Selection Header
              const Text(
                "SELECT EXPORT FORMAT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Format Option 1: PDF Clinical Summary
              _buildFormatOptionCard(
                index: 0,
                title: "PDF Clinical Summary Report",
                subtitle: "Formatted AASM-compliant PDF document for physician review.",
                icon: Icons.picture_as_pdf_outlined,
              ),
              const SizedBox(height: 10),

              // Format Option 2: FHIR R4 JSON
              _buildFormatOptionCard(
                index: 1,
                title: "FHIR R4 DiagnosticReport JSON",
                subtitle: "Interoperable health data payload for EMR / EHR integration.",
                icon: Icons.code,
              ),
              const SizedBox(height: 28),

              // Action Button
              ShadButton(
                label: _selectedFormatIndex == 0 ? "Export Signed PDF Report" : "Export FHIR JSON Payload",
                variant: ShadButtonVariant.primary,
                icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.background),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _selectedFormatIndex == 0
                            ? "Generating signed PDF clinical report..."
                            : "Exporting FHIR R4 DiagnosticReport JSON payload...",
                      ),
                      backgroundColor: AppColors.purpleAnalytics,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOptionCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFormatIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormatIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? AppColors.accentGreen : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentGreen : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
