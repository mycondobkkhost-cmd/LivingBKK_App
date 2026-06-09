import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type NotifyPayload = {
  event: string;
  lead_id?: string;
  appointment_id?: string;
  calendar_event_id?: string;
  listing_code?: string;
  status?: string;
  scheduled_date?: string;
  time_slot?: string;
  seeker_nickname?: string;
  title?: string;
  description?: string;
  external_event_id?: string;
  start_at?: string;
  end_at?: string;
};

/** POST censored event to Make.com (no phone). */
export async function postMakeComWebhook(payload: NotifyPayload): Promise<void> {
  const url = Deno.env.get("MAKECOM_WEBHOOK_URL");
  if (!url) return;

  try {
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ...payload,
        source: "livingbkk",
        at: new Date().toISOString(),
      }),
    });
  } catch (_) {
    // non-fatal
  }
}

/** Legacy FCM HTTP API (optional FCM_SERVER_KEY). */
export async function sendFcmToUser(
  supabase: SupabaseClient,
  userId: string | null | undefined,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<{ sent: boolean }> {
  const serverKey = Deno.env.get("FCM_SERVER_KEY");
  if (!serverKey || !userId) return { sent: false };

  const { data: profile } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", userId)
    .maybeSingle();

  const token = profile?.fcm_token as string | undefined;
  if (!token || token.length < 20) return { sent: false };

  try {
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${serverKey}`,
      },
      body: JSON.stringify({
        to: token,
        notification: { title, body },
        data: { channel: "livingbkk", ...data },
      }),
    });
    return { sent: res.ok };
  } catch (_) {
    return { sent: false };
  }
}

export async function sendFcmToUsers(
  supabase: SupabaseClient,
  userIds: string[],
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<{ sent: number }> {
  const unique = [...new Set(userIds.filter((id) => id && id.length > 4))];
  let sent = 0;
  for (const uid of unique) {
    const res = await sendFcmToUser(supabase, uid, title, body, data);
    if (res.sent) sent++;
  }
  return { sent };
}
