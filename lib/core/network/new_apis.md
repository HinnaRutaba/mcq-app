# MCQ Mobile — one application for the magistrate, the CMO and the Administrator

**Audience:** the mobile developer extending the magistrate app into a shared
application. The server is finished and tested; this guide is the contract.

Companion files:

| File                                                                     | What it is                                                                                                |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `docs/MOBILE_API.md`                                                     | This guide: rules, field meanings, screens, errors.                                                       |
| `docs/MOBILE_API_EXAMPLES.md`                                            | Real request/response pairs, captured from the tests (generated).                                         |
| `docs/MCQ-Mobile.postman_collection.json`                                | Importable Postman v2.1 collection, with captured examples attached.                                      |
| `docs/MCQ-Mobile.postman_environment.json`                               | Environment template: placeholders only. Fill it in locally.                                              |
| `docs/MAGISTRATE_API.md` + `docs/MCQ-Magistrate.postman_collection.json` | The magistrate's field screens in full (generated). Still current; read section 6 below for what changed. |

`docs/MOBILE_API_MAGISTRATE.md` is superseded. Do not build against it.

---

## 1. Rules that apply to every call

1. **Base URL.** Staging (UAT): `https://stag.planmycrew.com`. Production:
   `https://mrms.mcq.gob.pk`. Every path below starts `/api/v1/…`.
2. **Bearer token** on every call except sign-in:
   `Authorization: Bearer <token>`, plus `Accept: application/json`. Keep the token
   in the OS keychain. Never log it.
3. **The envelope.** Success: `{"data": …, "message": "…"}` (lists add `meta` and
   `links`). Failure: `{"message": "…", "code": "…", "errors": {"field": ["…"]}}` —
   at the **top level**; there is no nested `error` object.
4. **Money is a string** (`"12500.00"`). Never parse it, never add two amounts on
   the phone. Every total you need is computed by the server.
5. **Ids are strings** on agreement-workspace resources (`"id": "41"`); the field
   endpoints return integers, as before. Send them back exactly as received.
6. **Dates** are `YYYY-MM-DD`; timestamps are ISO 8601 with offset. Display in
   Asia/Karachi. Date filters are inclusive and in Asia/Karachi.
7. **The server decides everything.** Draw buttons from what the server says
   (`mobile.capabilities`, `stage.act_options`). Hiding a button is a courtesy;
   every endpoint authorises again and refuses with 403.

---

## 2. Who sees what — capability matrix

The app draws a workspace when the session's `mobile.workspaces` contains it. An
officer holding two roles gets both; there is no "highest role".

| Capability (`mobile.capabilities`)                               |                              Magistrate                              | CMO | Administrator | Permission behind it                                      |
| ---------------------------------------------------------------- | :------------------------------------------------------------------: | :-: | :-----------: | --------------------------------------------------------- |
| **Workspace `field`** (opens on `field.record_action`)           |                                  ✓                                   |  –  |       –       | `enforcement.action.record`                               |
| `field.dashboard`, `field.open_case`, `field.follow_ups`         |                                  ✓                                   |  –  |       –       | `enforcement.case.view` / `.case.manage` / `.action.view` |
| `field.impose_fine`, `field.seals`, `field.seal`, `field.unseal` |                                  ✓                                   |  –  |       –       | `enforcement.fine.impose`, `enforcement.seal.*`           |
| `field.trade_licences`                                           |                                  ✓                                   |  –  |       –       | `trade.licence.view`                                      |
| **Workspace `agreements`** (opens on a reviewing permission)     |                                  –                                   |  ✓  |       ✓       | below                                                     |
| `agreements.endorse` (review, endorse, query, answer)            |                                  –                                   |  ✓  |       –       | `allotment.intake.forward`                                |
| `agreements.dispatch`                                            |                                  –                                   |  ✓  |       –       | `allotment.intake.dispatch`                               |
| `agreements.decide` (approve, reject, return)                    |                                  –                                   |  –  |       ✓       | `allotment.intake.approve`                                |
| `agreements.view`                                                |                                  –                                   |  ✓  |       ✓       | `allotment.intake.view`                                   |
| `agreements.applicant_documents`                                 |                                  –                                   |  ✓  |       ✓       | `allottee.document.view`                                  |
| `agreements.execution_evidence` (signed scan)                    |                                  –                                   |  ✓  |       ✓       | `allotment.intake.execution.view`                         |
| `agreements.execution_video`                                     |                                  –                                   |  –  |       ✓       | `allotment.intake.execution.video`                        |
| `agreements.terminations`                                        |                                  –                                   |  ✓  |       ✓       | `allotment.termination.view`                              |
| `agreements.taxation_review`                                     | Taxation Superintendent only — the same endpoints work for that role |

Not on the phone for anybody: preparing a case, uploading captures, printing
stamp paper, the numbered PDF, the signing visit, signed-scan upload and
activation. Those are Estate's, on the web. A magistrate never gets the agreement
workspace and cannot create an agreement or an allottee (403).

---

## 3. Authentication and the session

| Step               | Call                                                                              | Notes                                                                                                                                                                                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sign in            | `POST /api/v1/auth/device/login` `{username, password, device_name}`              | Username, not email. Returns `token`, `expires_at`, `user`, `mobile`. Signing in again from the same `device_name` replaces that device's token.                                                                                                                                                     |
| On launch / resume | `GET /api/v1/auth/device/session`                                                 | `401` → the token is dead: clear it, show sign-in. Otherwise redraw from `mobile` — it is recomputed every call, so a role or permission changed after sign-in shows here.                                                                                                                           |
| Sign out           | `POST /api/v1/auth/device/logout`                                                 | Revokes this device's token only.                                                                                                                                                                                                                                                                    |
| First login        | `PUT /api/v1/auth/password` `{current_password, password, password_confirmation}` | While `mobile.password_change_required` is true, every other endpoint answers `403` with `code: password_change_required`. The change **revokes every token of the account**: sign in again with the new password. The new password is at least 12 characters and is checked against known breaches. |

`user.mobile_on_file` is false while a provisioned account still holds the
placeholder number `0000000000`. Ask the officer for their mobile on the profile
screen; `PUT /api/v1/profile` accepts other changes without it (an unchanged
number is not re-validated), and a number that is given must be a valid
Pakistani mobile.

`mobile` block:

```json
{
  "workspaces": ["agreements"],
  "capabilities": ["agreements.decide", "agreements.execution_evidence", "…"],
  "password_change_required": false
}
```

Failures:

| Situation                                                         | Response                                                                                             |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Wrong password, unknown username, **switched-off account**        | `422`, one identical sentence for all three. Do not tell the user which.                             |
| Too many attempts                                                 | `429` (10 a minute per address), and the account locks after repeated failures (`422` saying so).    |
| Token expired (30 days by default), revoked, or the account reset | `401` on any call.                                                                                   |
| Account deactivated after sign-in                                 | Its tokens are revoked: `401`.                                                                       |
| Permission removed after sign-in                                  | `403` on the affected endpoints immediately; `session.mobile` no longer lists it.                    |
| Temporary password                                                | `403 password_change_required` everywhere except session, sign-out, profile and the password change. |

OTP: there is no OTP on staff sign-in, and this work added none.

---

## 4. The agreement workspace (CMO, Administrator)

### 4.1 The workflow

Preparation: **Estate → Taxation → CMO → Administrator**. Dispatch of an approved
case: **Administrator → CMO → Taxation → Estate**, who prints and activates.

| `status.value`              | With          | The phone may                                                                                                   |
| --------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------- |
| `pending_taxation`          | Taxation      | (Taxation only) forward, query-answer, return to Estate                                                         |
| `pending_cmo`               | CMO           | **endorse** (signed), **return** to Estate or **query** Taxation, **respond** to a query from the Administrator |
| `pending_admin`             | Administrator | **approve** (signed), **reject**, **return** to Estate, or query Taxation or the CMO                            |
| `pending_dispatch`          | CMO           | **dispatch** to Taxation                                                                                        |
| `pending_execution_handoff` | Taxation      | (Taxation only) hand to Estate                                                                                  |
| `approved`                  | Estate        | nothing on the phone; Estate prints and activates                                                               |
| `activated`                 | —             | read only; the agreement now exists                                                                             |
| `returned`                  | Estate        | read only                                                                                                       |
| `rejected`, `cancelled`     | —             | read only                                                                                                       |

Rules the server enforces, which the app should explain rather than work around:

- **Four people per cycle.** Whoever acted at one stage of a cycle cannot act at
  another. Reason `separation_of_duties`.
- **An endorsement counts only on the content it was given on.** If Estate
  changed the case after the CMO endorsed it, the Administrator cannot approve
  until it comes round again (`prior_step_not_valid`, error
  `intake.endorsement_not_valid`).
- **A query must be answered first.** While a query is open at your stage, the
  onward act is closed (`query_open`); answer with `respond`.
- **The shop must still be where it was reviewed.** If its market, area or zone
  changed since submission, onward acts are refused (`location_changed`; error
  `intake.location_changed` or `intake.location_unverified`). Return the case to
  Estate.
- **Endorse and approve are signed** with the officer's signature on file. With
  none, `signature_required`. The officer adds one on the web (profile → My
  signature).
- **Approval does not create an agreement.** Only Estate's activation does.

### 4.2 Dashboard — `GET /api/v1/allotment/intakes/dashboard`

Filters: `market_id`, `from`, `to` (`YYYY-MM-DD`, inclusive, Asia/Karachi).
**What the dates bound depends on the block**, and each block's linked list uses
the same rule, so a tile and its list always count the same cases:

| Block                       | `from`/`to` bound                   | Linked list                                                      |
| --------------------------- | ----------------------------------- | ---------------------------------------------------------------- |
| `waiting`, `returned_by_me` | nothing — these are _now_           | `scope=awaiting_me`, a queue, or `returned_by_me`: dates ignored |
| `my_actions`                | the day **you** took that act       | `scope=acted:<action>`: the same acts, same days                 |
| `register`                  | the day the case was last submitted | `scope=all`: same                                                |

Every figure counts **cases** (counter agreement cases), not agreements or acts,
unless its key says otherwise. Every tile carries the list `scope` that opens
exactly the cases it counted.

| Key                        | Meaning                                                                                                                                                                                                                                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `waiting.total`            | Cases waiting for **this officer, now** (`scope=awaiting_me`). Ignores `from`/`to`.                                                                                                                                                                                                                     |
| `waiting.queues[]`         | The same, split: `review` (CMO review), `queries` (a query waiting for your answer), `dispatch` (approved, waiting for your dispatch), `decision` (Administrator), `execution_handoff` (Taxation). Only the queues the officer works are listed.                                                        |
| `returned_by_me.count`     | Cases whose **latest act** is this officer's return or query — still away from them. Falls to 0 when answered or resubmitted.                                                                                                                                                                           |
| `my_actions[]`             | What this officer **did**: `action`, `cases` (distinct cases), `acts` (times). A case endorsed, returned and endorsed again is 1 case, 2 acts. `endorsed` is the CMO's recommendation, **not** approval; only `approved` is the Administrator's decision. Bounded by `from`/`to` on the day of the act. |
| `register.by_status[]`     | Every non-draft case the officer may list, by status (all statuses listed, zeroes included). Bounded by `from`/`to` on the day of last submission.                                                                                                                                                      |
| `register.in_progress`     | Of those, still open.                                                                                                                                                                                                                                                                                   |
| `register.activated_cases` | Of those, activated.                                                                                                                                                                                                                                                                                    |
| `register.agreements_live` | Of those, whose resulting agreement is still active or suspended (a later termination ends the agreement, not the case).                                                                                                                                                                                |

A resubmitted case is still one case everywhere above.

### 4.3 Lists — `GET /api/v1/allotment/intakes`

| Parameter             | Values                                                                                                                                                                                                                                                                                                                                          |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scope`               | `awaiting_me`, `review`, `queries`, `dispatch`, `decision`, `returned_by_me`, `acted:<action>` (`endorsed`, `approved`, `rejected`, `returned`, `responded`, `dispatched`, `taxation_forwarded`, `execution_forwarded`), `decided_by_me` (any of those), `history` (Administrator's decisions), `all` (every non-draft case the reader may see) |
| `q`                   | Case number, applicant's name, CNIC digits (5+), or shop number                                                                                                                                                                                                                                                                                 |
| `market_id`, `status` | Narrowing filters                                                                                                                                                                                                                                                                                                                               |
| `from`, `to`          | Inclusive days in Asia/Karachi. For `acted:<action>`, `history` and `decided_by_me`: the day **you** took the act. For waiting queues (`awaiting_me`, `review`, `queries`, `dispatch`, `decision`, `returned_by_me`): ignored. Otherwise (`all`): the day of last submission.                                                                   |
| `page`, `per_page`    | `per_page` 1–100, default 25                                                                                                                                                                                                                                                                                                                    |

Response: `data[]` of case rows, `meta` (`current_page`, `last_page`, `per_page`,
`total`), `links`. An empty page is `data: []` with `meta.total: 0` — show the
empty state for that tab, never an error. `422` on a bad filter (e.g. `to` before
`from`).

A row carries the same shape as the detail without the expensive parts
(`stage.act_options`, `applicant.record`).

### 4.4 Case detail — `GET /api/v1/allotment/intakes/{id}`

The fields a reviewer reads, by section:

| Section       | Fields                                                                                                                                                                                                                                                                              |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Identity      | `id`, `intake_no`, `case_type`, `status`, `approval_route`, `content_revision`, `lock_version`, `with_branch` (`estate`, `taxation`, `cmo`, `administrator`), `next_action`                                                                                                         |
| Shop          | `shop.shop_no`, `shop.market`, `shop.area`, `shop.zone`, `shop.address`, `shop.verified`, `shop.problem`, `shop.reviewed_location` (market/area/zone/shop at last submission), `shop.location_changed_since_review`                                                                 |
| Applicant     | `applicant.*` (name, father, CNIC, mobile, address, business, NTN), `applicant.record` (the register record it will become, and whether it matches)                                                                                                                                 |
| Witnesses     | `witnesses[]` (position, name, father, CNIC, mobile)                                                                                                                                                                                                                                |
| Money         | `amounts.*`: verified monthly rent, opening arrears, the date they are as of (`opening_arrears_as_of`), the instalment offer and its breakdown, first rent month, security deposit, the source figures from the register and the variance. All strings, all computed by the server. |
| Workflow      | `actions[]` in order: `action`, `actor`, `actor_role`, `branch`, `from_status`, `to_status`, `destination`, `remarks`, `at`, `case_revision`, `changes` (what a resubmission changed), `attachments[]`, `in_reply_to`                                                               |
| Latest return | `last_return` (who, when, remarks)                                                                                                                                                                                                                                                  |
| Open query    | `stage.query` (who asked, from which stage, what, when)                                                                                                                                                                                                                             |
| What I may do | `stage.act_options[]`, below                                                                                                                                                                                                                                                        |
| Documents     | `media[]`, `numbered_pdf`, `execution` (section 5)                                                                                                                                                                                                                                  |

`stage.act_options[]` lists every review act the reader holds the permission
for — never an Estate act:

```json
{
  "act": "approve",
  "allowed": false,
  "reason": "prior_step_not_valid",
  "method": "POST",
  "path": "/api/v1/allotment/intakes/41/approve",
  "signed": true,
  "remarks_required": false,
  "destinations": []
}
```

`reason` is null when allowed, else one of `not_at_stage`, `query_open`,
`no_open_query`, `separation_of_duties`, `prior_step_not_valid`,
`location_changed`, `signature_required`, `not_available`. For `return`,
`destinations` lists where this reader may send it (`estate`, `taxation`, `cmo`).
`allowed: true` means the server expects to accept it; it still re-checks.

### 4.5 Decisions

| Act                             | Path                   | Body                                                                                   |
| ------------------------------- | ---------------------- | -------------------------------------------------------------------------------------- |
| Endorse (CMO, signed)           | `POST …/{id}/endorse`  | `remarks?`, `client_uuid`, `lock_version`, `attachments[]?`                            |
| Approve (Administrator, signed) | `POST …/{id}/approve`  | same                                                                                   |
| Reject (Administrator)          | `POST …/{id}/reject`   | **`remarks` required** (10–2000 chars)                                                 |
| Return / query                  | `POST …/{id}/return`   | **`remarks` required**, `destination` (`estate`, `taxation`, `cmo`) from `act_options` |
| Answer a query                  | `POST …/{id}/respond`  | `remarks?`                                                                             |
| Dispatch (CMO)                  | `POST …/{id}/dispatch` | `remarks?`                                                                             |

- **`client_uuid`**: generate one UUID per tap, reuse it on retry. A retried act
  returns `200` with the case and records nothing twice. Reusing a UUID for a
  _different_ act is `409 intake.client_uuid_reused`.
- **`lock_version`**: send the value from the case you displayed. If another
  officer acted in between, `409 intake.changed_since_viewed` — reload, show what
  changed, let the officer decide again.
- **Attachments**: send as `multipart/form-data` with `attachments[]` (up to 5;
  PDF, JPEG, PNG, WebP; 12 MB each). A larger or disguised file is `422` naming
  the file. Remarks and the other fields go as form fields.
- The response is the updated case. Approved cases go to `pending_dispatch` —
  back to the CMO — never straight to Estate.
- There is no "cancel" for a reviewer. Reject ends a case; return sends it back.

### 4.6 Errors you will meet

| HTTP | `code`                                                       | Meaning → what to show                                                              |
| ---- | ------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| 401  | —                                                            | Token dead → sign-in                                                                |
| 403  | `password_change_required`                                   | Password screen                                                                     |
| 403  | (none) / `intake.acted_at_earlier_stage` / `intake.own_case` | Not yours to act on → reload the case, the button should be gone                    |
| 404  | —                                                            | No such case or document **for this case** (a document id from another case is 404) |
| 409  | `intake.changed_since_viewed`                                | Someone acted first → reload                                                        |
| 409  | `intake.wrong_stage`, `intake.no_query`                      | The case moved on → reload                                                          |
| 409  | `intake.endorsement_not_valid`                               | Content changed after the endorsement → return to Estate                            |
| 409  | `intake.location_changed`, `intake.location_unverified`      | Shop location changed → return to Estate                                            |
| 422  | `intake.no_signature`                                        | No signature on file → explain where to add one                                     |
| 422  | `intake.return_destination`                                  | Destination not allowed from this stage                                             |
| 422  | (validation)                                                 | `errors.<field>` → show under the field                                             |
| 429  | —                                                            | Slow down                                                                           |
| 500  | `database_error` + `reference`                               | Show the 8-character reference; MCQ IT can find the log                             |

---

## 5. Documents

All files stream through the API with the bearer token. None has a public URL,
and none may be written to shared storage on the phone. Responses carry
`Cache-Control: private, no-store`.

| Document                                                                                    | How to get it                                                                                                                                           | Who                                                   |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Applicant photo, thumb, signature, CNIC scans, witness CNICs/thumbs, certificates and deeds | `media[]` on the case: each has `id`, `slot`, `evidence_code`, `mime`, `is_pdf`, `filename`, `url` → `GET /api/v1/allotment/intakes/{id}/media/{media}` | Anybody who may view the case                         |
| Attachment on a workflow act                                                                | `actions[].attachments[].url` → `GET …/{id}/actions/{action}/files/{file}`                                                                              | Same                                                  |
| Saved numbered agreement PDF                                                                | `numbered_pdf` (null until Estate saves one) → `GET …/{id}/numbered-pdf`                                                                                | Same                                                  |
| Signed original scan and its versions                                                       | `execution.signed_scan.current` (and `.history[]`): each file has its parts' `url`s → `GET …/{id}/execution/parts/{part}`                               | `agreements.execution_evidence`                       |
| Signing video                                                                               | `execution.execution_video.current` — its `url`s are **null** when the reader may not play it (`execution_video.restricted: true`)                      | `agreements.execution_video` (Administrator, not CMO) |

A document id from another case, sent through this case's address, is `404`.

**The draft agreement is not available as a file.** The stamp-paper draft the web
shows is rendered in the browser from the case data with the approved template;
there is no server endpoint for it and this guide does not invent one. On the
phone, show the case's fields (section 4.4) and its captures. When Estate has
saved a numbered PDF, offer it as "Numbered copy" — it is the approved template
on the real stamp-paper numbers, not the signed original. The signed original is
the uploaded scan under `execution`. Label the three distinctly: **draft (data
only)**, **numbered copy (PDF)**, **signed original (scan)**.

---

## 6. The magistrate's field workspace — what changed

The field endpoints, their paths and their existing keys are unchanged; the full
reference is `docs/MAGISTRATE_API.md`. Three things changed in meaning, and the
app must follow them.

### 6.1 Debt is not default

`GET /api/v1/enforcement/field/defaulters` used to list every live agreement with
any balance. That balance includes opening arrears nobody has been billed for,
instalments still months away, and bills prepared but not sent — so at launch
almost every shop looked like a defaulter.

It now lists agreements with **overdue demand**: a rent bill that was **sent**
and whose **due date has passed**, still unpaid, less any part an officer agreed
for a later bill. Sorted by overdue amount, then whole debt.

Every card (and every unit card in `field/units`) carries `debt`:

| Field                  | Meaning                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `total_outstanding`    | Everything the ledger says is owed on the rent account. Same value as the old `outstanding`, which is kept.                                                        |
| `issued_unpaid`        | Unpaid on bills already sent, less any part agreed for a later bill.                                                                                               |
| `overdue`              | The part of `issued_unpaid` past its bill's due date. **The recovery figure.**                                                                                     |
| `deferred`             | Agreed by an officer for a later bill. Not overdue.                                                                                                                |
| `draft_amount`         | On a bill prepared and not yet sent. Nobody has been asked for it.                                                                                                 |
| `future_instalments`   | Old arrears on no bill yet (an instalment plan's later months, or opening arrears before their first bill).                                                        |
| `future_on_books`      | The part of `future_instalments` inside `total_outstanding`.                                                                                                       |
| `late_fees_unpaid`     | Unpaid late fees, inside `issued_unpaid`.                                                                                                                          |
| `other_charges_unpaid` | Fines and fees on bills of their own — a **separate** debt. Never add to `total_outstanding`.                                                                      |
| `opening_arrears`      | The historical balance recorded when the agreement started.                                                                                                        |
| `advance_held`         | Money paid ahead, held as credit.                                                                                                                                  |
| `oldest_due_date`      | The oldest due date still carrying unpaid money. `days_overdue` counts from it (it now looks through carried-forward bills; it used to read only the newest bill). |
| `next_due_date`        | The next due date not yet reached, or null.                                                                                                                        |

`field/beat` `queues[key=defaulters]`: `count` = agreements with overdue demand,
`amount` = sum of overdue (`amount_basis: "overdue"`), `total_debt` = the whole
debt of the same agreements. `field/round` adds `overdue` per bazaar beside
`outstanding`. `field/follow-ups` and `field/seals` add `overdue_now` beside
`outstanding_now`.

**"Today" is Quetta's day.** A bill due on 30 November is overdue from 00:00 on
1 December in Quetta (19:00 UTC on 30 November), on the web and in the field
alike; `months_behind`, `days_overdue` and commitment days count Quetta days.
Timestamps (`as_of`, `generated_at`) are still UTC instants.

Bills follow MCQ's calendar: a month's rent is prepared at month end, **issued on
the 1st of the next month**, due on the configured due day of that month
(currently the 25th). A bill is never overdue before its due date.

### 6.2 Former agreements still owing

`GET /api/v1/enforcement/field/defaulters?agreement=former` lists agreements that
have **ended** (cancelled, expired, transferred) whose former holder still owes.
Termination stops billing; it does not forgive. Each card adds:

- `agreement_state: "former"`, `agreement_status`, `ended.expiry_date`,
  `ended.billing_stop_period`;
- `current_occupancy`: `is_vacant`, `allotment_no`, `holder_name` — **who holds
  the shop now, who owes none of it.**

The debtor is the card's `allottee_*`. Never pursue the current occupant for it.

`field/units` adds `former_debt` (null when none): `agreements`,
`total_outstanding`, `overdue`, and the `endpoint` listing those debtors. A vacant
shop with former debt is not debt-free; a newly let shop does not inherit it.
Filter: `?property_id=` on the defaulter list.

### 6.3 An empty bazaar explains itself

`field/beat` adds `register`:

| Field                | Meaning                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `live_agreements`    | Active or suspended agreements in the officer's areas.                                    |
| `legacy_entries`     | Shops in the accepted legacy register in those areas.                                     |
| `pending_activation` | Counter cases there not yet activated (a count only — the field never sees case details). |
| `operational`        | `live_agreements > 0`.                                                                    |

At launch every shop is in the legacy register and none is live: units and
defaulters are empty, correctly. Shops appear one at a time when Estate activates
a counter agreement. Approved-but-not-activated cases never appear as
agreements.

### 6.4 Migration steps for the installed magistrate app

1. Read `debt.overdue` for "overdue" and `debt.total_outstanding` for "total
   debt". Do not label `outstanding` as overdue.
2. On the dashboard, label the defaulters tile with its `amount_basis`.
3. Add a "Former holders" list (`?agreement=former`) and show `former_debt` on
   unit cards.
4. When units/defaulters are empty, show `register` (e.g. "No agreements are
   live in your areas yet. 214 shops are in the legacy register; 3 counter cases
   are awaiting activation.").
5. Read the `mobile` block on sign-in and session, and route to the workspace it
   names.

Nothing was removed, so an un-updated app keeps working. It will simply show a
shorter defaulter list, the correct one.

### 6.5 Scoping, unchanged and verified

Every field list is limited to the officer's postings, re-read on every call: a
posting ended after sign-in narrows the next response. A guessed `property_id`,
`area_id` or search term outside the postings returns an empty list; an agreement
or document outside them is `403`. The person lookup (`field/person`) remains
city-wide by policy: it answers "is this person known", not "show me their
agreements".

---

## 7. Screens, and the call behind each

| Screen                      | Calls                                                 | Loading                                | Empty                                                 | Error / conflict                                                             |
| --------------------------- | ----------------------------------------------------- | -------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| Splash                      | `GET auth/device/session`                             | Splash                                 | —                                                     | 401 → sign-in                                                                |
| Sign-in                     | `POST auth/device/login`                              | Button spinner                         | —                                                     | 422 → one generic sentence; 429 → "try again in a minute"                    |
| Change password             | `PUT auth/password`, then sign-in again               | Button spinner                         | —                                                     | 422 → field errors                                                           |
| Workspace switcher          | from `mobile.workspaces`                              | —                                      | No workspace → "Nothing on this app for your account" | —                                                                            |
| CMO/Administrator home      | `GET allotment/intakes/dashboard`                     | Skeleton tiles                         | All zero → "Nothing is waiting for you"               | 403 → re-read session                                                        |
| Queue tab                   | `GET allotment/intakes?scope=…` (paginate)            | List skeleton; keep rows on refresh    | "No cases here" per tab                               | Keep old rows, show a retry bar                                              |
| Case                        | `GET allotment/intakes/{id}`                          | Skeleton                               | —                                                     | 404 → "This case is not available"; 403 → back to list                       |
| Decide                      | `POST …/{act}` from `act_options`                     | Disable the button; keep `client_uuid` | —                                                     | 409 → reload and say "Someone acted on this case first"; 422 → show `errors` |
| Document                    | `GET` the `url`                                       | Progress                               | —                                                     | 404/403 → "Not available to you"                                             |
| Field home                  | `GET enforcement/field/beat`                          | Skeleton                               | `register` sentence                                   | —                                                                            |
| Defaulters / Former holders | `GET enforcement/field/defaulters[?agreement=former]` | List skeleton                          | "Nobody in your areas is overdue"                     | —                                                                            |

Session expiry anywhere: a `401` from any call means clear the token and go to
sign-in, keeping any unsent decision's `client_uuid` so a retry after sign-in is
safe.

---

## 8. What is not on the server

- No server-rendered draft agreement (section 5).
- No push notifications; refresh the dashboard on resume.
- Termination and change requests run on the same chain and their endpoints work
  with a token (`/api/v1/allotment/termination-requests…`), but they are not on
  the reviewers' dashboard and have no captured examples here.
- No offline queue for agreement decisions. Decisions are online acts; the
  magistrate's field writes keep their `client_action_uuid` offline retry.
