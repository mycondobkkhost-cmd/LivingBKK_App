import {
  fuzzyIncludes,
  normalizeChatText,
} from "./chat_text_normalize.ts";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

Deno.test("normalizeChatText maps Thai price typos", () => {
  assert(
    normalizeChatText("เท่าไหร่ครับ").includes("เท่าไร"),
    "เท่าไหร่ → เท่าไร",
  );
});

Deno.test("fuzzyIncludes matches FAQ pattern with typo", () => {
  assert(
    fuzzyIncludes("สัตวเลี้ยงได้ไหม", "สัตว์เลี้ยง"),
    "missing ์ on สัตว์",
  );
  assert(
    fuzzyIncludes("ค่าส่วนกลางงเท่าไร", "ค่าส่วนกลาง"),
    "extra ง on ค่าส่วนกลาง",
  );
});

Deno.test("fuzzyIncludes exact English patterns", () => {
  assert(fuzzyIncludes("common fee เท่าไร", "common fee"), "english alias");
  assert(fuzzyIncludes("มี parking ไหม", "parking"), "parking");
});
