/** โทน AI เมื่อลูกค้าขอหาห้องอื่นจากแชททรัพย์ — fork ไปฟอร์มฝากหา */
import { FIND_OTHER_ACK, FIND_OTHER_FORK } from "./chat_ai_voice.ts";

export const FIND_OTHER = {
  formLabel: "กรอกบรีฟฝากหาห้อง",
  ack: FIND_OTHER_ACK,
  fork: FIND_OTHER_FORK,
} as const;

export function findOtherRoomBurst(): string[] {
  return [FIND_OTHER.ack, FIND_OTHER.fork];
}
