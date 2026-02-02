import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';

/// Simplified login for demo - in production, verify against RHU/BHW master lists
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to GABAY')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Care for your little one',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _demoLogin(context),
              child: const Text('Demo Login (Parent)'),
            ),
          ],
        ),
      ),
    );
  }

  void _demoLogin(BuildContext context) async {
    // Demo: create minimal user/child for testing
    // In production: verify against RHU/BHW master lists
    final provider = context.read<AppProvider>();
    final user = UserModel(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      anonymizedId: 'anon_${DateTime.now().millisecondsSinceEpoch}',
      role: 'parent',
      createdAt: DateTime.now(),
    );
    final child = ChildModel(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      caregiverId: user.id,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 180)),
    );
    await provider.setUserAndChild(user, child);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.preTest);
  }
}
