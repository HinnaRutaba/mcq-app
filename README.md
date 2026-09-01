# MCQ Magistrate App

A field application for **Municipal Magistrates and enforcement officers of
Metropolitan Corporation Quetta**. They walk the bazaars with it: find out
who in *their assigned areas* has not paid rent on an MCQ shop, visit them,
record what happened, impose fines under a named provision of law, and seal
or release shops.

It is not a general-purpose admin app. A magistrate cannot take money, cannot
amend a bill, and cannot see areas they are not posted to.

Built against `MOBILE_API_MAGISTRATE.md` (the API contract),
`MOBILE_APP_BUILD_BRIEF.md` and `MAGISTRATE_APP_BRIEF.md` (flow, design and
the `field/*` module). Where they disagree the contract wins on payload
shapes and the brief wins on flow. Open questions that need MCQ's answer are
in [QUESTIONS.md](QUESTIONS.md).

## Running it

```bash
flutter pub get
flutter run                                        # defaults to staging
flutter run --dart-define=MCQ_API_HOST=https://<other-host>
flutter analyze && flutter test          # both stay clean
```

`MCQ_API_HOST` defaults to `https://stag.planmycrew.com`. Before designing
around any payload, verify the live API:

```bash
./scripts/verify_api.sh https://stag.planmycrew.com magistrate '<password>'
```

Minimum Android API 24 — these are cheap handsets. Test on one, on mobile
data, not only on an emulator on Wi-Fi.

## The design bar

MCQ will show this to government officials, and the first version came back
as a set of screens rather than an application. So the flow, the hierarchy
and the craft are treated as requirements, not polish:

- **Balochistan Green.** Deep forest green as the corporate colour, warm gold
  as the accent — always with dark text on it — and a near-black ink ramp for
  type. Status colour means *only* status, and never carries meaning alone:
  every state has an icon and a word so a red card and an amber card are
  distinguishable in greyscale, by a colour-blind officer, in sunlight. One
  place decides what each tone looks like in both themes (`AppTone`).
- **The scale starts at 15, not 12.** This is read at arm's length, in
  sunlight, by an officer who may be over fifty. There is a large-text
  setting on top of the operating system's, in Settings, next to the
  language.
- **Skeletons, never spinners**, on every list and dashboard. Cards stagger
  in at 260ms, counts count up, the card the officer taps expands into the
  profile, and pull-to-refresh has the app's own indicator. Every animation
  is 200–300ms and none of them delays the work.
- **Every empty list is designed.** A drawn illustration and a sentence in
  plain language — *"No shop in your areas is behind on payment today. Good
  morning."* Never a blank screen, never "No data".
- **Haptics on decisions.** Sealing a shop feels like a decision; scrolling
  past a card does not.
- **Urdu is a first-class layout, not a toggle.** Nastaliq at ~1.85 line
  height against ~1.5, Western digits throughout, and
  `EdgeInsetsDirectional`/`AlignmentDirectional` everywhere.

## The six rules the code is built around

1. **Money is a `String` and is never parsed.** `Money` (`models/common/`)
   holds the server's digits and formats them with string surgery. There is
   no `+` on it and there must never be one: every total, subtotal, share and
   percentage comes from the server. Grep for `double.parse` — there is none
   near an amount.
2. **A 403 shows a message; only a 401 signs the officer out.** Handled once,
   in the Dio interceptor (`core/network/api_client.dart`). A 409 is a domain
   refusal and gets a dialog with the server's own sentence, not a toast.
3. **The token lives in the OS keychain** (`flutter_secure_storage`), never in
   `SharedPreferences`.
4. **Urdu is first-class and right-to-left from day one.** Every app string
   goes through `t()`; server strings (enum labels, validation messages,
   domain refusals) are shown verbatim because the API already translated
   them. Layout uses `EdgeInsetsDirectional` and start/end throughout.
5. **Server `can_*` flags gate every action**, never a state machine inferred
   from `status` (`models/common/can_flags.dart`).
6. **Every destructive action confirms, naming the shop and the allottee**
   (`widgets/dialogs/app_confirm_dialog.dart`).

## Tech stack

| Concern | Choice |
| --- | --- |
| Architecture | MVC on GetX — `models/` (data), `data/` (repositories), `controllers/` (state + logic), `views/` (screens) |
| State / DI | [get](https://pub.dev/packages/get) — `GetxController`, `Obx`, `Get.put`/`Get.find` |
| Navigation | [go_router](https://pub.dev/packages/go_router) — declarative guards for "signed in" and "must change password" |
| HTTP | [dio](https://pub.dev/packages/dio) — one interceptor implements 401/403/409/422 for the whole app |
| Secure store | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — Keychain / Keystore |
| Local state | [shared_preferences](https://pub.dev/packages/shared_preferences) — language, device name, read cache, offline queue |
| Idempotency | [uuid](https://pub.dev/packages/uuid) — `client_action_uuid` on every field write |
| Field capture | image_picker + flutter_image_compress (under 1 MB), geolocator, device_info_plus, signature (witness signatures) |
| Map | flutter_map + latlong2 over OpenStreetMap tiles — no API key to lose, and grid clustering written in twenty lines rather than another dependency |
| Sharing | share_plus + a WhatsApp deep link, for handing a payment link to a shopkeeper |
| Offline | connectivity_plus + a persisted write queue; local visit reminders via flutter_local_notifications |
| i18n | flutter_localizations + plain Dart string tables (`lib/l10n/`) — no build step |

The brief's defaults suggested Riverpod and freezed. This repo stays on
**GetX** and hand-written models, deliberately: GetX is what the existing
codebase and its widget library are built on (see `CLAUDE.md`), and
hand-written `fromJson` with defensive readers (`core/utils/json_reader.dart`)
keeps a renamed API field from becoming a silent null while the API is still
moving. Routing is `go_router`, as the brief suggests, not GetX's router.

## Directory structure

```
lib/
├── main.dart                     # awaits DI, then runs McqApp
├── app/                          # root widget (theme, locale, direction) + DI container
│
├── l10n/                         # t(), AppLocale, English and Urdu string tables
│
├── core/
│   ├── network/                  # api_constants (every URL), api_client (Dio + interceptor),
│   │                             # api_envelope (unwrap once), api_exception (401/403/409/422)
│   ├── storage/                  # keychain token store, key-value store, read cache
│   ├── services/                 # camera+compression, GPS, connectivity, device name, reminders
│   └── utils/                    # json readers, formatters, dialer, status tones, feedback
│
├── models/
│   ├── common/                   # Money, ApiEnum {value,label,tone}, CanFlags, pagination,
│   │                             # entity refs, Fetched<T>, WriteOutcome<T>
│   ├── auth/ reporting/ enforcement/ property/ billing/ legal/ location/ offline/
│
├── data/api/repositories/        # one per API module: auth, reporting, enforcement,
│                                 # property, allotment, billing, payment, legal, location,
│                                 # notification, and the offline queued-write repository
│
├── controllers/
│   ├── api/                      # session, locale, offline queue (permanent singletons);
│   │                             # cases, case detail, fines, profile, legal, settings;
│   │                             # field_write_controller — shared base for the four writes
│   └── field/                    # the handset module: beat, round, defaulters, follow-ups,
│                                 # seals, unit search, activity, map, shop profile
│
└── views/
    ├── splash/ auth/             # session boot, sign in, forced password change
    ├── magistrate/field/         # the officer app: beat (home), round, defaulters,
    │                             # follow-ups, seals, find, activity, map, shop profile
    └── magistrate/api/           # shell, cases, case detail, record action, seal/release,
                                  # fine, inspection, legal, queue, settings
```

`widgets/` is the shared, domain-agnostic library every screen builds out of
(`AppText`, `AppButton`, `AppCard`, `MoneyText`, `UserText`, `AppBanner`,
`AppPill`, `AppMoneyPanel`, `AppActionSheet`, `AppSkeleton`,
`AppIllustration`, `AppRefresh`, `AppCountUp`, `AppStaggerIn`,
`AppSignaturePad`, confirm/message dialogs, …). Domain cards live beside
their screens in `views/magistrate/field/widgets/`.

### The `field/*` module

Seven endpoints were built for this handset, and each answers a whole screen
in **one** request — five requests on a weak bazaar signal is a screen that
never finishes painting. They live in
`data/api/repositories/field_repository.dart`.

| Endpoint | Screen |
| --- | --- |
| `enforcement/field/beat` | the home screen: who he is, where he is posted, six queues |
| `enforcement/field/round` | today's round, grouped by market, broken promises first |
| `enforcement/field/defaulters` | the working list |
| `enforcement/field/follow-ups` | promises to chase, in three states |
| `enforcement/field/seals` | one list, two readings — sealed, and ready to unseal |
| `enforcement/field/units` | search, **including vacant units** |
| `enforcement/field/activity` | "my work" |

`field/defaulters`, `field/units` and the round's `stops` return the **same
card shape**, so the app has exactly one card widget
(`views/magistrate/field/widgets/field_card_tile.dart`) rather than three
that drift apart.

### Screens

1. **Sign in** — username (not email), editable device name, one error
   message for every failure. **Forced password change** explains itself and
   says plainly that a successful change signs the officer out of every
   device, because it does.
2. **The beat** (home) — one call. His name and areas in a gradient band,
   six large tiles that each open the list behind them, today's round, the
   month's work, a map preview and quick actions. No number on it is a dead
   end: tiles the app has no screen for still open, through the server's own
   `endpoint`.
3. **Defaulters** — cards carrying everything needed to decide without
   opening anything, and among the pills **the commitment**: who promised
   what, on which date, and how many days are left.
4. **Today's round** — markets as expandable cards, at most five stops each,
   and a stop-by-stop walk-through.
5. **The shopkeeper profile** — the card expands into it; hero, money panel,
   facts, timeline, and the action sheet: record a visit, give a warning,
   take a promise, set a reminder, impose a fine, open a case, seal, release.
6. **Promises to chase** — three states, three treatments, both balances.
7. **Seals** — ready-to-release first, with the rule stated in plain words.
8. **Find** — two tabs, vacant units included, recent searches.
9. **My work**, **the map**, **cases** (including those assigned by the
   taxation branch), **court cases** (read-only), **offline queue**,
   **settings**.

### The demo screens that predate this

`views/tenant/` and the older `views/magistrate/*.dart` prototype screens are
still on disk and still compile, but nothing routes to them any more — the
officer app replaced them, and the API contract is explicit that there is no
allottee app (no allottee authentication surface exists). Delete them once the
officer app has been in a magistrate's hands.
