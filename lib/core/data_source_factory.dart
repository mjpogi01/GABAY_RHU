import 'package:flutter/foundation.dart';
import 'app_data_source.dart';
import 'data_source_web.dart';
import 'data_source_io.dart';

AppDataSource createAppDataSource() {
  if (kIsWeb) {
    return createAppDataSourceWeb();
  } else {
    return createAppDataSourceIO();
  }
}
