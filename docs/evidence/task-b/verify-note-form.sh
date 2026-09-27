#!/usr/bin/env bash
# Task B: the Verify items of building-client-form, checked against the note form from run-1.
#   bash docs/evidence/task-b/verify-note-form.sh   (repo root; builds and starts :3000)
# "Without JavaScript" is emulated the way a browser without JS submits: the <form> from the server
# HTML (with React's hidden $ACTION_* inputs for the bound action) posted as multipart, no Next-Action header.
set -euo pipefail
OUT=docs/evidence/task-b/verify.txt
LOG=$(mktemp); PAGE=$(mktemp)
npm run build >/dev/null 2>&1
. docs/evidence/bin/server.sh
start_server "$LOG"
trap 'stop_server; rm -f "$LOG" "$PAGE"' EXIT
U=http://localhost:3000/dashboard/leads/lead_0001
OLENA="leaddesk_session=demo-u_olena"; MARTA="leaddesk_session=demo-u_marta"
notes() { curl -s -b "$OLENA" "$U" | grep -o "$1" | wc -l | tr -d ' '; }

# Hidden inputs React rendered into the note form (progressive enhancement of the bound action).
curl -s -b "$OLENA" "$U" > "$PAGE"
HIDDEN=$(node -e '
const html = require("fs").readFileSync(process.argv[1], "utf8");
const form = html.slice(html.lastIndexOf("<form", html.indexOf("name=\"note\"")), html.indexOf("</form>", html.indexOf("name=\"note\"")));
for (const m of form.matchAll(/<input type="hidden" name="([^"]+)"(?: value="([^"]*)")?/g))
  console.log(`-F\n${m[1]}=${(m[2] ?? "").replace(/&quot;/g, "\"").replace(/&amp;/g, "&")}`);' "$PAGE")
IFS=$'\n' read -r -d '' -a ARGS <<<"$HIDDEN" || true
nojs() { # $1 cookie, $2 note text -> HTTP code
  curl -s -o /dev/null -w "%{http_code}" -b "$1" -X POST "$U" "${ARGS[@]}" -F "note=$2"
}
{
  echo "# Task B verify · $(git rev-parse --short HEAD)$(git diff --quiet -- app components lib || echo +dirty) · build $BUILD_ID · pid $SERVER_PID · $(date -u +%FT%TZ)"
  echo "hidden \$ACTION inputs found in server HTML: $(( ${#ARGS[@]} / 2 ))"
  echo "no-JS POST as owner, note 'VERIFY-NOJS-1': HTTP $(nojs "$OLENA" 'VERIFY-NOJS-1') · note on page: $(notes VERIFY-NOJS-1)"
  echo "no-JS POST as marta (other workspace), 'VERIFY-MARTA': HTTP $(nojs "$MARTA" 'VERIFY-MARTA') · note on page: $(notes VERIFY-MARTA)"
  echo "no-JS POST without cookie, 'VERIFY-ANON': HTTP $(nojs '' 'VERIFY-ANON') · note on page: $(notes VERIFY-ANON)"
  echo "no-JS POST as owner, empty note: HTTP $(nojs "$OLENA" '   ')"
  LONG=$(printf 'x%.0s' $(seq 1 501))
  echo "no-JS POST as owner, 501 chars: HTTP $(nojs "$OLENA" "$LONG") · 501-char note on page: $(notes "$LONG")"
  echo "server log lines mentioning the note text or an email/phone: $(grep -cE 'VERIFY-|@|\+380' "$LOG" || true)"
  echo "server log lines total: $(wc -l < "$LOG" | tr -d ' ')"
} | tee "$OUT"
