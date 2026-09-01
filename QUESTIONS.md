# Questions for MCQ — written down rather than guessed

A guess that reaches production in a revenue system is expensive to unpick.
These are the things the three documents do not settle, listed with what the
app does in the meantime and what would have to change once there is an
answer.

## 1. Test-account passwords — the last thing blocking real verification

The staging host is **`https://stag.planmycrew.com`** and is now the app's
default (`ApiConstants.host`, overridable with
`--dart-define=MCQ_API_HOST=…`).

What has been confirmed against it, unauthenticated:

| Check | Result |
| --- | --- |
| `GET /auth/device/session` with no token | `401` `{"message":"You must sign in to continue.","code":"unauthenticated"}` — not a 500, and it carries a sentence written for the officer |
| `GET /reporting/dashboard` with no token | `401` |
| `POST /auth/device/login` with `{}` | `422` with `errors.username`, `errors.password`, `errors.device_name` and `code":"validation_failed"` |

All three are the shapes the client already handles, and `device_name` is
confirmed required. What is still needed is **the password for `magistrate`**
(and ideally `admin`, to prove the dashboard is genuinely area-scoped by
comparing `scope` and `receivable.owed` between the two).

With that, run:

```bash
./scripts/verify_api.sh https://stag.planmycrew.com magistrate '<password>'
```

Until then every model in `lib/models/` is written from the documents and is
*defensive* — unknown fields are kept, missing fields fall back rather than
throw — but the payload shapes behind the token are unverified.

## 1b. `Accept-Language: ur` came back in English

On staging, this returns English:

```bash
curl -s -X POST https://stag.planmycrew.com/api/v1/auth/device/login \
  -H 'Accept: application/json' -H 'Accept-Language: ur' \
  -H 'Content-Type: application/json' -d '{}'
# {"message":"The username field is required. (and 2 more errors)", …}
```

The app sends `Accept-Language: en|ur` on every request and shows server
messages **verbatim**, on the documents' instruction not to translate server
strings on the client. If validation messages are not translated server-side,
an officer working in Urdu sees Urdu chrome with English errors under the
fields.

Two possibilities, and the answer changes nothing in the app but does change
what MCQ ships: either the `ur` language files are not deployed on this host,
or the locale is only resolved for an authenticated request (there is no user
to read `locale` from before sign-in). Worth checking with a token, and worth
confirming that enum `label`s and 409 refusals *are* translated — those are
the strings the app leans on most.

## 2. The `action_type` enum — narrowed, not settled

The build brief's action-sheet table is the first document to write these
values down, and the app now offers exactly them:

`site_visit`, `verbal_warning`, `final_warning`, `payment_promised`,
`reminder_visit_set`, `notice_served`, `other` — see `FieldWriteEnums`.

Two things are still open:

- **Is that the whole enum?** `POST /enforcement/cases/{case}/actions`
  validates with an enum rule and a value the app offers but the server does
  not have is a 422 on a dropdown the app itself put in front of an officer.
- **The labels are a second source of truth.** They live in `lib/l10n/` in
  two languages because there is no options endpoint returning
  `{value,label}` the way every other enum does. Add one and both tables can
  go. Until then, a value the server sends that the app does not know renders
  as itself rather than asserting — see `tEnum()`.

`fine_type` is fixed by the contract (`non_payment`, `seal_violation`,
`unauthorised_use`, `encroachment`, `other`) and is safe. `inspection_type`
has the same problem as `action_type`, more mildly.

## 2b. `promised_payment_date` and `next_visit_date`

`payment_promised` and `reminder_visit_set` are useless without their date —
a promise with no date is a note, and a revisit with no date never reaches
the follow-ups queue. The app sends them as top-level fields alongside
`action_type`:

```jsonc
{ "action_type": "payment_promised", "promised_payment_date": "2026-09-06", … }
{ "action_type": "reminder_visit_set", "next_visit_date": "2026-09-10", … }
```

Confirm the field names. They are named in the brief's §7 table and nowhere
else, and the app refuses to submit without them rather than letting the
server 422 an officer standing in a bazaar.

## 3. `can_unseal` or `can_release`?

The build brief lists `can_seal`, `can_close`, `is_live`, `is_sealed`,
`visit_overdue`, `requires_approval`, `awaiting_approval`, `can_approve`. The
developer prompt lists `can_seal`, `can_unseal`, `can_fine`,
`can_record_action`. The API contract mentions `can_unseal` on a seal.

The app reads flags as a map and treats either name as the same thing
(`CanFlags.canRelease`), defaulting to *not permitted* when neither is
present. Confirming the real name would let that alias go.

## 4. How should a 409 on a queued offline record be presented?

Left open by the brief (section 11.12). What the app does now:

- the record is **never** discarded;
- it goes to "Waiting to sync" → *Needs your attention*, with the server's
  own sentence attached verbatim;
- the officer gets two explicit choices, *Send again* and *Discard this
  record*, and discarding names the shop and the allottee first.

If MCQ wants something else — an escalation to a supervisor, a mandatory
remark before discarding, a report of dropped records — say so, because it
changes the queue screen.

## 5. Are local visit reminders enough for the first release?

There is no device-registration endpoint and no push integration. The app
schedules local notifications from `next_visit_date` on the cases it has
loaded (`VisitReminderService`), which means an officer who has not opened
the app since a case was rescheduled will hold a stale reminder.

If that is not good enough, a device-registration endpoint plus FCM is
backend work.

## 6. Two things the app deliberately does not do

Neither is a gap in the app; both are decisions worth confirming.

- **No arithmetic on money, anywhere.** If a screen needs a figure the API
  does not return — a per-area subtotal, a sum of selected rows — it is a
  backend request, not a client workaround. Say which figures are wanted.
- **Inspections are not queued offline.** They are a one-step multipart
  write with no `client_action_uuid`, so a blind retry could record the same
  inspection twice. An officer with no signal cannot record one. If
  inspections need to work offline, they need an idempotency key like the
  other four field writes.

## 7. Smaller things

- **`GET /reporting/reports/defaulters` and the enforcement case id.** The
  documented row carries `property_id` but no case id, so tapping a
  defaulter opens the *property* rather than its case when there is one. If
  the view can carry `enforcement_case_id`, the officer saves a hop; the app
  already reads it if present.
- **A live stay order on a property.** The app asks
  `GET /legal/cases` and matches on `property_id` to hide the seal button
  before the server refuses it. A flag on the case or property payload
  (`has_live_stay`) would be cheaper and more reliable; the app reads that
  too if it appears.
- **Bulk SMS from a test build.** The demo register has three real handsets
  attached to the first three allottees. Confirm which host is safe to
  impose fines against.

## 8. `paid_since_promise` — a figure the app is not allowed to compute

The brief asks the follow-ups queue to draw *"Paid ₨3,000 since promising"*
(§10). The payload carries `outstanding_at_promise` and `outstanding_now`,
and the difference between them is exactly the sentence an officer would
quote to a shopkeeper at a counter.

**The app will not compute it.** Subtracting two server amounts in Dart is
the same error as adding them, and rule one says every figure the app
displays comes from the server. So the screen shows both figures verbatim
and states the movement in words — *"The balance has come down since he
promised"* / *"has not moved"* — which carries the useful part of the
signal without inventing a number.

To draw the brief's actual sentence, add `paid_since_promise` (a decimal
string) to each `field/follow-ups` row. One field, and the app will use it
the day it appears.

## 9. Seal and unseal payload field names — two documents disagree

The contract-derived client sent `reason` and `action_date`. The build brief
(§9) names `seal_reason`, `sealed_on` and `seal_photo_path` on a seal, and
`unseal_reason` and `unsealed_on` on a release.

The app currently sends **both spellings** on both writes. That is
deliberate and it is not a state to leave in place: extra keys are usually
ignored by a Laravel `validate()`, but a seal refused by a 422 on a field
name is an officer standing at a shutter with nothing to show for it, and
guessing one of the two was the worse risk.

Say which is real and the duplicates come out — `EnforcementRepository`
`sealShop`/`releaseSeal` and `SealFormController._sealBody`/`_releaseBody`.

## 10. Which filters `field/defaulters` actually accepts

The brief documents `area_id`, `search`, `never_paid` and `limit`. The
screen's filter chips are *All · Never paid · Promise broken · Sealed*, so
the last two are applied to the rows already fetched rather than sent as URL
parameters the server would ignore. An ignored filter that looks applied is
worse than no filter at all.

If `promise_broken=1` and `sealed=1` exist, say so and they move up into the
request, which also fixes the count under the header.

## 11. `GET /reporting/map` — the pin payload

The brief names the endpoint and `defaulters_only=1` but not the row shape.
The app reads `map: {latitude, longitude}` (falling back to top-level
`latitude`/`longitude`), `property_id`, `property_code`, `shop_no`,
`area_name`, `market_name`, `allottee_name`, `mobile_no`, `outstanding`,
`is_sealed`, `is_vacant`, `seal_no`, and accepts either a bare array or
`{units: […]}`.

Rows with no usable coordinate are **counted and reported in a footnote**,
never silently dropped — a bazaar that looks empty on a map is not the same
as a bazaar with nothing in it. Confirm the shape, and confirm whether the
endpoint is area-scoped the way the rest of the reporting module is.

## 12. The Urdu needs a native reviewer before the demo

Every string in `lib/l10n/strings_ur.dart` is present — a test enforces
parity with English and it will not let a new screen ship half translated —
and the layout, line height and typeface are built for Nastaliq rather than
retrofitted. But the brief says plainly: **do not machine-translate, get the
Urdu reviewed by somebody who reads it.**

The strings added for the field module have not been through that review.
The magistrate demo account is deliberately set to Urdu, so this is the path
MCQ will see first. It is a half-day of somebody's time and it should happen
before the demo, not after it.

## 13. The `field/*` endpoints are still unverified

Everything in §1 applies to the seven new endpoints as well. Every model in
`lib/models/field/` is written from the brief and is defensive — a missing
or re-typed field falls back and asserts in debug rather than throwing in a
magistrate's hand — but no payload behind the token has been seen. The
first thing to run once there is a password is:

```bash
curl -s -H "Authorization: Bearer <token>" \
  https://stag.planmycrew.com/api/v1/enforcement/field/beat | python3 -m json.tool
```

That one call drives the entire home screen. If it matches, everything else
follows.

## 14. The warning amber has changed, and the web application should follow

The handset's status palette was checked for perceptual separation — under
normal vision and under the three common forms of colour blindness — against
the surface each colour sits on. Two of the four failed:

| Pair | Normal vision ΔE | Protanopia ΔE | Verdict |
| --- | --- | --- | --- |
| old danger `#D92D20` ↔ old warning `#B54708` | 7.7 | **1.5** | fail — the same colour to a large minority of readers |
| new danger `#D92D20` ↔ new warning `#BC8A00` | 17.9 | 8.3 | pass |

(ΔE in OKLab ×100; the working threshold is ≥15 for normal vision and ≥8
under simulated CVD.)

That pair is **the app's single most important distinction** — "this shop is
overdue" against "this shop promised and the promise stands" — and roughly
one man in twelve could not see it. Red is unchanged; the amber moved from a
burnt orange to a true gold-brown, and it now differs in *lightness* as well
as hue, so the two also survive greyscale and direct sunlight.

The information blue moved with it, `#0A7FB0` → `#1273A8`, to clear the same
floor against the settled emerald.

**The question for MCQ:** the web application uses the old values. A pill
that is amber on the desk and gold-brown on the handset is the kind of small
inconsistency that makes an officer doubt both. Should the web application
adopt these, or should the corporation's brand guide be the authority and the
handset revert — accepting the colour-blindness failure, and relying on the
icon and the word each pill already carries?

The app is safe either way: colour is never the only signal here. But it
should be one system, and this is a decision for MCQ rather than for the
client.
