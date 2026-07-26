import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmToUsers } from "../_shared/notify.ts";

type LeaseRow = {
  id: string;
  listing_code: string;
  status: string;
  payment_policy: {
    reminder_days_before?: number[];
  } | null;
};

type InstallmentRow = {
  id: string;
  lease_id: string;
  sequence: number;
  due_date: string;
  status: string;
  reminders_sent_days_before: number[] | null;
  reminders_paused: boolean | null;
};

type MemberRow = {
  lease_id: string;
  user_id: string;
  role: string;
};

function dayStart(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function daysBetween(from: Date, to: Date): number {
  return Math.floor(
    (dayStart(to).getTime() - dayStart(from).getTime()) / 86400000,
  );
}

function isSettled(row: InstallmentRow): boolean {
  if (row.reminders_paused) return true;
  return row.status === "slip_submitted" ||
    row.status === "paid" ||
    row.status === "confirmed";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const today = dayStart(new Date());

    const { data: leases, error: leaseErr } = await supabase
      .from("rental_leases")
      .select("id, listing_code, status, payment_policy")
      .eq("status", "active");

    if (leaseErr) {
      return jsonResponse({ error: leaseErr.message }, 500);
    }

    const activeLeases = (leases ?? []) as LeaseRow[];
    if (activeLeases.length === 0) {
      return jsonResponse({ success: true, leases_checked: 0, reminders_sent: 0 });
    }

    const leaseIds = activeLeases.map((l) => l.id);
    const leaseById = new Map(activeLeases.map((l) => [l.id, l]));

    const { data: installments, error: instErr } = await supabase
      .from("rental_payment_installments")
      .select(
        "id, lease_id, sequence, due_date, status, reminders_sent_days_before, reminders_paused",
      )
      .in("lease_id", leaseIds);

    if (instErr) {
      return jsonResponse({ error: instErr.message }, 500);
    }

    const { data: members, error: memErr } = await supabase
      .from("rental_lease_members")
      .select("lease_id, user_id, role")
      .in("lease_id", leaseIds)
      .eq("role", "tenant");

    if (memErr) {
      return jsonResponse({ error: memErr.message }, 500);
    }

    const tenantsByLease = new Map<string, string[]>();
    for (const m of (members ?? []) as MemberRow[]) {
      const list = tenantsByLease.get(m.lease_id) ?? [];
      list.push(m.user_id);
      tenantsByLease.set(m.lease_id, list);
    }

    let sent = 0;

    for (const inst of (installments ?? []) as InstallmentRow[]) {
      if (isSettled(inst)) continue;

      const lease = leaseById.get(inst.lease_id);
      if (!lease) continue;

      const policyDays = lease.payment_policy?.reminder_days_before ?? [2, 1];
      const due = dayStart(new Date(inst.due_date));
      const daysUntil = daysBetween(today, due);
      const sentBefore = inst.reminders_sent_days_before ?? [];

      for (const before of policyDays) {
        if (daysUntil !== before || sentBefore.includes(before)) continue;

        const recipients = tenantsByLease.get(inst.lease_id) ?? [];
        const title = "RealXtate — ใกล้ครบชำระค่าเช่า";
        const body = [
          lease.listing_code,
          `รอบที่ ${inst.sequence}`,
          `อีก ${before} วัน`,
          inst.due_date,
        ].join(" · ");

        if (recipients.length > 0) {
          await sendFcmToUsers(supabase, recipients, title, body, {
            type: "rental_payment_reminder",
            lease_id: inst.lease_id,
            channel: "livingbkk",
            installment_sequence: String(inst.sequence),
          });
        }

        const nextSent = [...sentBefore, before].sort((a, b) => b - a);
        await supabase
          .from("rental_payment_installments")
          .update({ reminders_sent_days_before: nextSent })
          .eq("id", inst.id);

        sent++;
      }
    }

    return jsonResponse({
      success: true,
      leases_checked: activeLeases.length,
      reminders_sent: sent,
      ran_at: new Date().toISOString(),
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
