import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { requireAdmin } from "../_shared/admin_auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/notify.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await requireAdmin(req);
    if (auth instanceof Response) return auth;

    const body = await req.json();
    const requirementId = body.requirement_id as string | undefined;
    const postCode = body.post_code as string | undefined;
    const postTitle = (body.post_title as string | undefined)?.trim();

    if (!requirementId || !postCode) {
      return jsonResponse({ error: "requirement_id and post_code required" }, 400);
    }

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: reqRow, error: reqErr } = await db
      .from("customer_requirements")
      .select("id, user_id, thread_id")
      .eq("id", requirementId)
      .single();

    if (reqErr || !reqRow) {
      return jsonResponse({ error: "Requirement not found" }, 404);
    }

    const threadId = reqRow.thread_id as string | null;
    if (!threadId) {
      return jsonResponse({ error: "Requirement has no chat thread yet" }, 400);
    }

    const titlePart = postTitle ? ` (${postTitle})` : "";
    const text =
      `เผยแพร่บนบอร์ดแล้ว รหัส ${postCode}${titlePart}\n` +
      "ทีมกำลังรับข้อเสนอจากเจ้าของ/นายหน้า — จะคัดแล้วส่งให้ในแชทนี้ครับ";

    const { data: msg, error: msgError } = await db
      .from("chat_messages")
      .insert({
        thread_id: threadId,
        role: "admin_notice",
        text,
        sender_id: auth.userId,
      })
      .select("*")
      .single();

    if (msgError) return jsonResponse({ error: msgError.message }, 400);

    await db
      .from("chat_threads")
      .update({
        listing_code: postCode,
        admin_reply_done: false,
        admin_escalated: true,
        status: "open",
        last_message_at: new Date().toISOString(),
      })
      .eq("id", threadId);

    const userId = reqRow.user_id as string | undefined;
    if (userId) {
      await sendFcmToUser(
        db,
        userId,
        "PROPPITER — บอร์ดเผยแพร่แล้ว",
        `${postCode}: ทีมกำลังรับข้อเสนอทรัพย์ให้คุณ`,
        { type: "requirement_published", thread_id: threadId, post_code: postCode },
      );
    }

    return jsonResponse({ message: msg, thread_id: threadId });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
