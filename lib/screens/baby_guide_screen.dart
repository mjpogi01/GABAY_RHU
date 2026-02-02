import 'package:flutter/material.dart';

class BabyGuideScreen extends StatelessWidget {
  const BabyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baby Guide',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Tips and guides for caring for your baby aged 0-2 years. '
              'Explore the modules to learn about newborn care, nutrition, safety, and more.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
    );
  }
}
