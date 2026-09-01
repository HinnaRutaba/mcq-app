import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../storage/key_value_store.dart';

/// Supplies and remembers `device_name`.
///
/// The API requires it, the officer sees it when revoking a lost handset,
/// and it is the key the server uses to replace *that* device's previous
/// token on re-login. So it is prefilled with the handset model and left
/// editable — and never a UUID.
class DeviceInfoService {
  DeviceInfoService(this._store);

  final KeyValueStore _store;

  String? _model;

  /// What the login screen prefills: whatever the officer typed last time,
  /// otherwise the handset model.
  Future<String> suggestedDeviceName() async {
    final remembered = _store.getString(KeyValueStore.deviceNameKey);
    if (remembered != null && remembered.trim().isNotEmpty) return remembered;
    return handsetModel();
  }

  Future<String> handsetModel() async {
    if (_model != null) return _model!;
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        _model = '${android.manufacturer} ${android.model}'.trim();
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        _model = ios.utsname.machine;
      }
    } on Object {
      // A handset that will not say what it is still has to be able to
      // sign in; the officer can type a name.
      _model = null;
    }
    return _model?.isNotEmpty == true ? _model! : 'MCQ handset';
  }

  Future<void> remember(String deviceName) =>
      _store.setString(KeyValueStore.deviceNameKey, deviceName.trim());
}
