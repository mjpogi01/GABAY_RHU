import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants.dart';
import '../models/assessment_result_model.dart';
import '../models/user_model.dart';

/// Generates digital certificate upon meeting benchmark criteria
class CertificateService {
  static Future<Uint8List> generateCertificate({
    required UserModel user,
    required AssessmentResultModel postTestResult,
    required DateTime completionDate,
  }) async {
    final pdf = pw.Document();
    final scorePercent = (postTestResult.overallScore * 100).round();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 40),
              pw.Text(
                'Certificate of Completion',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                AppConstants.appName,
                style: const pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'This certifies that',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Participant ID: ${user.anonymizedId}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'has successfully completed the GABAY infant care education program.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Post-test score: $scorePercent%',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Completed: ${completionDate.toString().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Spacer(),
              pw.Text(
                'Research & Public Health Intervention Tool',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printCertificate(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'GABAY_Certificate.pdf',
    );
  }
}
