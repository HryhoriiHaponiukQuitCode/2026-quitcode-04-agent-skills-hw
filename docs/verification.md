# Перевірка (Task A–C)

> Сюди — лише те, що справді сталося. Кожне число має файл-джерело в `docs/evidence/`; сирі
> транскрипти сесій — `docs/evidence/raw-transcripts.tar.gz`. Прогони A/B і фіча — `docs/ab-validation.md`.

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
  (`docs/evidence/task-a/context-after-install.txt`) і з `--setting-sources project --strict-mcp-config`
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
вантажить при відкритті (сирий розмір і gzip). Заміри запускались **після** коміту, SHA в першому рядку
кожного файлу — `docs/evidence/task-a/00-baseline-main.txt` … `07-async-suspense-boundaries.txt`.

| Правило (id) | Коміт | Файли | Що змінилось | Було | Стало | Як міряли |
|---|---|---|---|---|---|---|
| `async-parallel` | `e289c5d` | `app/dashboard/page.tsx` | `getLeads`/`getLeadStats`/`getSourceBreakdown` — `Promise.all` замість трьох `await` підряд | TTFB **2,244 / 2,229 / 2,238 с** | TTFB **1,429 / 1,463 / 1,428 с** | `curl`, 3 прогони, `00-*` → `01-*` |
| `server-cache-react` | `e84f206` | `lib/data.ts` + 4 виклики | `getCurrentUser` обгорнуто в `cache()`; `getWorkspace(slug)` приймає рядок, а не інлайн `{ slug }` (з об'єктом `cache` щоразу промахувався) | `db:getUserBySession` **3**, `db:getWorkspace` **3** на запит | **1** і **1** | лічильники `db:*` за один запит, `01-*` → `02-*` |
| `server-serialization` | `281ff34` | `app/dashboard/page.tsx`, `components/leads-table.tsx` | у `LeadsTable` — `LeadRow` (5 полів), а не весь `Lead` | HTML **424 592 Б**, RSC **315 197 Б**; `rawPayload`, `internalNotes`, `ipAddress` — по **172** входження в HTML | HTML **111 377 Б**, RSC **31 257 Б**; **0** входжень | `curl … \| wc -c`, `grep -o <поле>`, `02-*` → `03-*` |
| `bundle-conditional` | `211f8fe` | `components/leads-toolbar.tsx` | `exceljs` — `await import("exceljs")` усередині обробника кліку | JS на відкритті **1 871 692 Б** (gzip 536 006) | **941 001 Б** (gzip 282 121) | сума скриптів з HTML, `03-*` → `04-*` |
| `bundle-dynamic-imports` | `7a55dd8` | `components/leads-toolbar.tsx` | `SourcesChart` (recharts) — `next/dynamic` з `ssr: false` у Client Component | **941 001 Б**, 10 скриптів | **587 212 Б** (gzip 181 271), 9 скриптів | те саме, `04-*` → `05-*` |
| `server-auth-actions` | `01464c9` | `app/actions.ts` | `updateLeadStatus` / `deleteLead`: сесія, належність ліда до workspace користувача, статус із `LEAD_STATUSES` — **усередині** дії | від імені `u_marta` (інший workspace) `updateLeadStatus(lead_0001)` → **HTTP 200, статус змінився** | **HTTP 500, статус не змінився** | прямий POST з `Next-Action`, `attack-before.txt` → `attack-after.txt` |
| `async-suspense-boundaries` | `3d3cf84` | `app/dashboard/page.tsx` | запит статистики стартує одразу, картки стрімляться за `<Suspense>` зі скелетоном | TTFB **1,423 с** | TTFB **0,628 / 0,631 / 0,623 с**; total 1,415 с | `curl`, 3 прогони, `05-*` → `07-*` |

**Разом по дашборду:** TTFB 2,24 → **0,63 с**, повна сторінка 2,24 → **1,41 с**, HTML 425 → 113 КБ,
JS на відкритті 1,87 МБ → **0,59 МБ** (gzip 536 → 181 КБ), жодного поля `rawPayload`/`internalNotes`/`ipAddress`
у браузері, запити сесії 3 → 1.

- **Чому для «головного» заміру — `async-parallel`.** Скарга клієнта — «дашборд відкривається понад
  2 секунди»; базова лінія це підтвердила (2,24 с), а ефект читається одним числом. Числа зняті для всіх
  виправлень, бо скрипт однаковий.
- **Виправлення без зміни часу — теж результат.** `server-cache-react` не прискорив сторінку (1,429 →
  1,429 с): три виклики з layout, header і page і так ішли паралельно. Він прибирає 4 зайві запити до БД на
  кожне відкриття — це навантаження на базу, а не латентність.
- **Як переконались, що не зламали.** Після кожного виправлення — `npm run lint` і `tsc --noEmit` (0
  помилок), замір на продакшн-збірці. Після всіх — прогін у браузері (`docs/evidence/task-a/smoke-browser.txt`):
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

_(заповнюється після Task B)_

## Task C — `integrating-n8n-webhooks`

_(заповнюється після Task C)_
