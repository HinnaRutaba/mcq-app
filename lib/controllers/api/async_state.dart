import 'package:get/get.dart';

import '../../core/network/api_exception.dart';

/// Load state shared by every screen that reads from the API.
///
/// A screen has four states, not two: loading, loaded, empty, and failed —
/// and an empty state must say *why* it is empty (no posting, or nothing
/// overdue; both are real answers).
mixin AsyncState on GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final Rx<ApiException?> failure = Rx<ApiException?>(null);

  /// True when what is on screen came from the cache rather than the
  /// network. Drives the "showing data saved at …" banner, because a cached
  /// figure must never look live.
  final RxBool isStale = false.obs;

  /// When the data on screen was actually fetched.
  final Rx<DateTime?> fetchedAt = Rx<DateTime?>(null);

  bool get hasFailed => failure.value != null;

  /// Runs a read, keeping the load flags and the failure honest.
  ///
  /// A 401 is not handled here: the interceptor has already sent the
  /// officer to login. A 403 is not handled here either — the interceptor
  /// has already shown the server's sentence — but it is recorded so the
  /// screen can render a refusal instead of an empty list.
  Future<void> load(
    Future<void> Function() work, {
    bool refreshing = false,
  }) async {
    if (refreshing) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    failure.value = null;
    try {
      await work();
    } on ApiException catch (error) {
      failure.value = error;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void markFetched(DateTime at, {required bool fromCache}) {
    fetchedAt.value = at;
    isStale.value = fromCache;
  }
}
