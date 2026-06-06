#!/usr/bin/env python3
"""Generate SQL migration from supabase/seed/chat_bot_training_gemini_v1.json"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "supabase" / "seed" / "chat_bot_training_gemini_v1.json"
OUT = ROOT / "supabase" / "migrations" / "20260605160000_chat_faq_gemini_import.sql"


def sql_str(s: str) -> str:
    return s.replace("'", "''")


def sql_array(items: list[str]) -> str:
    inner = ", ".join(f"'{sql_str(x)}'" for x in items)
    return f"ARRAY[{inner}]"


def main() -> int:
    if not SEED.exists():
        print(f"Missing {SEED}", file=sys.stderr)
        return 1

    data = json.loads(SEED.read_text(encoding="utf-8"))
    rules = data.get("faq_rules", [])

    lines = [
        "-- PROPPITER: Import Gemini chat FAQ training pack v1",
        "",
        "ALTER TABLE public.chat_faq_rules",
        "  ADD COLUMN IF NOT EXISTS escalate boolean NOT NULL DEFAULT false;",
        "",
        "ALTER TABLE public.chat_faq_rules",
        "  ADD COLUMN IF NOT EXISTS topic_th text;",
        "",
        "COMMENT ON COLUMN public.chat_faq_rules.escalate IS",
        "  'When true, matching this FAQ notifies admin inbox';",
        "",
        "UPDATE public.chat_faq_rules SET is_active = false WHERE is_active = true;",
        "",
        "INSERT INTO public.chat_faq_rules",
        "  (scope, patterns, reply_text, priority, is_active, escalate, topic_th)",
        "VALUES",
    ]

    rows = []
    for r in rules:
        scope = r["scope"]
        patterns = sql_array(r["patterns"])
        reply = sql_str(r["reply_text"])
        priority = int(r.get("priority", 100))
        escalate = "true" if r.get("escalate") else "false"
        topic = sql_str(r.get("topic_th", ""))
        rows.append(
            f"  ('{scope}'::public.chat_faq_scope, {patterns}, "
            f"'{reply}', {priority}, true, {escalate}, '{topic}')"
        )

    lines.append(",\n".join(rows))
    lines.append(";")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {len(rules)} rules -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
