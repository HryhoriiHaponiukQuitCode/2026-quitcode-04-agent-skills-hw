#!/usr/bin/env bash
# Task B: the Verify items of building-client-form, checked against the note form from run-1.
#   bash docs/evidence/task-b/verify-note-form.sh   (repo root; builds and starts :3000)
# "Without JavaScript" is emulated the way a browser without JS submits: the <form> from the server
# HTML (with React's hidden $ACTION_* inputs for the bound action) posted as multipart, no Next-Action header.
set -euo pipefail
OUT=docs/evidence/task-b/run-2/verify.txt
LOG=$(mktemp); PAGE=$(mktemp)
npm run build >/dev/null 2>&1
. docs/evidence/bin/server.sh
start_server "$LOG"
trap 'stop_server; rm -f "$LOG" "$PAGE" "$BODY"' EXIT
U=http://localhost:3000/dashboard/leads/lead_0001
OLENA="leaddesk_session=demo-u_olena"; MARTA="leaddesk_session=demo-u_marta"
notes() { curl -s -b "$OLENA" "$U" | grep -o "$1" | wc -l | tr -d ' '; }

# Hidden inputs React rendered into the note form (progressive enhancement of the bound action).
curl -s -b "$OLENA" "$U" > "$PAGE"
ARGS=()
while IFS= read -r l; do ARGS+=(--form-string "$l"); done < <(node -e '
const html = require("fs").readFileSync(process.argv[1], "utf8");
const i = html.indexOf("name=\"note\"");
const form = html.slice(html.lastIndexOf("<form", i), i);
for (const m of form.matchAll(/<input type="hidden" name="([^"]+)"(?: value="([^"]*)")?/g))
  console.log(`${m[1]}=${(m[2] ?? "").replace(/&quot;/g, "\"").replace(/&amp;/g, "&")}`);' "$PAGE")
BODY=$(mktemp)
nojs() { # $1 cookie, $2 note text -> HTTP code; response HTML in $BODY
  curl -s --max-time 15 -o "$BODY" -w "%{http_code}" -b "$1" -X POST "$U" "${ARGS[@]}" --form-string "note=$2"
}
has() { grep -c -- "$1" "$BODY" | tr -d ' '; }
{
  echo "# Task B verify · $(git rev-parse --short HEAD)$(git diff --quiet -- app components lib || echo +dirty) · build $BUILD_ID · pid $SERVER_PID · $(date -u +%FT%TZ)"
  NAMES=""; for a in "${ARGS[@]}"; do [ "$a" != "--form-string" ] && NAMES="$NAMES ${a%%=*}"; done
  echo "hidden inputs in the server-rendered note form: $(( ${#ARGS[@]} / 2 )) —$NAMES"
  echo "no-JS POST as owner, note 'VERIFY-NOJS-1': HTTP $(nojs "$OLENA" 'VERIFY-NOJS-1') · note on page: $(notes VERIFY-NOJS-1)"
  echo "no-JS POST as marta (other workspace), 'VERIFY-MARTA': HTTP $(nojs "$MARTA" 'VERIFY-MARTA') · note on page: $(notes VERIFY-MARTA)"
  echo "no-JS POST without cookie, 'VERIFY-ANON': HTTP $(nojs '' 'VERIFY-ANON') · note on page: $(notes VERIFY-ANON)"
  echo "no-JS POST as owner, empty note: HTTP $(nojs "$OLENA" '   ') · aria-invalid=true: $(has 'aria-invalid="true"') · role=alert: $(has 'role="alert"') · 'Напишіть текст нотатки': $(has 'Напишіть текст нотатки')"
  LONG=$(printf 'x%.0s' $(seq 1 501))
  echo "no-JS POST as owner, 501 chars: HTTP $(nojs "$OLENA" "$LONG") · error 'Не більше 500': $(has 'Не більше 500') · typed text kept in textarea: $(grep -c ">$LONG</textarea>" "$BODY" | tr -d ' ') · saved: $(notes "$LONG")"
  echo "server log lines mentioning the note text or an email/phone: $(grep -cE 'VERIFY-|@|\+380' "$LOG" || true)"
  echo "server log lines total: $(wc -l < "$LOG" | tr -d ' ')"
} | tee "$OUT"
