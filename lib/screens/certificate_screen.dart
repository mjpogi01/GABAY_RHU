import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/app_provider.dart';
import '../services/certificate_service.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    if (provider.postTestResult == null || provider.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Certificate'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('No certificate available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Certificate'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Uint8List>(
        future: CertificateService.generateCertificate(
          user: provider.user!,
          postTestResult: provider.postTestResult!,
          completionDate: provider.postTestResult!.completedAt,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return PdfPreview(
            build: (_) async => snapshot.data!,
            allowSharing: true,
            allowPrinting: true,
          );
        },
      ),
    );
  }
}
