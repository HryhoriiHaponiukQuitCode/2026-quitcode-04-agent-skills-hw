# Інтеграції з n8n

Контракт — скіл `.claude/skills/integrating-n8n-webhooks`. Один рядок на подію.

| event | напрям | шлях n8n | режим | власник |
|---|---|---|---|---|
| `quote-request` | Next.js → n8n, колбек n8n → `POST /api/n8n/quote-request` | `/webhook/quote-request` | асинхронно: 202 + підписаний колбек (воркфлоу 40–90 с) | клієнт (воркфлоу), агенція (код) |

## quote-request

- Запуск: Server Action `requestQuote` (`app/quotes/actions.ts`) зберігає запит (`queued`), редіректить на
  `/quotes/<id>` і викликає n8n в `after()`.
- `data`: `quoteId`, `company`, `description`, `budget`. Email клієнта в n8n **не** передаємо — воркфлоу
  листів не надсилає. Якщо знадобиться — додати поле й записати рішення тут.
- Колбек: `quote-request.completed` з `result.documentUrl` (лише `https://`) → `ready`;
  `quote-request.failed` → `failed`.
