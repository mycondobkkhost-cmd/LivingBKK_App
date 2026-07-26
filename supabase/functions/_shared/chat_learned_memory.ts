import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type LearnedAnswer = {
  id: string;
  topic_key: string;
  question_example: string;
  answer_guidance: string;
  scope: string;
  listing_id: string | null;
  property_type: string | null;
  use_count: number;
};

/** Load learned guidance — global + property-type + listing-specific. */
export async function loadLearnedAnswers(
  db: SupabaseClient,
  opts: {
    listingId?: string | null;
    propertyType?: string | null;
    userText: string;
    limit?: number;
  },
): Promise<LearnedAnswer[]> {
  const limit = opts.limit ?? 8;
  const { data } = await db
    .from("chat_learned_answers")
    .select(
      "id, topic_key, question_example, answer_guidance, scope, listing_id, property_type, use_count",
    )
    .eq("is_active", true)
    .order("use_count", { ascending: false })
    .limit(40);

  const rows = (data ?? []) as LearnedAnswer[];
  const q = opts.userText.toLowerCase();

  const scored = rows
    .map((row) => {
      let score = row.use_count;
      if (row.scope === "listing" && row.listing_id === opts.listingId) {
        score += 100;
      } else if (
        row.scope === "property_type" &&
        opts.propertyType &&
        row.property_type === opts.propertyType
      ) {
        score += 50;
      } else if (row.scope === "global") {
        score += 10;
      } else {
        score -= 20;
      }
      const ex = row.question_example.toLowerCase();
      if (ex && (q.includes(ex.slice(0, 8)) || ex.includes(q.slice(0, 8)))) {
        score += 30;
      }
      if (row.topic_key && q.includes(row.topic_key.replace(/_/g, " "))) {
        score += 20;
      }
      return { row, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((x) => x.row);

  return scored;
}

export async function saveLearnedAnswer(
  db: SupabaseClient,
  input: {
    topicKey: string;
    questionExample: string;
    answerGuidance: string;
    scope?: "global" | "property_type" | "listing";
    listingId?: string | null;
    propertyType?: string | null;
    sourceThreadId?: string | null;
    createdBy?: string | null;
  },
): Promise<string | null> {
  const { data, error } = await db
    .from("chat_learned_answers")
    .insert({
      topic_key: input.topicKey.slice(0, 120),
      question_example: input.questionExample.slice(0, 500),
      answer_guidance: input.answerGuidance.slice(0, 4000),
      scope: input.scope ?? "global",
      listing_id: input.listingId ?? null,
      property_type: input.propertyType ?? null,
      source_thread_id: input.sourceThreadId ?? null,
      created_by: input.createdBy ?? null,
    })
    .select("id")
    .single();

  if (error) {
    console.error("saveLearnedAnswer", error.message);
    return null;
  }
  return data?.id as string ?? null;
}

export async function bumpLearnedAnswerUse(
  db: SupabaseClient,
  id: string,
): Promise<void> {
  const { data } = await db
    .from("chat_learned_answers")
    .select("use_count")
    .eq("id", id)
    .maybeSingle();
  const n = ((data?.use_count as number) ?? 0) + 1;
  await db.from("chat_learned_answers").update({ use_count: n }).eq("id", id);
}

export function learnedAnswersBlock(rows: LearnedAnswer[]): string {
  if (rows.length === 0) return "(none yet — admin may coach new answers)";
  return rows
    .map(
      (r) =>
        `[${r.scope}/${r.topic_key}] Q: ${r.question_example} → GUIDANCE (paraphrase naturally): ${r.answer_guidance}`,
    )
    .join("\n");
}
