import '../data/sqlite_app_data_source.dart';
import '../data/supabase_app_data_source.dart';
import 'app_data_source.dart';
import 'supabase_config.dart';

AppDataSource createAppDataSource() {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAppDataSource();
  }
  return SqliteAppDataSource();
}
