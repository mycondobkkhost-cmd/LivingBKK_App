import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseProposedViewingSchedule } from "./viewing_request_voice.ts";

Deno.test("parseProposedViewingSchedule — 16:00 วันนี้", () => {
  assertEquals(parseProposedViewingSchedule("16:00 วันนี้"), "วันนี้ · 16:00 น.");
});

Deno.test("parseProposedViewingSchedule — พรุ่งนี้ 10 โมง", () => {
  assertEquals(parseProposedViewingSchedule("พรุ่งนี้ 10 โมง"), "พรุ่งนี้ · 10:00 น.");
});

Deno.test("parseProposedViewingSchedule — วันอื่น", () => {
  assertEquals(
    parseProposedViewingSchedule("นัดดู 15/6 14:30"),
    "15/6 · 14:30 น.",
  );
});
