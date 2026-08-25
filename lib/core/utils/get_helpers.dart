import 'package:get/get.dart';

/// Fetches the existing GetX singleton for [T] if one is registered,
/// otherwise creates and registers one via [create].
///
/// Screens register their controller from `build()` (no route Bindings in
/// this app — see `lib/app/dependency_injection.dart`), and `build()` can
/// run more than once; a bare `Get.put` would silently replace the
/// controller — and its state — on every rebuild. This keeps the first
/// instance alive instead.
T getOrPut<T>(T Function() create) {
  return Get.isRegistered<T>() ? Get.find<T>() : Get.put<T>(create());
}
