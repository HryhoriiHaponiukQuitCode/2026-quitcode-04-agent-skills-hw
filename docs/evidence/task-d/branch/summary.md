# Evidence: task-d/branch

Packed by `docs/evidence/bin/pack-evidence.mjs`. Each section is one original file; the originals (and raw `transcript.jsonl`) are in `docs/evidence/raw-evidence.tar.gz`.

## `task-d/branch/check-contract-final.txt`

```text
$ node .claude/skills/integrating-n8n-webhooks/scripts/check-contract.mjs; echo "exit=$?"   # увесь проєкт
check-contract · root <repo> · full
n8n callers: lib/n8n/client.ts · callback routes: app/api/n8n/[event]/route.ts
C1   PASS no test webhook URL (/webhook-test/) in code or .env.example
C2   PASS no NEXT_PUBLIC_ variable for n8n / webhook / callback settings
C3   PASS requests to n8n only from lib/n8n/client.ts
C4   PASS the module that calls n8n starts with import "server-only"
C5   PASS every fetch to n8n has signal: AbortSignal.timeout(...)
C6   PASS requests to n8n send x-n8n-token, idempotency-key, x-correlation-id
C7   PASS request body is the envelope { version: 1, event, data }
C8   PASS a Server Action that triggers n8n does it inside after()
C9   PASS callback route reads the raw body; no request.json(), no JSON.parse before the signature check
C10  PASS callback signature: HMAC + length check + timingSafeEqual, never ===
C11  PASS callback timestamp checked against a 300 s window
C12  PASS callback idempotency-key read and bound to data.jobId of the signed body
C13  PASS no export const runtime = "edge"
C14  PASS no bodies, form data, personal data, tokens or signatures in console.* of n8n code
C15  PASS .env.example: N8N_WEBHOOK_BASE_URL, N8N_WEBHOOK_TOKEN, N8N_CALLBACK_SECRET, APP_BASE_URL
Summary: 15 PASS, 0 FAIL, 0 N/A
exit=0
```

## `task-d/branch/lead-check.txt`

```text
# lead-created check · 9ab228f · build lJIOIyp0ArAwPlUVguy23 · pid 61528 · 2026-09-27T14:21:20Z
no-JS POST / (lead form) -> HTTP 200 in 0.433904 s
mock log (mode immediately):
  | [mock-n8n] 2026-09-27T14:21:20.988Z POST /webhook/lead-created -> 200 in 1 ms auth=ok idempotency=new | headers: accept,accept-language,content-type,idempotency-key,user-agent,x-correlation-id,x-n8n-token | body 266 B 
server log n8n lines:
  | {"n8n":"out","event":"lead-created","correlationId":"4dbd2ecf-ecc9-4b95-81ee-8c94fd9c0719","attempt":1,"status":200,"ms":8}
server log lines with the submitted email / phone / message: 0
```

## `task-d/branch/scenario/build.log`

```text

> 2026-quitcode-04-agent-skills-hw@0.1.0 build
> next build

▲ Next.js 16.3.5 (Turbopack)
- Environments: .env.local
⚠ Warning: Next.js ignored package-lock.json in /Users/hryhorii_haponiuk because it is outside the current Git repository (/Users/hryhorii_haponiuk/Desktop/Work Folder/Agentic Course/2026-quitcode-04-agent-skills-hw).
 To use this directory, set `turbopack.root` in your Next.js config.

✓ Running next.config.ts took 10ms

  Creating an optimized production build ...
✓ Compiled successfully in 267ms
  Running TypeScript ...
  Finished TypeScript in 692ms ...
  Collecting page data using 9 workers ...
  Generating static pages using 9 workers (0/8) ...
  Generating static pages using 9 workers (2/8) 
db:listUsers: 1
  Generating static pages using 9 workers (4/8) 
  Generating static pages using 9 workers (6/8) 
✓ Generating static pages using 9 workers (8/8) in 127ms
  Finalizing page optimization ...

Route (app)
┌ ○ /
├ ○ /_not-found
├ ƒ /api/leads
├ ƒ /api/n8n/[event]
├ ƒ /dashboard
├ ƒ /dashboard/leads/[id]
├ ○ /login
├ ƒ /quotes/[id]
└ ○ /quotes/new


ƒ Proxy (Middleware)

○  (Static)   prerendered as static content
ƒ  (Dynamic)  server-rendered on demand

```

## `task-d/branch/scenario/mock.log`

```text
[mock-n8n] 2026-09-27T14:20:53.153Z listening on http://127.0.0.1:5678  mode=respond-202  delay=5000 ms  cloud-timeout=off
[mock-n8n] 2026-09-27T14:20:53.154Z production URLs: POST http://127.0.0.1:5678/webhook/<path>
[mock-n8n] 2026-09-27T14:20:53.154Z test URLs: not registered (start with --listen to open them for 120 s)
[mock-n8n] 2026-09-27T14:20:53.154Z header auth: x-n8n-token required (N8N_WEBHOOK_TOKEN is set)
[mock-n8n] 2026-09-27T14:20:53.154Z callbacks: signed, sent to the request's callbackUrl after 5000 ms (async modes)
[mock-n8n] 2026-09-27T14:20:53.587Z POST /webhook/quote-request -> 202 in 1 ms auth=ok idempotency=new | headers: accept,accept-language,content-type,idempotency-key,user-agent,x-correlation-id,x-n8n-token | body 256 B sha256=5dd53f058f245df063b6a5eb1166b2a2770c77fa933d529784ae94c763604564
[mock-n8n] 2026-09-27T14:20:53.587Z workflow 4093ad01-4fa7-45d1-8e46-57a852277ada running for 5000 ms, then callback event=quote-request.completed
[mock-n8n] 2026-09-27T14:20:58.813Z callback POST http://127.0.0.1:3000/api/n8n/quote-request -> 202 in 223 ms (try 1/3) event=quote-request.completed body 382 B sha256=712bfb28cb144578e4a337e9c749ea3b534172d59657a350b78052e5854e5a1c
[mock-n8n] 2026-09-27T14:21:00.109Z stopping (SIGTERM)
```

## `task-d/branch/scenario/scenario.txt`

```text
# scenario · copy 2026-quitcode-04-agent-skills-hw 9ab228f · build lJIOIyp0ArAwPlUVguy23 · server pid 61419 · 2026-09-27T14:20:53Z
mock: tools/mock-n8n.mjs --mode respond-202 --delay 5000 (from the working repo, --env-file=.env.local of the copy)
.env.local keys (names only): N8N_WEBHOOK_BASE_URL N8N_WEBHOOK_TOKEN N8N_CALLBACK_SECRET APP_BASE_URL 
GET /quotes/new -> 200
form fields posted: $ACTION_REF_1 $ACTION_1:0 $ACTION_1:1 $ACTION_KEY company email description budget
no-JS POST /quotes/new -> HTTP 303 in 0.135481 s (TTFB 0.135281 s)
redirect / status page: /quotes/da55c4b7-2871-4f0f-8a82-739b5e387027
mock log right after the POST:
  | [mock-n8n] 2026-09-27T14:20:53.153Z listening on http://127.0.0.1:5678  mode=respond-202  delay=5000 ms  cloud-timeout=off
  | [mock-n8n] 2026-09-27T14:20:53.154Z production URLs: POST http://127.0.0.1:5678/webhook/<path>
  | [mock-n8n] 2026-09-27T14:20:53.154Z test URLs: not registered (start with --listen to open them for 120 s)
  | [mock-n8n] 2026-09-27T14:20:53.154Z header auth: x-n8n-token required (N8N_WEBHOOK_TOKEN is set)
  | [mock-n8n] 2026-09-27T14:20:53.154Z callbacks: signed, sent to the request's callbackUrl after 5000 ms (async modes)
  | [mock-n8n] 2026-09-27T14:20:53.587Z POST /webhook/quote-request -> 202 in 1 ms auth=ok idempotency=new | headers: accept,accept-language,content-type,idempotency-key,user-agent,x-correlation-id,x-n8n-token | body 256 B sha256=5dd53f058f245df063b6a5eb1166b2a2770c77fa933d529784ae94c763604564
  | [mock-n8n] 2026-09-27T14:20:53.587Z workflow 4093ad01-4fa7-45d1-8e46-57a852277ada running for 5000 ms, then callback event=quote-request.completed
/quotes/<id> before the callback:  LeadDesk ← Studio Nova Кошторис для Scenario Test LLC Запит від 27 вер. 2026 р., 17:20 Готуємо кошторис Зазвичай це займає одну-дві хвилини. Сторінка оновиться сама. 
mock log after the workflow (--mode respond-202 --delay 5000), 6 s after the POST:
  | [mock-n8n] 2026-09-27T14:20:53.153Z listening on http://127.0.0.1:5678  mode=respond-202  delay=5000 ms  cloud-timeout=off
  | [mock-n8n] 2026-09-27T14:20:53.154Z production URLs: POST http://127.0.0.1:5678/webhook/<path>
  | [mock-n8n] 2026-09-27T14:20:53.154Z test URLs: not registered (start with --listen to open them for 120 s)
  | [mock-n8n] 2026-09-27T14:20:53.154Z header auth: x-n8n-token required (N8N_WEBHOOK_TOKEN is set)
  | [mock-n8n] 2026-09-27T14:20:53.154Z callbacks: signed, sent to the request's callbackUrl after 5000 ms (async modes)
  | [mock-n8n] 2026-09-27T14:20:53.587Z POST /webhook/quote-request -> 202 in 1 ms auth=ok idempotency=new | headers: accept,accept-language,content-type,idempotency-key,user-agent,x-correlation-id,x-n8n-token | body 256 B sha256=5dd53f058f245df063b6a5eb1166b2a2770c77fa933d529784ae94c763604564
  | [mock-n8n] 2026-09-27T14:20:53.587Z workflow 4093ad01-4fa7-45d1-8e46-57a852277ada running for 5000 ms, then callback event=quote-request.completed
  | [mock-n8n] 2026-09-27T14:20:58.813Z callback POST http://127.0.0.1:3000/api/n8n/quote-request -> 202 in 223 ms (try 1/3) event=quote-request.completed body 382 B sha256=712bfb28cb144578e4a337e9c749ea3b534172d59657a350b78052e5854e5a1c
/quotes/<id> after the callback:  LeadDesk ← Studio Nova Кошторис для Scenario Test LLC Запит від 27 вер. 2026 р., 17:20 Кошторис готовий Завантажте PDF за посиланням нижче. Завантажити PDF 
callback matrix (send-signed-callback.mjs --url http://127.0.0.1:3000/api/n8n/quote-request, secret via --env-file):
  | send-signed-callback · http://127.0.0.1:3000/api/n8n/quote-request · event quote-request · success cases skipped (no --request-key)
  | ok   unknown event in the path                expected 404, got 404
  | ok   wrong content-type (text/plain)          expected 415, got 415
  | ok   body larger than 64 KB                   expected 413, got 413
  | ok   timestamp 301 s in the past              expected 401, got 401
  | ok   timestamp 301 s in the future            expected 401, got 401
  | ok   wrong signature                          expected 401, got 401
  | ok   body reformatted after signing           expected 401, got 401
  | 7/7 as expected
server log: 26 lines; lines with the submitted email / company / description: 0
server log lines mentioning n8n / quote / callback:
  | db:insertQuote: 1
  | {"n8n":"out","event":"quote-request","correlationId":"5dafdf7f-9311-4783-b1b3-12728e25eed1","attempt":1,"status":202,"ms":12}
  | db:getQuote: 1
  | db:updateQuote: 1
  | db:getQuote: 2
  | db:claimCallbackKey: 1
  | db:getQuoteByRequestKey: 1
  | db:updateQuote: 2
  | {"n8n":"in","event":"quote-request","correlationId":"5dafdf7f-9311-4783-b1b3-12728e25eed1","status":202,"bytes":382,"ms":185}
  | db:getQuote: 3
  | {"n8n":"in","event":"no-such-event-xyz","correlationId":"115bad50-0e74-445d-a8ab-4dc2485a5d67","status":404,"bytes":0,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"66ade1f0-23f1-4847-a94b-85e3e022aeaf","status":415,"bytes":0,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"538b1999-018a-4985-91ab-e4d87f6b906b","status":413,"bytes":0,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"5c4f8194-7da1-47f9-aa92-324445d167b4","status":401,"bytes":382,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"a4405bf9-667e-40cc-9ca3-0c034365585e","status":401,"bytes":382,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"a73dc898-f94b-46fb-91f6-a14eb41dced5","status":401,"bytes":382,"ms":0}
  | {"n8n":"in","event":"quote-request","correlationId":"d4f7f018-2652-4db3-a2e7-78b2b8d3719c","status":401,"bytes":447,"ms":1}
```

## `task-d/branch/scenario/server.log`

```text
▲ Next.js 16.3.5
- Local:         http://localhost:3000
- Network:       http://192.168.0.102:3000
✓ Ready in 57ms
⚠ Warning: Next.js ignored package-lock.json in /Users/hryhorii_haponiuk because it is outside the current Git repository (/Users/hryhorii_haponiuk/Desktop/Work Folder/Agentic Course/2026-quitcode-04-agent-skills-hw).
 To use this directory, set `outputFileTracingRoot` in your Next.js config.

✓ Running next.config.ts took 13ms
⚠ Missing `origin` header from a forwarded Server Actions request.
db:insertQuote: 1
{"n8n":"out","event":"quote-request","correlationId":"5dafdf7f-9311-4783-b1b3-12728e25eed1","attempt":1,"status":202,"ms":12}
db:getQuote: 1
db:updateQuote: 1
db:getQuote: 2
db:claimCallbackKey: 1
db:getQuoteByRequestKey: 1
db:updateQuote: 2
{"n8n":"in","event":"quote-request","correlationId":"5dafdf7f-9311-4783-b1b3-12728e25eed1","status":202,"bytes":382,"ms":185}
db:getQuote: 3
{"n8n":"in","event":"no-such-event-xyz","correlationId":"115bad50-0e74-445d-a8ab-4dc2485a5d67","status":404,"bytes":0,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"66ade1f0-23f1-4847-a94b-85e3e022aeaf","status":415,"bytes":0,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"538b1999-018a-4985-91ab-e4d87f6b906b","status":413,"bytes":0,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"5c4f8194-7da1-47f9-aa92-324445d167b4","status":401,"bytes":382,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"a4405bf9-667e-40cc-9ca3-0c034365585e","status":401,"bytes":382,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"a73dc898-f94b-46fb-91f6-a14eb41dced5","status":401,"bytes":382,"ms":0}
{"n8n":"in","event":"quote-request","correlationId":"d4f7f018-2652-4db3-a2e7-78b2b8d3719c","status":401,"bytes":447,"ms":1}
```
