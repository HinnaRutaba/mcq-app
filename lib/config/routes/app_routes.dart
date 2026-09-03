/// Route path constants used with [GoRouter].
///
/// Screens and controllers should always navigate through these constants
/// (never a raw string literal) so paths stay in one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  /// The password change an officer cannot skip, when the server says
  /// `must_change_password`. Reached from sign-in, and only from there — it
  /// needs the current password, which is never persisted.
  static const String changePassword = '/change-password';

  // --- Magistrate shell branches ---------------------------------------
  // One per tab on the bottom bar, in bar order — the create button in the
  // middle of the bar is not one of these; it pushes `createFine` over the
  // shell. Each has a directory of its own under `lib/views/magistrate/`.
  static const String magistrateHome = '/magistrate/home';
  static const String magistrateDefaulters = '/magistrate/defaulters';
  static const String magistrateRound = '/magistrate/round';
  static const String magistrateTradeLicences = '/magistrate/trade-licences';
  static const String magistrateChallans = '/magistrate/challans';
  static const String magistrateMore = '/magistrate/more';

  // --- Inside the "More" branch ----------------------------------------
  // Nested under it rather than pushed over the top, so the bar stays on
  // screen and the officer is never stranded on a page with no way back to
  // their round but the system gesture.
  static const String magistrateSealed = '/magistrate/more/sealed';
  static const String magistrateProfile = '/magistrate/more/profile';

  /// The `go_router` child segments for the two routes above. A nested
  /// [GoRoute] takes the tail, not the whole path.
  static const String magistrateSealedSegment = 'sealed';
  static const String magistrateProfileSegment = 'profile';

  // --- Pushed full-screen routes (appear above the shell/bottom nav) ---

  /// Imposing a fine. Reached from the add button on the shell with no shop in
  /// mind, and from a unit's profile with one — hence the optional
  /// `?property=` rather than a path parameter.
  static const String createFine = '/magistrate/fine/new';

  static String createFinePath({int? propertyId}) =>
      propertyId == null ? createFine : '$createFine?property=$propertyId';

  /// The property profile — one shop read end to end. Pushed over the shell
  /// from Defaulters, from the Round and from Find, which is why it has a
  /// directory of its own (`views/magistrate/property/`) rather than sitting
  /// under the tab that happened to open it.
  ///
  /// The row the officer tapped travels as the route's `extra`, so the profile
  /// can draw its header before the three calls behind it answer. A cold link
  /// carries none, and the screen loads from the id alone.
  static const String propertyProfile = '/magistrate/property/:id';

  static String propertyProfilePath(int propertyId) =>
      '/magistrate/property/$propertyId';
}
