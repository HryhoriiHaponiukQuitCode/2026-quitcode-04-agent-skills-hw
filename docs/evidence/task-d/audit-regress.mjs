#!/usr/bin/env node
// Regression checks for three defects found by an audit of the quote feature (Task D):
//   1. budget: "1500,50" became 150050, "1,2,3" became 123 — commas were stripped instead of parsed;
//   2. callback: a signed "quote-request.completed" with data.status "failed" was accepted (202);
//   3. race: a callback that sets "ready" between after()'s status read and its write was overwritten with "sent".
// Needs the app on :3000 started with N8N_WEBHOOK_BASE_URL=http://127.0.0.1:5679/webhook and test values of
// N8N_WEBHOOK_TOKEN / N8N_CALLBACK_SECRET in the environment (audit-regress.sh does that). This script plays
// n8n on :5679. No secret value is printed. Exit 1 on any FAIL.
import { createServer } from "node:http";
import { createHmac, randomUUID } from "node:crypto";

const APP = "http://127.0.0.1:3000";
const { N8N_WEBHOOK_TOKEN: TOKEN, N8N_CALLBACK_SECRET: SECRET } = process.env;
if (!TOKEN || !SECRET) { console.error("N8N_WEBHOOK_TOKEN / N8N_CALLBACK_SECRET are not set"); process.exit(2); }

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let okCount = 0, failCount = 0;
const check = (name, pass, detail = "") => {
  if (pass) okCount++; else failCount++;
  console.log(`${pass ? "ok  " : "FAIL"} ${name}${detail ? ` — ${detail}` : ""}`);
};

// ---- fake n8n -------------------------------------------------------------------------------------------
const received = new Map(); // quoteId -> { budget, requestKey, callbackUrl }
let raceDelayMs = null; // null: just answer 202; a number: call back first, answer 202 after that many ms

function signedCallback(url, requestKey, { event, status, jobId = randomUUID() }) {
  const raw = JSON.stringify({
    version: 1, event,
    data: { jobId, status, requestIdempotencyKey: requestKey,
      ...(status === "completed" ? { result: { documentUrl: "https://example.test/quote.pdf" } } : { error: { code: "test" } }) },
  });
  const ts = String(Math.floor(Date.now() / 1000));
  const sig = `sha256=${createHmac("sha256", SECRET).update(`${ts}.${raw}`).digest("hex")}`;
  return fetch(url, {
    method: "POST", body: raw,
    headers: { "content-type": "application/json", "x-n8n-timestamp": ts, "x-n8n-signature": sig,
      "idempotency-key": `${jobId}:${event}`, "x-correlation-id": "audit-regress" },
  }).then((r) => r.status);
}

const n8n = createServer((req, res) => {
  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", async () => {
    if (req.url !== "/webhook/quote-request" || req.headers["x-n8n-token"] !== TOKEN) { res.writeHead(403).end(); return; }
    const envelope = JSON.parse(raw);
    const entry = { budget: envelope.data.budget, requestKey: req.headers["idempotency-key"], callbackUrl: envelope.callbackUrl };
    received.set(envelope.data.quoteId, entry);
    if (raceDelayMs !== null) {
      entry.callback = signedCallback(entry.callbackUrl, entry.requestKey, { event: "quote-request.completed", status: "completed" });
      await sleep(raceDelayMs);
    }
    res.writeHead(202, { "content-type": "application/json" }).end("{}");
  });
});
await new Promise((r) => n8n.listen(5679, "127.0.0.1", r));

// ---- the form, submitted the way a browser without JavaScript does ------------------------------------
async function submitQuote(budget) {
  const html = await (await fetch(`${APP}/quotes/new`)).text();
  const form = html.slice(html.indexOf("<form"), html.indexOf("</form>"));
  const fd = new FormData();
  for (const m of form.matchAll(/<input\b([^>]*)>/g)) {
    if (/\btype="hidden"/.test(m[1])) {
      const name = /\bname="([^"]+)"/.exec(m[1])?.[1];
      if (name) fd.append(name, (/\bvalue="([^"]*)"/.exec(m[1])?.[1] ?? "").replace(/&quot;/g, '"').replace(/&amp;/g, "&"));
    }
  }
  fd.append("company", "Audit Regress LLC");
  fd.append("email", "audit.regress@example.test");
  fd.append("description", "Landing page and CRM sync for the audit regression check");
  fd.append("budget", budget);
  const r = await fetch(`${APP}/quotes/new`, { method: "POST", body: fd, redirect: "manual" });
  const id = /\/quotes\/([0-9a-f-]{36})/.exec(r.headers.get("location") ?? "")?.[1] ?? null;
  return { status: r.status, id, body: id ? "" : await r.text() };
}
async function waitReceived(id) {
  for (let i = 0; i < 50 && !received.has(id); i++) await sleep(100);
  return received.get(id);
}
const statusTitle = async (id) => {
  const html = await (await fetch(`${APP}/quotes/${id}`)).text();
  return ["Кошторис готовий", "Готуємо кошторис", "Не вдалося підготувати кошторис", "Запит прийнято"].find((t) => html.includes(t)) ?? "?";
};

// ---- 1. budget ------------------------------------------------------------------------------------------
console.log("# 1. budget parsing (value that reached n8n, or a form error)");
const BUDGETS = [
  ["1500", 1500], ["1 500", 1500], ["1500,50", 1500.5], ["1500.50", 1500.5], ["1 500,5", 1500.5], ["", null],
  ["1,2,3", "error"], ["1,500", "error"], ["1e3", "error"], ["0x10", "error"], ["-5", "error"], ["12345678901234", "error"],
];
for (const [input, want] of BUDGETS) {
  const r = await submitQuote(input);
  if (want === "error") {
    const got = r.id ? `accepted, n8n got ${JSON.stringify((await waitReceived(r.id))?.budget)}` : "form error";
    check(`budget ${JSON.stringify(input)} -> form error`, !r.id && r.body.includes("Вкажіть бюджет"), got);
  } else {
    const got = r.id ? (await waitReceived(r.id))?.budget : undefined;
    check(`budget ${JSON.stringify(input)} -> ${JSON.stringify(want)}`, got === want, r.id ? `n8n got ${JSON.stringify(got)}` : "form error");
  }
}

// ---- 2. event and data.status must agree ------------------------------------------------------------------
console.log("# 2. signed callback: event suffix must match data.status");
for (const [event, status, want] of [
  ["quote-request.completed", "failed", 400], ["quote-request.failed", "completed", 400], ["quote-request.completed", "completed", 202],
]) {
  const r = await submitQuote("1000");
  const got = await waitReceived(r.id);
  await sleep(300); // let after() finish its own status write first
  const code = await signedCallback(got.callbackUrl, got.requestKey, { event, status });
  check(`${event} + status "${status}" -> ${want}`, code === want, `got ${code}, page: ${await statusTitle(r.id)}`);
}

// ---- 3. a callback between after()'s read and write must win ----------------------------------------------
console.log("# 3. race: n8n calls back before answering 202, after 0..400 ms");
const raced = [];
for (let d = 0; d <= 400; d += 20) {
  raceDelayMs = d;
  const r = await submitQuote("1000");
  const got = await waitReceived(r.id);
  raced.push({ d, id: r.id, callback: got.callback });
}
raceDelayMs = null;
await sleep(1500);
const lost = [];
for (const q of raced) {
  const code = await q.callback, title = await statusTitle(q.id);
  if (code !== 202 || title !== "Кошторис готовий") lost.push(`${q.d} ms: callback ${code}, page "${title}"`);
}
check(`${raced.length} quotes with a completed callback all end "Кошторис готовий"`, lost.length === 0, lost.join("; "));

n8n.close();
console.log(`result: ${okCount} ok, ${failCount} FAIL`);
process.exit(failCount ? 1 : 0);
