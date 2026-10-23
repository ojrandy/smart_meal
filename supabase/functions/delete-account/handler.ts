// delete-account — the request logic, free of Supabase clients so it can be
// unit-tested with fakes (handler_test.ts). index.ts wires in the real ones.
//
// Order matters (P14): storage objects do not cascade, so they go first;
// push tokens next; the auth user last, whose deletion cascades through
// `profiles` to every user row (supabase/tests/04_account_lifecycle).

/** How recent the caller's sign-in must be (owner, 2026-10-23). */
export const REAUTH_WINDOW_SECONDS = 10 * 60;

/** The verified JWT claims the handler needs. */
export interface CallerClaims {
  sub: string;
  /** Authentication methods with their Unix timestamps (Supabase `amr`). */
  amr?: unknown;
}

/** Privileged operations, all scoped to one user ID. */
export interface AccountAdmin {
  /** Counts an attempt; false when the caller is over the limit. */
  noteAttempt(userId: string): Promise<boolean>;
  deleteAvatarFiles(userId: string): Promise<void>;
  deletePushTokens(userId: string): Promise<void>;
  /** Deletes the auth user. Resolves when the user is already gone. */
  deleteUser(userId: string): Promise<void>;
}

/** Response bodies. `error` values are stable codes the app maps to copy. */
export type DeleteAccountBody =
  | { status: "deleted" }
  | {
    error:
      | "method_not_allowed"
      | "reauthentication_required"
      | "rate_limited"
      | "deletion_failed";
  };

function reply(status: number, body: DeleteAccountBody): Response {
  return Response.json(body, { status });
}

/** Latest sign-in time in the token, in Unix seconds, or null. */
export function lastSignInAt(amr: unknown): number | null {
  if (!Array.isArray(amr)) return null;
  let latest: number | null = null;
  for (const entry of amr) {
    const timestamp = (entry as { timestamp?: unknown })?.timestamp;
    if (typeof timestamp === "number" && (latest === null || timestamp > latest)) {
      latest = timestamp;
    }
  }
  return latest;
}

export async function handleDeleteAccount(
  req: Request,
  claims: CallerClaims,
  admin: AccountAdmin,
  nowSeconds: number = Math.floor(Date.now() / 1000),
): Promise<Response> {
  if (req.method !== "POST") {
    return reply(405, { error: "method_not_allowed" });
  }

  const userId = claims.sub;

  // A refreshed token keeps the original sign-in time, so an old session on
  // an unlocked phone cannot delete the account.
  const signedInAt = lastSignInAt(claims.amr);
  if (signedInAt === null || nowSeconds - signedInAt > REAUTH_WINDOW_SECONDS) {
    return reply(403, { error: "reauthentication_required" });
  }

  try {
    if (!(await admin.noteAttempt(userId))) {
      return reply(429, { error: "rate_limited" });
    }
    await admin.deleteAvatarFiles(userId);
    await admin.deletePushTokens(userId);
    await admin.deleteUser(userId);
  } catch (error) {
    // No user ID, email or token in logs (S4): the error name is enough to
    // start looking.
    console.error("delete-account failed:", (error as Error)?.name ?? "unknown");
    return reply(500, { error: "deletion_failed" });
  }

  return reply(200, { status: "deleted" });
}
