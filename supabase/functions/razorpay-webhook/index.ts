// Razorpay webhook – escrow: payment.captured → lockEscrow; payment.failed → cancel; payout.processed → releasePayout; refund.processed → reverse
// Configure in Razorpay Dashboard: https://<project>.supabase.co/functions/v1/razorpay-webhook
// Secrets: RAZORPAY_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RAZORPAY_WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

async function verifyRazorpaySignature(body: string, signature: string, secret: string): Promise<boolean> {
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
    const expected = Array.from(new Uint8Array(sig))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    return expected === signature;
  } catch {
    return false;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  const signature = req.headers.get("X-Razorpay-Signature") ?? "";
  const body = await req.text();
  if (!RAZORPAY_WEBHOOK_SECRET || !(await verifyRazorpaySignature(body, signature, RAZORPAY_WEBHOOK_SECRET))) {
    return new Response(JSON.stringify({ error: "Invalid signature" }), { status: 400 });
  }

  let event: { event: string; payload: Record<string, unknown> };
  try {
    event = JSON.parse(body);
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400 });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // ─── payment.captured → lock escrow, order in_progress ───────────────────
  if (event.event === "payment.captured") {
    const paymentEntity = (event.payload as Record<string, unknown>).payment as Record<string, unknown> | undefined;
    const payment = paymentEntity?.entity as Record<string, unknown> | undefined;
    if (payment) {
      const razorpayPaymentId = payment.id as string | undefined;
      const amountPaise = (payment.amount as number) || 0;
      const amountInr = amountPaise / 100;
      const notes = (payment.notes as Record<string, string>) ?? {};
      const metaOrderId = notes.order_id;
      const roleVerification = notes.role_verification;
      const userId = notes.user_id;

      if (roleVerification && userId) {
        await supabase.from("roles").upsert({
          user_id: userId,
          role: roleVerification,
          paid_at: new Date().toISOString(),
          verified_at: new Date().toISOString(),
        }, { onConflict: "user_id,role" });
      }

      if (metaOrderId && razorpayPaymentId) {
        const { data: order } = await supabase.from("orders").select("total_inr, platform_charge_inr, status, buyer_id, provider_id").eq("id", metaOrderId).single();
        if (order && order.status === "pending_payment") {
          const totalInr = Number(order.total_inr);
          const platformFee = Number(order.platform_charge_inr ?? 49);
          const creatorPayout = totalInr - platformFee;
          await supabase.from("order_finance").update({
            buyer_paid_amount: totalInr,
            platform_fee: platformFee,
            escrow_locked: true,
            creator_payout: creatorPayout,
            razorpay_payment_id: razorpayPaymentId,
            finance_status: "escrow_locked",
            updated_at: new Date().toISOString(),
          }).eq("order_id", metaOrderId);
          await supabase.from("orders").update({
            status: "in_progress",
            chat_unlocked_at: new Date().toISOString(),
            ready_for_delivery_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          }).eq("id", metaOrderId);
          const buyerId = order.buyer_id as string;
          const creatorId = order.provider_id as string;
          await supabase.from("chat_rooms").upsert({
            order_id: metaOrderId,
            buyer_id: buyerId,
            creator_id: creatorId,
          }, { onConflict: "order_id" });
          await supabase.from("order_timeline").insert({
            order_id: metaOrderId,
            event_type: "payment_received",
            title: "Payment received",
            description: "Escrow locked. Order in progress.",
          });
        }
      }

      if (metaOrderId && userId) {
        await supabase.from("payments").insert({
          order_id: metaOrderId,
          user_id: userId,
          razorpay_payment_id: razorpayPaymentId,
          amount_inr: amountInr,
          status: "captured",
        });
      }
    }
  }

  // ─── payment.failed → cancel order ───────────────────────────────────────
  if (event.event === "payment.failed") {
    const paymentEntity = (event.payload as Record<string, unknown>).payment as Record<string, unknown> | undefined;
    const payment = paymentEntity?.entity as Record<string, unknown> | undefined;
    const notes = (payment?.notes as Record<string, string>) ?? {};
    const metaOrderId = notes.order_id;
    if (metaOrderId) {
      await supabase.from("orders").update({
        status: "failed",
        updated_at: new Date().toISOString(),
      }).eq("id", metaOrderId);
      await supabase.from("order_finance").update({
        payout_status: "failed",
        updated_at: new Date().toISOString(),
      }).eq("order_id", metaOrderId);
    }
  }

  // ─── payout.processed → release payout ───────────────────────────────────
  if (event.event === "payout.processed") {
    const payoutEntity = (event.payload as Record<string, unknown>).payout as Record<string, unknown> | undefined;
    const payout = payoutEntity?.entity as Record<string, unknown> | undefined;
    const payoutId = payout?.id as string | undefined;
    const notes = (payout?.notes as Record<string, string>) ?? {};
    const metaOrderId = notes.order_id;
    if (metaOrderId) {
      await supabase.from("order_finance").update({
        payout_status: "released",
        released_at: new Date().toISOString(),
        transaction_id: payoutId,
        finance_status: "payout_released",
        updated_at: new Date().toISOString(),
      }).eq("order_id", metaOrderId);
      await supabase.from("orders").update({
        status: "completed",
        updated_at: new Date().toISOString(),
      }).eq("id", metaOrderId);
    }
  }

  // ─── refund.processed → reverse (refund buyer) ───────────────────────────
  if (event.event === "refund.processed") {
    const refundEntity = (event.payload as Record<string, unknown>).refund as Record<string, unknown> | undefined;
    const refund = refundEntity?.entity as Record<string, unknown> | undefined;
    const paymentId = refund?.payment_id as string | undefined;
    if (paymentId) {
      const { data: row } = await supabase.from("order_finance").select("order_id").eq("razorpay_payment_id", paymentId).maybeSingle();
      if (row?.order_id) {
        await supabase.from("order_finance").update({
          payout_status: "refunded",
          updated_at: new Date().toISOString(),
        }).eq("order_id", row.order_id);
        await supabase.from("orders").update({
          status: "cancelled",
          updated_at: new Date().toISOString(),
        }).eq("id", row.order_id);
      }
    }
  }

  return new Response("OK", {
    status: 200,
    headers: { "Content-Type": "text/plain" },
  });
});
