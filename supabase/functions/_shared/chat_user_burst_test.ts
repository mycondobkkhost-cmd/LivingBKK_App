import {
  mergeUserBurstTexts,
  trailingUserTexts,
  type ThreadMessageRow,
} from "./chat_user_burst.ts";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

Deno.test("trailingUserTexts collects burst at end", () => {
  const rows: ThreadMessageRow[] = [
    { id: "1", role: "ai", text: "welcome", created_at: "t1" },
    { id: "2", role: "user", text: "สวัสดีค่ะ", created_at: "t2" },
    { id: "3", role: "ai", text: "hi back", created_at: "t3" },
    { id: "4", role: "user", text: "มีห้องอื่นใกล้ปี", created_at: "t4" },
    { id: "5", role: "user", text: "ใกล้ปีนี้อีกไหมคะ", created_at: "t5" },
  ];
  const burst = trailingUserTexts(rows);
  assert(
    burst.length === 2 && burst[0] === "มีห้องอื่นใกล้ปี",
    "burst first line",
  );
  assert(
    mergeUserBurstTexts(burst) === "มีห้องอื่นใกล้ปี ใกล้ปีนี้อีกไหมคะ",
    "merged burst",
  );
});

Deno.test("trailingUserTexts stops at prior bot message", () => {
  const rows: ThreadMessageRow[] = [
    { id: "1", role: "user", text: "old", created_at: "t1" },
    { id: "2", role: "ai", text: "reply", created_at: "t2" },
    { id: "3", role: "user", text: "new only", created_at: "t3" },
  ];
  assert(
    trailingUserTexts(rows).join("|") === "new only",
    "only latest burst",
  );
});
