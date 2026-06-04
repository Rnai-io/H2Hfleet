import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { totalSpent, expenses, vehicleCount } = await req.json();

    let prompt = "";
    if (!expenses || Object.keys(expenses).length === 0) {
      prompt = `วันนี้ยังไม่มีค่าใช้จ่ายรถ (${vehicleCount} คัน) แนะนำสิ่งที่ควรตรวจสอบประจำวันสั้นๆ`;
    } else {
      const list = Object.entries(expenses)
        .map(([k, v]) => `- ${k}: ${Number(v).toFixed(0)} บาท`)
        .join("\n");
      prompt = `รถ ${vehicleCount} คัน ค่าใช้จ่ายวันนี้รวม ${Number(totalSpent).toFixed(0)} บาท\n${list}\n\nสรุปสั้นๆ ให้เจ้าของกิจการ: มีค่าใช้จ่ายอะไรผิดปกติไหม? ควรระวังอะไร?`;
    }

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ไทย ตอบเป็นภาษาไทยเท่านั้น กระชับ ไม่เกิน 60 คำ",
          },
          { role: "user", content: prompt },
        ],
        max_tokens: 200,
        temperature: 0.7,
      }),
    });

    const data = await res.json();
    const text = data.choices?.[0]?.message?.content?.trim() ?? "ไม่มีข้อมูลวันนี้";

    return new Response(JSON.stringify({ summary: text }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ summary: "ไม่สามารถสร้างสรุปได้ในขณะนี้" }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
