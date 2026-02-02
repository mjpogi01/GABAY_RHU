import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _childDob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register as a parent or caregiver',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365)),
                    firstDate: DateTime.now().subtract(const Duration(days: 730)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _childDob = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Child\'s date of birth',
                    hintText: 'Tap to select',
                  ),
                  child: Text(
                    _childDob != null
                        ? '${_childDob!.year}-${_childDob!.month.toString().padLeft(2, '0')}-${_childDob!.day.toString().padLeft(2, '0')}'
                        : '',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {});
    if (_childDob == null) return;
    final provider = context.read<AppProvider>();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final user = UserModel(
      id: 'user_$ts',
      anonymizedId: 'anon_$ts',
      role: 'parent',
      createdAt: DateTime.now(),
    );
    final child = ChildModel(
      id: 'child_$ts',
      caregiverId: user.id,
      dateOfBirth: _childDob!,
    );
    await provider.setUserAndChild(user, child);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.preTest);
  }
}
