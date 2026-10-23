// delete-account — deletes the calling user's account and all their data
// (P14; App Store 5.1.1(v), Google Play account deletion).
//
// The caller is authenticated *inside* the function: withSupabase verifies
// the user's JWT against the project's signing keys (JWKS) before the
// handler runs; the gateway check (verify_jwt) is only a first layer. The
// admin client uses the project's secret key from the function environment
// and never leaves the server.
import { withSupabase } from "@supabase/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type AccountAdmin, handleDeleteAccount } from "./handler.ts";

const AVATARS_BUCKET = "avatars";

/** Every object path under `prefix/`, descending into sub-folders. */
async function listAvatarPaths(admin: SupabaseClient, prefix: string): Promise<string[]> {
  const paths: string[] = [];
  const pageSize = 1000;
  for (let offset = 0;; offset += pageSize) {
    const { data, error } = await admin.storage
      .from(AVATARS_BUCKET)
      .list(prefix, { limit: pageSize, offset });
    if (error) throw error;
    for (const item of data) {
      const path = `${prefix}/${item.name}`;
      // Folders come back without an id.
      if (item.id === null) {
        paths.push(...await listAvatarPaths(admin, path));
      } else {
        paths.push(path);
      }
    }
    if (data.length < pageSize) return paths;
  }
}

function accountAdmin(admin: SupabaseClient): AccountAdmin {
  return {
    async noteAttempt(userId) {
      const { data, error } = await admin.rpc("note_account_deletion_attempt", {
        p_user_id: userId,
      });
      if (error) throw error;
      return data === true;
    },
    async deleteAvatarFiles(userId) {
      const paths = await listAvatarPaths(admin, userId);
      for (let i = 0; i < paths.length; i += 1000) {
        const { error } = await admin.storage
          .from(AVATARS_BUCKET)
          .remove(paths.slice(i, i + 1000));
        if (error) throw error;
      }
    },
    async deletePushTokens(userId) {
      const { error } = await admin.from("push_tokens").delete().eq("user_id", userId);
      if (error) throw error;
    },
    async deleteUser(userId) {
      const { error } = await admin.auth.admin.deleteUser(userId);
      // Already deleted (a retry after success): the outcome is the same.
      if (error && error.status !== 404) throw error;
    },
  };
}

export default {
  fetch: withSupabase({ auth: "user" }, (req, ctx) =>
    handleDeleteAccount(
      req,
      ctx.jwtClaims!,
      accountAdmin(ctx.supabaseAdmin as unknown as SupabaseClient),
    )),
};
