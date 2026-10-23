// Unit tests for the delete-account logic with a fake admin.
// Run: deno test supabase/functions/delete-account/
import { deepStrictEqual, strictEqual } from "node:assert";
import {
  type AccountAdmin,
  type CallerClaims,
  handleDeleteAccount,
  lastSignInAt,
  REAUTH_WINDOW_SECONDS,
} from "./handler.ts";

const NOW = 1_800_000_000;
const USER = "11111111-1111-4111-8111-111111111111";

function recentClaims(secondsAgo = 60): CallerClaims {
  return { sub: USER, amr: [{ method: "password", timestamp: NOW - secondsAgo }] };
}

function fakeAdmin(overrides: Partial<AccountAdmin> = {}) {
  const calls: string[] = [];
  const admin: AccountAdmin = {
    noteAttempt: async (id) => {
      calls.push(`noteAttempt:${id}`);
      return true;
    },
    deleteAvatarFiles: async (id) => {
      calls.push(`avatars:${id}`);
    },
    deletePushTokens: async (id) => {
      calls.push(`tokens:${id}`);
    },
    deleteUser: async (id) => {
      calls.push(`user:${id}`);
    },
    ...overrides,
  };
  return { admin, calls };
}

const post = () => new Request("http://localhost/delete-account", { method: "POST" });

Deno.test("wrong method → 405, nothing deleted", async () => {
  const { admin, calls } = fakeAdmin();
  const res = await handleDeleteAccount(
    new Request("http://localhost/delete-account", { method: "GET" }),
    recentClaims(),
    admin,
    NOW,
  );
  strictEqual(res.status, 405);
  deepStrictEqual(await res.json(), { error: "method_not_allowed" });
  deepStrictEqual(calls, []);
});

Deno.test("success deletes avatars, then tokens, then the user", async () => {
  const { admin, calls } = fakeAdmin();
  const res = await handleDeleteAccount(post(), recentClaims(), admin, NOW);
  strictEqual(res.status, 200);
  deepStrictEqual(await res.json(), { status: "deleted" });
  deepStrictEqual(calls, [
    `noteAttempt:${USER}`,
    `avatars:${USER}`,
    `tokens:${USER}`,
    `user:${USER}`,
  ]);
});

Deno.test("a sign-in older than the window needs re-authentication", async () => {
  const { admin, calls } = fakeAdmin();
  const res = await handleDeleteAccount(
    post(),
    recentClaims(REAUTH_WINDOW_SECONDS + 1),
    admin,
    NOW,
  );
  strictEqual(res.status, 403);
  deepStrictEqual(await res.json(), { error: "reauthentication_required" });
  deepStrictEqual(calls, []);
});

Deno.test("a sign-in exactly at the window edge is accepted", async () => {
  const { admin } = fakeAdmin();
  const res = await handleDeleteAccount(post(), recentClaims(REAUTH_WINDOW_SECONDS), admin, NOW);
  strictEqual(res.status, 200);
});

Deno.test("a token without sign-in times needs re-authentication", async () => {
  const { admin, calls } = fakeAdmin();
  for (const amr of [undefined, [], "password", [{ method: "password" }]]) {
    const res = await handleDeleteAccount(post(), { sub: USER, amr }, admin, NOW);
    strictEqual(res.status, 403);
  }
  deepStrictEqual(calls, []);
});

Deno.test("over the limit → 429, nothing deleted", async () => {
  const { admin, calls } = fakeAdmin({
    noteAttempt: async () => false,
  });
  const res = await handleDeleteAccount(post(), recentClaims(), admin, NOW);
  strictEqual(res.status, 429);
  deepStrictEqual(await res.json(), { error: "rate_limited" });
  deepStrictEqual(calls, []);
});

Deno.test("a failure stops before deleting the user and logs no PII", async () => {
  const { admin, calls } = fakeAdmin({
    deleteAvatarFiles: async () => {
      throw new TypeError(`storage failed for ${USER} (a@b.co)`);
    },
  });
  const logged: unknown[][] = [];
  const original = console.error;
  console.error = (...args: unknown[]) => logged.push(args);
  try {
    const res = await handleDeleteAccount(post(), recentClaims(), admin, NOW);
    strictEqual(res.status, 500);
    deepStrictEqual(await res.json(), { error: "deletion_failed" });
  } finally {
    console.error = original;
  }
  deepStrictEqual(calls, [`noteAttempt:${USER}`]);
  const text = JSON.stringify(logged);
  strictEqual(text.includes(USER), false);
  strictEqual(text.includes("a@b.co"), false);
});

Deno.test("lastSignInAt picks the latest method", () => {
  strictEqual(
    lastSignInAt([
      { method: "password", timestamp: 100 },
      { method: "oauth", timestamp: 300 },
      { method: "otp", timestamp: 200 },
    ]),
    300,
  );
  strictEqual(lastSignInAt(null), null);
});
