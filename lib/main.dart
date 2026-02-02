import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_routes.dart';
import 'core/data_source_factory.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  runApp(const GabayApp());
}

class GabayApp extends StatelessWidget {
  const GabayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = createAppDataSource();
    return ChangeNotifierProvider(
      create: (_) => AppProvider(dataSource)..init(),
      child: MaterialApp(
        title: 'GABAY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}
