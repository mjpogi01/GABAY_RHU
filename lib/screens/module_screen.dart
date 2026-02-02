import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../providers/app_provider.dart';
import '../models/module_model.dart';

class ModuleScreen extends StatefulWidget {
  final String moduleId;

  const ModuleScreen({super.key, required this.moduleId});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  ModuleModel? _module;
  int _cardIndex = 0;
  bool _loading = true;
  int _secondsSpent = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadModule();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsSpent++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadModule() async {
    final ds = context.read<AppProvider>().dataSource;
    _module = await ds.getModuleById(widget.moduleId);
    setState(() => _loading = false);
  }

  void _next() {
    if (_module == null) return;
    if (_cardIndex < _module!.cards.length - 1) {
      setState(() => _cardIndex++);
    } else {
      _complete();
    }
  }

  void _prev() {
    if (_cardIndex > 0) setState(() => _cardIndex--);
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await context.read<AppProvider>().completeModule(widget.moduleId, _secondsSpent);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _module == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cards = _module!.cards..sort((a, b) => a.order.compareTo(b.order));
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_module!.title),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('No content in this module.')),
      );
    }

    final isLast = _cardIndex == cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_module!.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_cardIndex + 1} / ${cards.length}'),
                  Text('${_secondsSpent}s'),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: cards.length,
                controller: PageController(initialPage: _cardIndex),
                onPageChanged: (i) => setState(() => _cardIndex = i),
                itemBuilder: (_, i) {
                  final c = cards[i];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.content,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 20,
                                      height: 1.6,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_cardIndex > 0)
                    TextButton(
                      onPressed: _prev,
                      child: const Text('Previous'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
