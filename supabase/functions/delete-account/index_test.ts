// The real entry point rejects a caller without a valid user JWT before
// any handler code runs. No network: the JWKS is given inline.
// Run: deno test --allow-env supabase/functions/delete-account/
import { strictEqual } from "node:assert";

Deno.env.set("SUPABASE_URL", "http://127.0.0.1:54321");
Deno.env.set("SUPABASE_JWKS", JSON.stringify({ keys: [] }));
Deno.env.set("SUPABASE_PUBLISHABLE_KEYS", JSON.stringify({ default: "sb_publishable_test" }));
Deno.env.set("SUPABASE_SECRET_KEYS", JSON.stringify({ default: "sb_secret_test" }));

const { default: entry } = await import("./index.ts");

Deno.test("no Authorization header → 401", async () => {
  const res = await entry.fetch(
    new Request("http://localhost/delete-account", { method: "POST" }),
  );
  strictEqual(res.status, 401);
  await res.body?.cancel();
});

Deno.test("a forged token → 401", async () => {
  const header = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = btoa(JSON.stringify({ sub: "11111111-1111-4111-8111-111111111111", role: "authenticated" }));
  const res = await entry.fetch(
    new Request("http://localhost/delete-account", {
      method: "POST",
      headers: { Authorization: `Bearer ${header}.${payload}.forged` },
    }),
  );
  strictEqual(res.status, 401);
  await res.body?.cancel();
});
