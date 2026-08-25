# mcq_app

A fintech app for two roles — **Tenant** and **Magistrate** — sharing one
login screen and a single design system, with role-specific dashboards
after sign-in.

## Tech stack

| Concern          | Choice                                                                                                                                                                             |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language / SDK   | Dart, Flutter (`sdk: ^3.12.2`)                                                                                                                                                     |
| Architecture     | MVC — `models/` (data), `controllers/` (state + logic), `views/` (screens/widgets)                                                                                                 |
| State management | [get](https://pub.dev/packages/get) (GetX) — used for state/DI only (`GetxController`, `Obx`, `Get.put`/`Get.find`); routing goes through `go_router` instead of GetX's own router |
| Navigation       | [go_router](https://pub.dev/packages/go_router) — `StatefulShellRoute.indexedStack` per role, so each role's bottom-nav tabs keep their own navigation/scroll state                |
| Fonts            | [google_fonts](https://pub.dev/packages/google_fonts) (Inter)                                                                                                                      |
| Formatting       | [intl](https://pub.dev/packages/intl) — currency (PKR) and date formatting, centralized in `core/utils/formatters.dart`                                                            |
| External links   | [url_launcher](https://pub.dev/packages/url_launcher) — "Open in Maps" on the Magistrate side                                                                                      |
| Data layer       | Mock in-memory repositories behind abstract interfaces (see below) — no backend yet                                                                                                |

Run it with the standard Flutter commands: `flutter pub get`, then
`flutter run`. `flutter analyze` and `flutter test` should stay clean.

## Directory structure

```
lib/
├── main.dart                    # entry point: registers DI, runs McqApp
├── app/
│   ├── app.dart                 # root widget — MaterialApp.router, theme wiring
│   └── dependency_injection.dart# registers repositories + app-wide GetX singletons
│
├── config/
│   ├── theme/                   # AppColors, AppTextTheme, AppTheme (light + dark)
│   └── routes/                  # AppRoutes (path constants), AppRouter (GoRouter config)
│
├── models/                      # plain data classes: Chalaan, Property, SealRecord,
│                                 # PaymentMethod, UserRole — no Flutter/GetX imports
│
├── data/
│   ├── mock/                    # mock_seed.dart — seed data + demo tenant/magistrate identity
│   └── repositories/            # abstract repository + Mock*Repository impl per entity
│                                 # (ChalaanRepository, PropertyRepository, SealRepository) —
│                                 # swap the Mock impl for a real API later; views/controllers
│                                 # only ever depend on the abstract type
│
├── controllers/                 # GetxController per screen/feature (state + business logic,
│                                 # no widgets). AuthController, ThemeController and
│                                 # SealController are registered as permanent singletons;
│                                 # the rest are registered lazily from their screen's build()
│
├── core/utils/                  # Formatters (currency/date), StatusStyle (status → color),
│                                 # getOrPut (safe GetX registration helper)
│
├── views/                       # screens, one folder per flow
│   ├── splash/
│   ├── auth/                    # shared login screen (role picked via checkbox)
│   ├── tenant/                  # shell (bottom nav) + Home/Payments/Profile + widgets/
│   └── magistrate/              # shell (bottom nav + FAB) + Home/Collections/Sealed/
│                                 # Profile/Create/Detail screens + widgets/
│
└── widgets/                     # generic, domain-agnostic UI components — every screen
    ├── text/                    # is built out of these instead of raw Material widgets
    ├── buttons/
    ├── inputs/                  # text field, search field, dropdown, date field
    ├── cards/
    ├── charts/                  # AppBarChart (paid vs due)
    ├── common/                  # header, bottom nav, status badge, chip tabs, stat tile,
    │                             # empty state, quick action, circle icon button
    └── widgets.dart              # barrel export — screens import this one file
```

### Conventions

- **Generic UI only in `widgets/`.** Screens compose `AppText`, `AppButton`,
  `AppTextField`, `AppCard`, `AppStatusBadge`, etc. instead of raw
  `Text`/`ElevatedButton`/`Container`, so the whole app restyles from one
  place (`config/theme/`).
- **Repositories are the swap point for a real backend.** Controllers and
  views depend on the abstract repository interface
  (`ChalaanRepository`, not `MockChalaanRepository`) — replacing the mock
  implementation in `dependency_injection.dart` is the only change needed
  once a real API exists.
- **Domain-specific composition lives next to its screen.** A widget that
  renders a `Chalaan` or `SealRecord` (e.g. `ChalaanTile`, `SealTile`) is
  not "generic," so it lives in `views/<role>/widgets/`, not in the
  top-level `widgets/` folder.
