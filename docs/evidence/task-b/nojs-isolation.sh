# usage: bash nojs.sh <label>  (in worktree) — build, start, GET lead page, replay its note form without JS
set -uo pipefail
. /private/tmp/claude-501/measure-wt-bin/server.sh
npm run build >/dev/null 2>&1 || { echo "$1: BUILD FAILED"; exit 1; }
start_server /private/tmp/claude-501/nojs.log
trap stop_server EXIT
H=$(mktemp); curl -s -b leaddesk_session=demo-u_olena http://localhost:3000/dashboard/leads/lead_0001 > $H
ARGS=(); while IFS= read -r l; do ARGS+=(--form-string "$l"); done < <(node -e '
const html=require("fs").readFileSync(process.argv[1],"utf8");const i=html.indexOf("name=\"note\"");
const f=html.slice(html.lastIndexOf("<form",i),i);
for(const m of f.matchAll(/<input type="hidden" name="([^"]+)"(?: value="([^"]*)")?/g))console.log(m[1]+"="+(m[2]??"").replace(/&quot;/g,"\"").replace(/&amp;/g,"&"))' $H)
echo "$1: hidden=${#ARGS[@]}/2 $(curl -s --max-time 10 -o /dev/null -w 'HTTP %{http_code} %{time_total}s' -b leaddesk_session=demo-u_olena -X POST http://localhost:3000/dashboard/leads/lead_0001 "${ARGS[@]}" --form-string "leadId=lead_0001" --form-string "note=  ")"
