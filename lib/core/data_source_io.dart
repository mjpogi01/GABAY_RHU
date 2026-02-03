import 'package:flutter/foundation.dart';
import '../data/sqlite_app_data_source.dart';
import '../data/supabase_app_data_source.dart';
import 'app_data_source.dart';
import 'supabase_config.dart';

AppDataSource createAppDataSourceIO() {
  // Mobile/Desktop: use SQLite if Supabase not configured
  if (SupabaseConfig.isConfigured) {
    return SupabaseAppDataSource();
  }
  return SqliteAppDataSource();
}
