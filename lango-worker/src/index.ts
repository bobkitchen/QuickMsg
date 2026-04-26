/**
 * Lango Worker — authenticates incoming requests with a shared secret,
 * resolves an opaque messageKey to a Meta WhatsApp template + recipient,
 * and fires the Meta Cloud API call.
 *
 * The phone never sees template names, recipient phone numbers, or the
 * Meta token. It only sends a messageKey string.
 */

export interface Env {
  LANGO_SECRET: string;
  META_TOKEN: string;
  META_PHONE_NUMBER_ID: string;
  // ROUTE_<key> = "<template_name>:<RECIPIENT_VAR>"
  // <NAME>_NUMBER = phone number in international format, no + or spaces
  [key: string]: string;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (req.method !== "POST" || url.pathname !== "/send") {
      return json({ ok: false, error: "not_found" }, 404);
    }

    if (req.headers.get("X-Lango-Secret") !== env.LANGO_SECRET) {
      return json({ ok: false, error: "unauthorized" }, 401);
    }

    const { key } = await req
      .json<{ key?: string }>()
      .catch(() => ({ key: undefined }));

    if (!key || typeof key !== "string") {
      return json({ ok: false, error: "missing_key" }, 400);
    }

    const route = env[`ROUTE_${key}`];
    if (!route) {
      return json({ ok: false, error: "unknown_key" }, 404);
    }

    const [template, recipientVar] = route.split(":");
    if (!template || !recipientVar) {
      return json({ ok: false, error: "malformed_route" }, 500);
    }

    const to = env[recipientVar];
    if (!to) {
      return json({ ok: false, error: "missing_recipient" }, 500);
    }

    // Mocked path for local testing before Meta credentials are wired.
    if (!env.META_TOKEN || !env.META_PHONE_NUMBER_ID) {
      console.log("mocked_send", { key, template, to });
      return json({ ok: true, mocked: true, key, template });
    }

    const metaUrl = `https://graph.facebook.com/v19.0/${env.META_PHONE_NUMBER_ID}/messages`;
    const metaResp = await fetch(metaUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.META_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "template",
        template: { name: template, language: { code: "en" } },
      }),
    });

    const metaBody = await metaResp.json<MetaResponse>().catch(() => ({} as MetaResponse));

    if (!metaResp.ok) {
      console.error("meta_error", metaResp.status, metaBody);
      return json(
        {
          ok: false,
          error: metaBody?.error?.message ?? "meta_failed",
          status: metaResp.status,
        },
        metaResp.status,
      );
    }

    const wamid = metaBody?.messages?.[0]?.id;
    return json({ ok: true, wa_message_id: wamid });
  },
};

type MetaResponse = {
  messages?: Array<{ id?: string }>;
  error?: { message?: string };
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
