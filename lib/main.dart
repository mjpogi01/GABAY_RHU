import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'core/theme.dart';
import 'core/app_routes.dart';
import 'core/data_source_factory.dart';
import 'core/supabase_config.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  // Always initialize Supabase for web builds since SQLite doesn't work
  if (kIsWeb || SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
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
        localizationsDelegates: const [
          quill.FlutterQuillLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fil'),
        ],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}
