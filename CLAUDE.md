# CLAUDE.md

Project-specific instructions for Claude Code when working in this repo.

## Widget reuse policy

This app has an existing widget library — treat it as the source of truth for UI:

- **[lib/widgets/](lib/widgets/)** — shared, generic components used across the whole app
  (buttons, cards, charts, common, inputs, text), exported through
  [lib/widgets/widgets.dart](lib/widgets/widgets.dart).
- **`lib/views/magistrate/<tab>/widgets/`** — widgets belonging to one tab, beside the
  screen that uses them: [home/widgets/](lib/views/magistrate/home/widgets/),
  [more/widgets/](lib/views/magistrate/more/widgets/). A widget used by more than one tab
  is promoted to [lib/widgets/](lib/widgets/) rather than imported across tabs.

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
  `chalaan.dart`, `seal_record.dart`, `payment_method.dart`). No Flutter UI, no business
  logic.
- **Views** — [lib/views/](lib/views/): screens/widgets grouped by feature
  (`auth/`, `splash/`, `magistrate/`), each with its own `widgets/` subfolder for
  screen-specific pieces (see Widget reuse policy above). Views read state from a
  controller (via `GetX`/`Obx`/`Get.find`) and call controller methods — they must not
  contain business logic or talk to repositories/data directly.
- **Controllers** — [lib/controllers/](lib/controllers/): `GetxController` subclasses
  (e.g. `auth_controller.dart`, `magistrate_home_controller.dart`,
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
