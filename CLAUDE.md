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

## Reading project state

Don't rely on memory or assumptions about this codebase across turns/sessions. For every
task, read the actual current files in the project directory first (widgets, models,
controllers, views, data) rather than assuming prior structure, since the code may have
changed since it was last read.
