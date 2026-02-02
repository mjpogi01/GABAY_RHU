import 'app_data_source.dart';
import 'data_source_stub.dart'
    if (dart.library.html) 'data_source_web.dart'
    if (dart.library.io) 'data_source_io.dart' as impl;

AppDataSource createAppDataSource() => impl.createAppDataSource();
