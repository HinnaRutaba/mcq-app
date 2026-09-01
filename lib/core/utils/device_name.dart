import 'dart:io';

/// A name for this handset, sent as `device_name` when signing in.
///
/// The officer sees it in the server's device list, so it wants to be
/// recognisable — the API's own example is "Pixel 8". Flutter has no built-in
/// model name, and `Platform.operatingSystemVersion` is the closest thing
/// without a plugin: on Android it carries the manufacturer and model, on iOS
/// only the OS build.
///
/// If a proper model name matters, add `device_info_plus` and replace the body
/// of [resolve]; nothing else has to change, because the name is written to the
/// keychain on the first sign-in and reused from there on, so a handset keeps
/// one device entry rather than collecting a new one per sign-in.
class DeviceName {
  DeviceName._();

  /// The API caps `device_name` at 120 characters.
  static const int maxLength = 120;

  static String resolve() {
    final platform = switch (Platform.operatingSystem) {
      'android' => 'Android',
      'ios' => 'iOS',
      'macos' => 'macOS',
      'windows' => 'Windows',
      'linux' => 'Linux',
      final String other => other,
    };

    final detail = Platform.operatingSystemVersion.trim();
    final name = detail.isEmpty ? '$platform handset' : '$platform · $detail';
    return name.length <= maxLength ? name : name.substring(0, maxLength);
  }
}
