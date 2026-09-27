# Перевірка (Task A–C)

> Сюди — лише те, що справді сталося. Кожне число має файл-джерело в `docs/evidence/`; сирі
> транскрипти сесій — `docs/evidence/raw-evidence.tar.gz` (оригінали всіх файлів, зібраних у `summary.md`). Прогони A/B і фіча — `docs/ab-validation.md`.

- **Інструмент і версія, модель:** Claude Code 2.1.282 · `claude-opus-5-5` (`--model opus`), effort `high`
  — з поля `model` в `init` кожного транскрипту
- **ОС і термінал, Node:** macOS (Darwin 25.6) · zsh · Node 22.21.0 · npm 10.9.4

**Як запускались перевірочні сесії.** Кожна — нова headless-сесія
`docs/evidence/bin/run-readonly-session.sh`: `claude -p` з запитом із файлу (SHA256 у `meta.txt`),
`--setting-sources project --strict-mcp-config` (без особистих скілів, хуків і MCP),
`--allowedTools Skill,Read,Grep,Glob --disallowedTools Edit,Write,NotebookEdit,Bash`. Факти про те,
що агент бачив, викликав і читав, витягує з транскрипту `docs/evidence/bin/session-report.mjs`,
а не пам'ять.

> **Чому лише для читання.** Спочатку я збирав скрипт на `--permission-mode bypassPermissions`, але
> класифікатор auto mode його заблокував («Create Unsafe Agents»). Обходити блокування не став і
> перейшов на сесії лише для читання з забороненими `Edit`/`Write`/`Bash`. Для рев'ю (Task A) і
> тесту спрацювання (Task B, E2) цього достатньо: ознака спрацювання — виклик `Skill`, а не зміни у файлах.

## Скіли видно у свіжій сесії

- Як перевіряли: `claude -p "/context"` з кореня репозиторію, двічі: зі звичайними налаштуваннями
  (`docs/evidence/task-a/summary.md`) і з `--setting-sources project --strict-mcp-config`
  (`…/context-project-only.txt`).

| Skill | Звідки | Примітка |
|---|---|---|
| `vercel-react-best-practices` | Project | видно в обох режимах, ~120 токенів опису |
| `building-client-form` | Project | див. Task B |
| `integrating-n8n-webhooks` | Project | див. Task C |

- **Особисті скіли, які теж видно.** У звичайній сесії поруч із проєктними — **14 скілів `User`** з
  `~/.claude/skills/` (`design`, `security-and-hardening`, `interface-design`…), 9 `claude.ai sync` і
  плагін `drawio`. Вони можуть вплинути: `security-and-hardening` чи `interface-design` спрацювали б на
  той самий запит про форму, що й `building-client-form`. Тому **всі перевірочні сесії й прогони A/B —
  з `--setting-sources project`**: у цьому режимі `/context` показує лише `Project` і `Built-in`,
  жодного `User`. Глобальний `~/.claude/CLAUDE.md` (RTK, semble) вантажиться завжди, в усіх сесіях однаково.

## Task A — виправлення за скілом Vercel

**Рев'ю за скілом.** Свіжа сесія, запит із walkthrough дослівно (`docs/evidence/task-a/vercel-review/`).
Агент викликав `Skill` → `vercel-react-best-practices`, прочитав 28 шляхів: 24 файли з `app/`, `components/`, `lib/`, а також `next.config.ts`,
`rules/server-cache-react.md`, `node_modules/next/dist/server/config.js` і `Glob` по `node_modules/next/dist/docs`, за межі репозиторію не
виходив, файлів не змінював, $0,81. Результат — таблиця з 16 знахідок з id правил (`transcript.md`, «Final answer»).

**Як міряли.** `docs/evidence/task-a/measure-dashboard.sh <мітка>` — один і той самий скрипт для кожного
заміру: `npm run build` → `next start -p 3000` → прогрів → 3 × `curl` з cookie
`leaddesk_session=demo-u_olena` (TTFB і total) → лічильники `db:<запит>` з журналу сервера за **один**
запит сторінки → розмір HTML і RSC → входження полів ліда в HTML → сума JS-скриптів, які HTML сторінки
вантажить при відкритті (сирий розмір і gzip). Файли `docs/evidence/task-a/summary.md` …
`07-async-suspense-boundaries.txt`; у першому рядку кожного — SHA, `BUILD_ID` збірки й PID сервера.

> **Заміри знято двічі — і ось чому.** Перша серія йшла в робочому дереві: скрипт стартував
> `npx next start` і зупиняв його `kill` обгортки `npx`. Пізніше (Task B) з'ясувалось, що `next start`
> перейменовує процес на `next-server`, і сервер може пережити зупинку: наступний скрипт тоді впаде на
> зайнятому порту й виміряє **старий** сервер — саме так зіпсувався перший verify Task B. Тому вся серія
> Task A перезнята в окремому worktree поза репозиторієм (`git checkout` кожного SHA по черзі) скриптом,
> який перед стартом падає, якщо порт 3000 зайнятий, і перевіряє, що порт слухає саме його процес
> (`docs/evidence/bin/server.sh`). У таблиці — друга серія. Розбіжність із першою: усі розміри,
> лічильники й кількість скриптів **ідентичні**, час — у межах 15 мс (напр. базова лінія 2,244 → 2,219 с).
> Висновок про `lodash` (нижче) підтверджено на сервері з перевіреним власником.

| Правило (id) | Коміт | Файли | Що змінилось | Було | Стало | Як міряли |
|---|---|---|---|---|---|---|
| `async-parallel` | `e289c5d` | `app/dashboard/page.tsx` | `getLeads`/`getLeadStats`/`getSourceBreakdown` — `Promise.all` замість трьох `await` підряд | TTFB **2,219 / 2,220 / 2,217 с** | TTFB **1,416 / 1,419 / 1,413 с** | `curl`, 3 прогони, `00-*` → `01-*` |
| `server-cache-react` | `e84f206` | `lib/data.ts` + 4 виклики | `getCurrentUser` обгорнуто в `cache()`; `getWorkspace(slug)` приймає рядок, а не інлайн `{ slug }` (з об'єктом `cache` щоразу промахувався) | `db:getUserBySession` **3**, `db:getWorkspace` **3** на запит | **1** і **1** | лічильники `db:*` за один запит, `01-*` → `02-*` |
| `server-serialization` | `281ff34` | `app/dashboard/page.tsx`, `components/leads-table.tsx` | у `LeadsTable` — `LeadRow` (5 полів), а не весь `Lead` | HTML **424 592 Б**, RSC **315 197 Б**; `rawPayload`, `internalNotes`, `ipAddress` — по **172** входження в HTML | HTML **111 377 Б**, RSC **31 257 Б**; **0** входжень | `curl … \| wc -c`, `grep -o <поле>`, `02-*` → `03-*` |
| `bundle-conditional` | `211f8fe` | `components/leads-toolbar.tsx` | `exceljs` — `await import("exceljs")` усередині обробника кліку | JS на відкритті **1 871 692 Б** (gzip 536 006) | **941 001 Б** (gzip 282 121) | сума скриптів з HTML, `03-*` → `04-*` |
| `bundle-dynamic-imports` | `7a55dd8` | `components/leads-toolbar.tsx` | `SourcesChart` (recharts) — `next/dynamic` з `ssr: false` у Client Component | **941 001 Б**, 10 скриптів | **587 212 Б** (gzip 181 271), 9 скриптів | те саме, `04-*` → `05-*` |
| `server-auth-actions` | `01464c9` | `app/actions.ts` | `updateLeadStatus` / `deleteLead`: сесія, належність ліда до workspace користувача, статус із `LEAD_STATUSES` — **усередині** дії | від імені `u_marta` (інший workspace) `updateLeadStatus(lead_0001)` → **HTTP 200, статус змінився** | **HTTP 500, статус не змінився** | прямий POST з `Next-Action`, `attack-before.txt` → `attack-after.txt` |
| `async-suspense-boundaries` | `3d3cf84` | `app/dashboard/page.tsx` | запит статистики стартує одразу, картки стрімляться за `<Suspense>` зі скелетоном | TTFB **1,412 с** | TTFB **0,612 / 0,613 / 0,610 с**; total 1,407 с | `curl`, 3 прогони, `05-*` → `07-*` |

**Разом по дашборду:** TTFB 2,22 → **0,61 с**, повна сторінка 2,22 → **1,41 с**, HTML 425 → 113 КБ,
JS на відкритті 1,87 МБ → **0,59 МБ** (gzip 536 → 181 КБ), жодного поля `rawPayload`/`internalNotes`/`ipAddress`
у браузері, запити сесії 3 → 1.

- **Чому для «головного» заміру — `async-parallel`.** Скарга клієнта — «дашборд відкривається понад
  2 секунди»; базова лінія це підтвердила (2,22 с), а ефект читається одним числом. Числа зняті для всіх
  виправлень, бо скрипт однаковий.
- **Виправлення без зміни часу — теж результат.** `server-cache-react` не прискорив сторінку (1,416 →
  1,416 с): три виклики з layout, header і page і так ішли паралельно. Він прибирає 4 зайві запити до БД на
  кожне відкриття — це навантаження на базу, а не латентність.
- **Як переконались, що не зламали.** Після кожного виправлення — `npm run lint` і `tsc --noEmit` (0
  помилок), замір на продакшн-збірці. Після всіх — прогін у браузері (`docs/evidence/task-a/summary.md`):
  5 карток і 172 рядки на місці; графік довантажує окремий чанк лише після кліку (скриптів 9 → 10) і
  малює 6 стовпців; експорт довантажує чанк `exceljs` лише після кліку (10 → 11) і створює
  `leads-2026-09-27.xlsx` на 18 704 Б; помилок у консолі немає.
- **Атака на `server-auth-actions`: що саме було діркою.** Без сесії старий код теж не змінив лід, але не
  завдяки дії: `/dashboard/*` прикриває `proxy.ts` (307 на `/login`), а POST на публічні `/` і `/login`
  отримує кешований `{}` — у маніфесті дія зареєстрована лише для `app/dashboard/leads/[id]/page`.
  Справжня дірка — **авторизація**: будь-який залогінений користувач міняв ліди чужого workspace. Саме це
  і закрито.

**Порада скіла, яку звірили з Next.js 16 і не застосували або змінили:**

| Порада | Що зробили | Чому |
|---|---|---|
| `bundle-barrel-imports` для `lodash` | застосував (`035118b`), **відкотив** (`e8c2cb5`) | JS до і після — **587 212 Б байт у байт** (`05-*` / `06-*`). Next.js 16 уже переписує `import { debounce } from "lodash"` на `lodash/debounce` вбудованим `modularizeImports` (`node_modules/next/dist/server/config.js:1117`). Помилились і рев'ю-агент (знахідка 8), і перша редакція `docs/skill-review.md` — обидва дивились лише на `optimizePackageImports`. Виправлено в рев'ю, п. 5 |
| `bundle-dynamic-imports` з `ssr: false` | застосував **лише** в Client Component (`leads-toolbar.tsx` має `"use client"`) | `lazy-loading.md:94`: у Server Component `ssr: false` — помилка збірки |
| `server-after-nonblocking` для `submitLead` (знахідка 6) | **відкладено до Task D** | це виклик n8n; walkthrough вимагає привести його до контракту разом із фічею, а не до BASE — інакше прогін A отримає частину контракту задарма |
| `client-swr-dedup`, `rerender-*`, `js-*` (знахідки 11–16) | не застосовано | дрібні або без вимірного ефекту на наших ~170 рядках; `client-swr-dedup` — нова залежність (`swr`), а `AGENTS.md` вимагає «так» на кожен пакет |

- `npm run lint`, `npm run build` після виправлень: 0 проблем ESLint, збірка успішна (кожен замір починається з `npm run build`).

## Task B — `building-client-form`

- Запит у свіжій сесії (скіл не названо; дослівно з walkthrough, SHA256 `1fb304ac…` однаковий в обох спробах):
  > На сторінці ліда в дашборді (/dashboard/leads/[id]) додай форму «Додати нотатку»: одне текстове поле
  > до 500 символів; нотатка дописується до внутрішніх нотаток ліда.
- Сесія: `docs/evidence/bin/run-scoped-session.sh` — `acceptEdits`, allowlist `Skill, Read, Grep, Glob,
  Edit, Write, Bash(npm run lint|build), Bash(npx tsc --noEmit), Bash(git status*|diff*)`,
  `--permission-prompts none`, мережеві інструменти заборонені, `--setting-sources project`.

| Спроба | Скіл | Чи спрацював і як видно | Що зробив агент | Verify |
|---|---|---|---|---|
| **run-1** (`d4a9ca7`, скіл 0.1.0) | у сесії: `building-client-form`, `vercel-react-best-practices` + вбудовані | **так, першим же кроком**: у транскрипті інструмент `Skill` → `building-client-form` (крок 1 із 25), ще до читання коду | `lib/lead-note-form.ts` (розбір, 500 символів, відмова замість обрізання), `components/lead-note-form.tsx` (`useActionState`, `aria-*`, `role="alert"`, `values` → `defaultValue`), дія `addLeadNote` (сесія → `authorizeLead` з Task A → валідація → запис → `after(logAudit)` → `{ status }`), `db.appendLeadNote` | **не пройшов** пункт «без JS»: форма зависала. Причина — у скілі (див. нижче) |
| **run-2** (`9297071`, скіл 0.1.1) | те саме | **так**: `Skill` → `building-client-form` першим кроком (1 із 27) | те саме, але id ліда — приховане поле, а не `.bind`; плюс нормалізація `\r\n` (браузерний `maxLength` рахує перенос за 1 символ, а надсилає 2) | **усі пункти пройшли** (нижче) |

**Що знайшла перша спроба — і що змінено в скілі.** Агент виконав скіл дослівно:
`useActionState(addLeadNote.bind(null, leadId))`, бо версія 0.1.0 радила «додаткові аргументи —
`action.bind(null, id)`». Відправка такої форми **без JavaScript** на сторінці ліда зависає: дія
виконується (`db:appendLeadNote` є в журналі сервера), але відповідь не починається навіть за 40 с. Так
само поводився справжній браузер: нативний `HTMLFormElement.submit()` серверної форми повис на навігації.
Ізоляція в окремому worktree (`docs/evidence/task-b/summary.md`):

| Варіант | Результат без JS |
|---|---|
| код run-1 (`useActionState(action.bind(null, leadId))`) | HTTP 000, 10 с без заголовків |
| той самий, дія повертає `invalid` першим рядком | HTTP 000, 10 с — тобто справа не в тілі дії |
| незв'язана дія + `<input type="hidden" name="leadId">` | **HTTP 200 за 0,52 с** |
| контроль: наявна форма заявки на `/`, та сама емуляція | HTTP 200 за 0,04 с, з помилками полів |

Документація Next.js 16 каже протилежне (`02-guides/forms.md:127`: «`bind` … supports progressive
enhancement»). У зв'язці з `useActionState` на цьому динамічному маршруті це не так. Скіл виправлено
(`9297071`, v0.1.1): id запису — приховане поле з авторизацією в дії; `bind` з `useActionState` не
використовувати. Захисту `bind` однаково не дає: агент сам написав у run-1, що «the id is still
client-controlled, so check it here». Діф обох спроб — `run-1/agent.diff`, `run-2/agent.diff`.

**Пункти Verify зі скіла — run-2** (`docs/evidence/task-b/summary.md`, скрипт `verify-note-form.sh`;
«без JS» — це серверна `<form>` з її прихованими полями `$ACTION_*` і `leadId`, надіслана як multipart без
заголовка `Next-Action`, тобто так, як її надсилає браузер без JavaScript):

| Пункт Verify | Результат |
|---|---|
| `npm run lint`, `npm run build` | 0 проблем; збірка успішна (verify-скрипт починається з `npm run build`) |
| порожня відправка | HTTP 200; `aria-invalid="true"`, `role="alert"`, «Напишіть текст нотатки» — у відповіді |
| 501 символ | помилка «Не більше 500 символів»; **введений текст лишився** в `<textarea>`; нічого не збережено |
| відправка без JS, власник | HTTP 200, нотатка на сторінці |
| дія від імені користувача іншого workspace (`u_marta`) | HTTP 404, нотатки немає |
| дія без сесії | HTTP 307 на `/login`, нотатки немає |
| журнал сервера | 0 рядків з текстом нотатки, `@` чи `+380` (з 57 рядків — лише лічильники `db:*`) |
| з JavaScript, у браузері (`run-2/verify-browser.txt`) | порожня: `aria-invalid`, `aria-describedby="lead-note-error"`, підсумок `role="alert"`; валідна: нотатка на сторінці, `role="status"` «Нотатку додано.» |

**Код з перевірки в гілці не лишив** — свідомо, хоча run-2 пройшов Verify. У ньому є
`after(() => logAudit(…))` у Server Action, тобто робочий приклад правила `server-after-nonblocking`.
Потрапивши в BASE для Task D, він дав би агенту в прогоні A частину контракту n8n безкоштовно (walkthrough,
Task D, крок 1: «BASE узято запізно»). Обидва діфи збережено як доказ.

> **Перший verify був недійсним — і це моя помилка, а не агента.** Скрипт стартував `next start`, але порт
> 3000 тримав мій старий `next-server` зі збірки ще без форми нотатки: `pkill -f "next start"` його не
> вбив, бо процес перейменовується. Скрипт не помітив, що його сервер не піднявся, і отримав 500 від
> старого. Файл лишено як є з позначкою: `run-1/verify-invalid-stale-server.txt`. Після цього всі
> скрипти стартують сервер через `docs/evidence/bin/server.sh`: він падає, якщо порт зайнятий, і
> перевіряє PID власника. Через це й перезнята вся серія Task A.

**Що ще видно з транскриптів про межі сесії.** `Bash` поза allowlist усе ж виконувався, якщо команда лише
читає: пройшли `git ls-files … | head`, `grep …`, `sed -n 1,80p …`, `find app/dashboard`,
`ls node_modules/next/dist/docs/`, `git diff | grep …`. Відхилено («no approval surface») кожну зв'язку,
де була хоч одна команда, що запускає чи слухає: `…; python3 -c "…"` (run-1), `…; lsof -iTCP:3457`,
`npm --prefix … run start -- -p 3457` і `… && ls app/dashboard -R` (run-2). Тобто allowlist звужує запуск і
запис, але не читання. У run-2 агент, крім скіла, сам прочитав `node_modules/next/dist/docs/…/after.md` і
`02-guides/forms.md`, як вимагає блок Next.js в `AGENTS.md`.

## Task C — `integrating-n8n-webhooks`

**BASE для Task D: `898aa2b`** (`skills: add integrating-n8n-webhooks (contract, references, scripts)`).
У ньому є виправлення Task A й усі три скіли, але ще немає ні `/quotes`, ні переробленого виклику n8n:
`app/actions.ts:55` досі робить `await fetch(process.env.N8N_WEBHOOK_URL!, …)` без заголовків і таймауту.
Від `main` у `app/actions.ts` змінено лише `authorizeLead` з Task A (`git diff --stat main 898aa2b -- app/actions.ts`
→ 15+/1−). Тож прогін A не отримує від BASE жодного шматка контракту.

### Що залишилось у `SKILL.md`, а що пішло в `references/`

Записка має 398 рядків і 12 розділів. `SKILL.md` має 108 рядків: він вантажиться в контекст щоразу, коли скіл
спрацьовує, тому в ньому лише те, що потрібне в кожній задачі:

| У `SKILL.md` | Чому тут |
|---|---|
| `description` (981 символ): що робить скіл, «Use when», фрази команди («надішли лід у n8n», «n8n викличе ендпоінт, коли буде готово», «n8n повертає 403 / 524»), «Не для» | За ним агент вирішує, чи вантажити скіл. Тіло до цього моменту не прочитане |
| Контракт однією таблицею: змінні, хто говорить з n8n, запит, повтори, режим, колбек по кроках, журнали, runtime | Потрібен у кожній задачі. Без нього агент пише «як звик» |
| «Як робимо» з прямими посиланнями на кожен reference | Одне посилання на кожен файл, без ланцюжків |
| Чекліст із 8 пунктів, правила зупинки, Verify з командами | Ці речі не можна пропустити |
| Посилання на `server-auth-actions` і `server-after-nonblocking` за id | Правила Vercel не переписані |

| У `references/` | Що там |
|---|---|
| `contract.md` (143 р.) | Деталі й «чому»: змінні, запит, повтори, колбек по кроках із кодами, ідемпотентність, журнали, ліміти |
| `response-modes.md` (61 р.) | Режими Webhook, 100 с / 524, що означає кожен код відповіді, тестовий vs production URL, мок |
| `code-templates.md` (249 р.) | `lib/n8n/client.ts`, сховище, Server Action з `after()` + `redirect()`, колбек-роут `app/api/n8n/[event]/route.ts` |
| `n8n-setup.md` (27 р.) | Налаштування воркфлоу на боці n8n текстом для клієнта |

Між файлами `references/` посилань немає (перевірено grep: 0). Розділи записки 11 («Відомі пастки») і 12
(«Поза межами») не скопійовані окремо. Вони стали правилами зупинки, пунктами чекліста й рядком «Не для» в
`description`.

**Правила зупинки** (без винятків «якщо задача потребує»):
- тестовий URL `/webhook-test/` у коді чи `.env.example`;
- секрет у Client Component, `NEXT_PUBLIC_`, query string, журналі чи відповіді;
- форма має чекати воркфлоу, довшого за ~10 с;
- колбек без підпису чи з іншою схемою підпису;
- зміна сенсу поля конверта;
- потрібні справжні значення змінних, нова npm-залежність або зміна воркфлоу клієнта;
- 403/404 на production-URL.

### `scripts/`

| Скрипт | Що робить |
|---|---|
| `check-contract.mjs` | Node без залежностей, 15 перевірок C1–C15: PASS/FAIL/N/A, для FAIL — `файл:рядок`, exit 1 при FAIL, 2 при помилці аргументів. Підтримує `--root`, `--changed-since <ref>` (змінені рядки + нові неіндексовані файли) і `--help`. Код перевіряється без коментарів; C1/C2 дивляться і в коментарі теж |
| `selftest-check-contract.mjs` | Доводить, що перевірки справжні (нижче) |
| `send-signed-callback.mjs` | Матриця колбеків проти запущеного роуту, секрет з `--env-file`, не друкує його. Поки перевірено лише `--help` і вихід без секрету (exit 2): роуту ще немає, прогін буде в Task D |
| `mock-n8n.mjs` | Копія `tools/mock-n8n.mjs` байт у байт |

### Вивід на `main`

Повний вивід: [`docs/evidence/task-c/check-contract-main.txt`](evidence/task-c/check-contract-main.txt).

```
$ mkdir ../leaddesk-main && git archive main | tar -x -C ../leaddesk-main
$ node .claude/skills/integrating-n8n-webhooks/scripts/check-contract.mjs --root ../leaddesk-main; echo "exit=$?"
C1   FAIL no test webhook URL (/webhook-test/) in code or .env.example
       .env.example:6  test webhook URL
C3   FAIL requests to n8n only from lib/n8n/client.ts
       app/actions.ts:54  fetch to n8n outside lib/n8n/client.ts
C4   FAIL … app/actions.ts:1  first statement is not import "server-only"
C5   FAIL … app/actions.ts:54  fetch without AbortSignal.timeout
C6   FAIL … app/actions.ts:54  missing header(s): x-n8n-token, idempotency-key, x-correlation-id
C7   FAIL … app/actions.ts:54  body is not the { version: 1, event, data } envelope
C8   FAIL … app/actions.ts:54  Server Action waits for n8n: no after()
C9–C12 N/A (колбек-роуту на main немає)
C15  FAIL … N8N_WEBHOOK_BASE_URL / N8N_WEBHOOK_TOKEN / N8N_CALLBACK_SECRET / APP_BASE_URL is missing
Summary: 3 PASS, 8 FAIL, 4 N/A
exit=1
```

На поточній гілці результат такий самий: 3 PASS, 8 FAIL, 4 N/A. Task A виклику n8n не торкався.

### Перевірки, яким на `main` нема що дивитись: навмисно поганий роут

Тимчасова тека з одним роутом: `JSON.parse` до перевірки підпису, порівняння `===`, без часу, без ключа,
`console.log` тіла. Теку після перевірки видалено. Результат —
[`bad-callback.txt`](evidence/task-c/bad-callback.txt):

```
C9   FAIL  app/api/n8n/[event]/route.ts:5  JSON.parse before the signature check
C10  FAIL  …:1 no timingSafeEqual · …:7 signature compared with === / !==
C11  FAIL  …:1 x-n8n-timestamp is not read
C12  FAIL  …:1 idempotency-key is not read
C14  FAIL  …:10 log call may print a body, personal data or a secret
Summary: 3 PASS, 5 FAIL, 7 N/A · exit=1
```

### Selftest: атака на власний скрипт

`selftest-check-contract.mjs` бере блоки `ts` прямо з `references/code-templates.md` і складає з них
проєкт: 15 з 15 PASS, exit 0. Отже шаблони, які скіл дає агенту, самі проходять перевірку. Далі йдуть 15
фікстур, кожна з яких ламає рівно одну перевірку, і кожна її ловить: FAIL, exit 1. Ще 3 кейси перевіряють
`--changed-since`. Вивід: [`selftest.txt`](evidence/task-c/selftest.txt), «all expectations met», exit 0.
Супутні FAIL (у C3 — ще C4/C6/C7, у C10 — ще C9) очікувані: прямий `fetch` поза клієнтом справді порушує
й ці пункти.

Selftest знайшов у `check-contract.mjs` три баги, які я виправив до коміту:
1. Коментар `// fetch to n8n` рахувався як код. Тепер код перевіряється без коментарів, а C1/C2 дивляться
   в сирий текст: тестовий URL у коментарі — теж витік.
2. `--changed-since` порівнював шляхи `/var/…` і `/private/var/…` (macOS) і не знаходив жодного зміненого
   файлу. Тепер обидва шляхи проходять через `realpath`.
3. Очікування в самому selftest шукало `app/legacy.ts` в усьому виводі, і його знаходив рядок заголовка.
   Тепер пошук іде лише по рядках знахідок `файл:рядок`.

### На фінальному коді

Після перенесення прогону B і двох комітів доведення (`b6d5a23`, `9ab228f`) вивід такий:
[`task-d/branch/check-contract-final.txt`](evidence/task-d/branch/summary.md).

```
n8n callers: app/actions.ts, lib/n8n/client.ts · callback routes: app/api/n8n/[event]/route.ts
Summary: 15 PASS, 0 FAIL, 0 N/A
exit=0
```

Там само видно дві неточності самого скрипта, знайдені на коді прогонів (подробиці в `docs/ab-validation.md`):
- C10 шукає `timingSafeEqual` лише у файлі роуту, а в прогонах A він лежить у `lib/`. Вердикт FAIL від цього
  не змінюється: HMAC там немає;
- C14 спрацьовує на `error.name`.

Обидві виправлено у v0.1.1 скіла. Selftest з двома новими кейсами — «all expectations met», exit 0
([`task-c/selftest.txt`](evidence/task-c/selftest.txt)). На `main` вивід той самий: 3 PASS, 8 FAIL, 4 N/A.
