# CLAUDE.md

Project-specific instructions for Claude Code when working in this repo.

## Widget reuse policy

This app has an existing widget library — treat it as the source of truth for UI:

- **[lib/widgets/](lib/widgets/)** — shared, generic components used across the whole app
  (buttons, cards, charts, common, inputs, text), exported through
  [lib/widgets/widgets.dart](lib/widgets/widgets.dart).
- **[lib/views/tenant/widgets/](lib/views/tenant/widgets/)** and
  **[lib/views/magistrate/widgets/](lib/views/magistrate/widgets/)** — widgets specific to
  those feature areas (e.g. `chalaan_tile.dart`, `collection_tile.dart`).

**Rule:** before building or editing any screen, check whether a suitable widget already
exists in one of the folders above and reuse it. Do not write new inline/duplicate widget
code (e.g. a hand-rolled button, card, tile, or text style) when an equivalent already
exists in these folders. Only add a new widget file (in the appropriate folder above) when
no existing one covers the need — don't build raw `Material`/`Cupertino` UI directly in
screens when a matching widget is available.

## MVC architecture

This app follows an MVC-style layering built on GetX (`get`). Keep new code inside the
matching layer — don't put business logic in views or UI code in controllers/models.

- **Models** — [lib/models/](lib/models/): plain data classes only (`property.dart`,
  `chalaan.dart`, `seal_record.dart`, `payment_method.dart`, `user_role.dart`). No Flutter
  UI, no business logic.
- **Views** — [lib/views/](lib/views/): screens/widgets grouped by feature
  (`auth/`, `splash/`, `tenant/`, `magistrate/`), each with its own `widgets/` subfolder for
  screen-specific pieces (see Widget reuse policy above). Views read state from a
  controller (via `GetX`/`Obx`/`Get.find`) and call controller methods — they must not
  contain business logic or talk to repositories/data directly.
- **Controllers** — [lib/controllers/](lib/controllers/): `GetxController` subclasses
  (e.g. `auth_controller.dart`, `tenant_home_controller.dart`,
  `collections_controller.dart`) that hold observable (`.obs`) state and business logic,
  and mediate between views and data.
- **Data layer** — [lib/data/](lib/data/): `repositories/` define the data access
  contracts controllers depend on (e.g. `ChalaanRepository`, `PropertyRepository`,
  `SealRepository`); `mock/` holds mock implementations/seed data used until real
  backends exist. Controllers depend on the repository's abstract type, never the mock
  class directly.
- **Wiring** — [lib/app/dependency_injection.dart](lib/app/dependency_injection.dart)
  registers repositories/controllers as GetX singletons (`Get.put`) before `runApp`;
  [lib/app/app.dart](lib/app/app.dart) wires theming + routing. Routing lives in
  [lib/config/routes/](lib/config/routes/), theming in [lib/config/theme/](lib/config/theme/),
  and cross-cutting helpers (formatting, styling) in [lib/core/utils/](lib/core/utils/).

**Rule:** when adding a feature, create/extend a model in `models/`, data access in
`data/repositories/` (+ mock in `data/mock/` if no backend yet), a `GetxController` in
`controllers/` for the logic/state, and a view in `views/<feature>/` that only renders and
delegates to the controller. Register any new repository/controller singleton in
`dependency_injection.dart`.

## Reading project state

Don't rely on memory or assumptions about this codebase across turns/sessions. For every
task, read the actual current files in the project directory first (widgets, models,
controllers, views, data) rather than assuming prior structure, since the code may have
changed since it was last read.

## The design bar

MCQ will show this app to government officials, and the first version came
back as a set of screens rather than an application. Treat the craft as a
requirement, not as polish to add later.

- **Colour** — Balochistan Green: deep forest green is the brand, warm gold
  is the accent and **always carries dark text**, body type is near-black
  ink and never brand-tinted. Status colour means *only* status. Resolve
  every tone through `AppTone` ([lib/config/theme/app_colors.dart](lib/config/theme/app_colors.dart))
  so light and dark agree; never hardcode a `Color(0x…)` in a screen.
- **Colour is never the only signal.** Every status carries an icon and a
  word as well — `AppStatusBadge`, `AppPill`, `MapPin`. A magistrate may be
  colour-blind and is certainly in bright sunlight.
- **The type scale starts at 15**, not 12, and `labelSmall` (14) is the one
  exception because it is a bold pill caption, never a sentence.
- **Skeletons, never spinners**, on lists and dashboards (`AppSkeleton`).
  Cards stagger in (`AppStaggerIn`), counts count up (`AppCountUp` — counts
  only, never money), important taps shrink and can fire haptics
  (`AppPressable`, `AppHaptics`), and pull-to-refresh uses `AppRefresh`.
  Every animation is 200–300ms and none may delay the officer.
- **Every empty list is designed** — `AppEmptyState` with an
  `AppIllustrationKind` and a sentence in plain language. Never a blank
  screen, never "No data". A zero that is good news must *look* like good
  news.
- **Rows stay on screen through a refresh and through a failure.** A list
  that empties itself because a request timed out is indistinguishable from
  "nobody owes anything". `FieldListView` holds that rule in one place — use
  it rather than reimplementing the four states.

## The API layer

The app talks to MCQ's Municipal Revenue Management System (`/api/v1`). Four
documents are the specification: the API contract, the build brief, the
developer prompt, and `MAGISTRATE_APP_BRIEF.md` (flow, design and the
`field/*` module). Where they disagree, the contract wins on payload shapes
and the brief wins on flow. Open questions live in
[QUESTIONS.md](QUESTIONS.md) — write a question down rather than guessing.

- **URLs** — every path lives in
  [lib/core/network/api_constants.dart](lib/core/network/api_constants.dart),
  grouped by module. A repository never writes a literal path.
- **HTTP** — one Dio client
  ([lib/core/network/api_client.dart](lib/core/network/api_client.dart)) with
  one interceptor. It is the only place that handles the four responses that
  matter, and the rules are not negotiable:
  **401** clears the keychain and signs the officer out (the *only* status
  that does); **403** shows the server's own sentence and never navigates;
  **409** is left for the screen, which shows it in a dialog; **422** binds
  `errors` onto the form. GETs retry twice on a connection timeout; a POST is
  never retried by the transport.
- **Repositories** — one per API module in
  [lib/data/api/repositories/](lib/data/api/repositories/): auth, reporting,
  enforcement, **field**, property, allotment, billing, payment, legal,
  location, notification, plus the queued-write repository. Controllers
  depend on these, never on Dio.
- **The field module** —
  [lib/data/api/repositories/field_repository.dart](lib/data/api/repositories/field_repository.dart)
  wraps the seven `enforcement/field/*` endpoints built for this handset.
  **Each answers a whole screen in one request**; never fan one screen out
  into three calls, because five requests on a weak bazaar signal is a
  screen that never finishes painting. Models live in
  [lib/models/field/](lib/models/field/), controllers in
  [lib/controllers/field/](lib/controllers/field/), screens in
  [lib/views/magistrate/field/](lib/views/magistrate/field/).
- **Models** — hand-written `fromJson` using the defensive readers in
  [lib/core/utils/json_reader.dart](lib/core/utils/json_reader.dart). A
  missing or re-typed field falls back and asserts in debug rather than
  throwing in a magistrate's hand.

### Rules that override convenience

1. **Money is a `String`.** Use [Money](lib/models/common/money.dart) and
   render it with `MoneyText`. Never `double.parse`, `num.tryParse` or
   `toStringAsFixed` an amount, and never add two amounts together — ask the
   server, or file a backend request.
2. **Every app string goes through `t()`** ([lib/l10n/](lib/l10n/)), and both
   the English and Urdu tables carry every key (a test enforces it). Server
   strings — enum `label`s, validation messages, domain refusals — are shown
   **verbatim**; never translate one on the client. Layout uses
   `EdgeInsetsDirectional`/`AlignmentDirectional` and start/end, never
   left/right.
3. **Gate actions on the server's `can_*` flags**
   ([CanFlags](lib/models/common/can_flags.dart)) *and* the officer's
   `permissions` ([Permissions](lib/models/auth/permissions.dart)). Never on
   `status`.
4. **Every field write carries `client_action_uuid`** and goes through
   [FieldWriteController](lib/controllers/api/field_write_controller.dart),
   which owns the photograph (upload first, send the path), the GPS fix (both
   coordinates or neither), and the decision to queue when the signal dies.
   201 means created; 200 means "you already sent that" — never announce it
   twice.
5. **Destructive actions confirm, naming the shop and the allottee**, via
   `AppConfirmDialog`.
6. **Nothing in the offline queue is ever discarded silently.** A refusal goes
   to "needs attention" with the server's sentence.
7. **Absent is not zero, and the app must keep them apart all the way to
   the widget.** `outstanding: null` on a vacant unit renders as "Vacant",
   never `0.00` — nobody owes anything because nobody holds it, which is a
   different fact from a tenant who is up to date. `days_overdue: null`
   draws no pill at all. A beat queue with `amount: null` is not measured in
   money and shows no figure. Use `moneyOrNull`, not `money`, wherever the
   payload may legitimately have nothing.
8. **One card widget, not three.** `field/defaulters`, `field/units` and the
   round's `stops` return the same shape on purpose;
   [FieldCardTile](lib/views/magistrate/field/widgets/field_card_tile.dart)
   draws all three. Do not fork it.
9. **`can_*` flags and server judgements are read, never recomputed.**
   `ready_to_release`, `commitment.broken` and `needs_offender_details` are
   the server's answers. A state machine written on the handset will be
   wrong within a month, and wrong in the direction of offering an action
   that gets refused in front of a shopkeeper.
10. **Hero tags are namespaced per list.** The shell keeps every branch
    alive at once, so two lists drawing the same shop with the same tag is a
    crash the moment any transition starts — pass `heroPrefix`, and carry it
    into the profile route as `?from=`.
