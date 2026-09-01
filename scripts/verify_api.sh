#!/usr/bin/env bash
# The five checks to run against the live API before designing around
# anything. The API is the authority; the documents are a snapshot.
#
#   ./scripts/verify_api.sh https://<host> magistrate '<password>'
#
# Tell the backend team if any of this has moved.
set -uo pipefail

HOST="${1:-}"
USERNAME="${2:-magistrate}"
PASSWORD="${3:-}"

if [[ -z "$HOST" || -z "$PASSWORD" ]]; then
  echo "usage: $0 https://<host> <username> <password>" >&2
  exit 64
fi

BASE="$HOST/api/v1"
JSON='Accept: application/json'

echo "== 1. Login returns a token =========================================="
LOGIN=$(curl -s -X POST "$BASE/auth/device/login" \
  -H "$JSON" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"device_name\":\"verify.sh\"}")
echo "$LOGIN" | head -c 600; echo

TOKEN=$(printf '%s' "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
if [[ -z "$TOKEN" ]]; then
  echo "!! No token. Check the credentials and the host, then stop here." >&2
  exit 1
fi

AUTH="Authorization: Bearer $TOKEN"

echo "== 2. The token opens the session endpoint ==========================="
curl -s "$BASE/auth/device/session" -H "$AUTH" -H "$JSON" | head -c 900; echo

echo "== 3. The dashboard is area-scoped ==================================="
echo "   Compare 'scope' and 'receivable.owed' against an administrator's."
echo "   They must differ, or the scoping is not doing what it claims."
curl -s "$BASE/reporting/dashboard" -H "$AUTH" -H "$JSON" | head -c 1200; echo

echo "== 3b. The full defaulters register opens for a magistrate ==========="
curl -s "$BASE/reporting/reports/defaulters" -H "$AUTH" -H "$JSON" | head -c 900; echo

echo "== 4. Cases come back with can_* flags =============================="
curl -s "$BASE/enforcement/cases?per_page=3" -H "$AUTH" -H "$JSON" | head -c 1200; echo

echo "== 5. No token is a 401, not a 500 =================================="
printf '   status: '
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/auth/device/session" -H "$JSON"

echo
echo "Also worth capturing before writing more models (see QUESTIONS.md):"
for path in \
  "/enforcement/seals?per_page=2" \
  "/enforcement/fines?per_page=2" \
  "/property/properties?per_page=2" \
  "/legal/cases?per_page=2" \
  "/location/postings" ; do
  echo "-- GET $path"
  curl -s "$BASE$path" -H "$AUTH" -H "$JSON" | head -c 700; echo
done
