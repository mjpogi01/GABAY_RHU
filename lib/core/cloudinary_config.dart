/// Cloudinary configuration for module image uploads.
///
/// Uses unsigned upload so the app never needs your API secret.
/// Set cloud name and upload preset via dart-define or replace defaults:
///
///   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
///
/// To create an unsigned preset in Cloudinary Dashboard:
/// Settings → Upload → Upload presets → Add upload preset → Signing Mode: Unsigned.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dtaeejtap',
  );

  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'GabayApp',
  );

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
