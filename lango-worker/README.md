# lango-worker

Cloudflare Worker that authenticates iOS Lango requests, resolves an opaque `messageKey` to a Meta WhatsApp template + recipient, and fires the Meta Cloud API call.

The phone never holds template names, recipient phone numbers, or the Meta API token. It only sends `{ "key": "gate_open" }` with a shared-secret header.

## One-time setup

```bash
npm install
npx wrangler login
npx wrangler secret put LANGO_SECRET   # paste a long random string
npx wrangler secret put META_TOKEN     # Meta System User permanent token
```

Then edit `wrangler.toml` to fill in `META_PHONE_NUMBER_ID`, `GUARD_NUMBER`, `ANNA_NUMBER`, `BOB_NUMBER`. Recipient numbers are international format, digits only (e.g. `2547XXXXXXXX`).

## Deploy

```bash
npm run deploy
```

Wrangler prints a `*.workers.dev` URL. That URL goes into the iOS app's Settings → Worker URL.

## Local dev

```bash
npm run dev
```

This runs the Worker locally. If `META_TOKEN` is unset, the Worker returns `{ ok: true, mocked: true, key, template }` so you can validate the iOS path end-to-end before Meta credentials exist.

## Add a new button

1. Add a `ROUTE_<key>` line to `wrangler.toml`, e.g. `ROUTE_running_late = "running_late:ANNA_NUMBER"`.
2. Make sure the Meta template `running_late` is approved.
3. `npm run deploy`.
4. In the iOS app's Settings, configure a slot with `messageKey = running_late`.

No iOS rebuild needed.

## Test with curl

```bash
curl -X POST https://lango-worker.<account>.workers.dev/send \
  -H "Content-Type: application/json" \
  -H "X-Lango-Secret: $LANGO_SECRET" \
  -d '{"key":"gate_open"}'
```

Expected (mocked, before META_TOKEN is set):
```json
{ "ok": true, "mocked": true, "key": "gate_open", "template": "gate_open" }
```

Expected (live):
```json
{ "ok": true, "wa_message_id": "wamid..." }
```

## Error responses

| Status | `error` | Meaning |
|--------|---------|---------|
| 400 | `missing_key` | Body had no `key` field |
| 401 | `unauthorized` | `X-Lango-Secret` header missing or wrong |
| 404 | `not_found` | Wrong path or method |
| 404 | `unknown_key` | No `ROUTE_<key>` env var defined |
| 500 | `missing_recipient` | Route points at a recipient var that has no value |
| 500 | `malformed_route` | A `ROUTE_*` value isn't `template:RECIPIENT_VAR` shape |
| Meta passthrough | (Meta's message) | Meta rejected the call; status code is Meta's |
