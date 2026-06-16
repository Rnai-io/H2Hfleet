import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CHANNEL_SECRET = Deno.env.get("LINE_CHANNEL_SECRET") ?? "";
const CHANNEL_TOKEN = Deno.env.get("LINE_CHANNEL_TOKEN") || "KlxTUlAtEC4NNmBbAcWvo83SCTzirO5zOHOiicwpiWlXKExRUf9SbfTtv8+tW9+cZc/uS5/mhUt/WZEzPRV+EgYoqlCnyv19BtEaqSULuCFkBzX0FBWLeg47H6UEKvD4h2xYzvKKKuaUnfwezepwLQdB04t89/1O/w1cDnyilFU=";
const LINE_REPLY_URL = "https://api.line.me/v2/bot/message/reply";

const commands: Record<string, string> = {
  "สรุป|summary|รายงาน": "📊 ค่าใช้จ่ายวันนี้\n\n• ค่าใช้จ่ายรวม: ฿0\n• รายการ: 0 รายการ\n\n💡 เปิดแอป H2HFleet เพื่อดูข้อมูลเต็ม",
  "รถ|vehicle|status": "🚛 สถานะรถออนไลน์\n\n• รถที่ใช้งาน: 1 คัน\n• คนขับออนไลน์: 1 คน\n\n💡 เปิดแอป → แผนที่สด เพื่อดู GPS",
  "รวม|total|sum": "💰 สรุปค่าใช้จ่าย\n\n📅 วันนี้: ฿0\n📅 สัปดาห์นี้: ฿0\n📅 เดือนนี้: ฿0",
  "เดินทาง|route|เส้นทาง": "🗺️ ประวัติการเดินทาง\n\n• ระยะทาง: 0 กม.\n• เวลา: 0 ชม.\n\n💡 ดูรายละเอียดในแอป",
  "น้ำมัน|oil|fuel": "⛽ ค่าน้ำมัน\n\n• วันนี้: ฿0\n• สัปดาห์นี้: ฿0\n• เดือนนี้: ฿0",
  "ซ่อม|repair|maintenance": "🔧 ค่าซ่อมบำรุง\n\n• วันนี้: ฿0\n• สัปดาห์นี้: ฿0\n• เดือนนี้: ฿0",
  "ai|อัจฉริยะ": "🤖 AI สรุปการจัดการรถ\n\n✅ วิเคราะห์ค่าใช้จ่าย\n✅ เส้นทางและระยะทาง\n✅ ข้อแนะนำการประหยัด\n\n💡 เปิดแอป → Dashboard",
  "แจ้งเตือน|notification|alert": "🔔 ระบบแจ้งเตือน\n\n• แจ้งเตือนค่าใช้จ่าย: ✅\n• แจ้งเตือนรถออนไลน์: ✅\n• สรุป AI: ✅",
  "ช่วย|help|คำสั่ง|command": "🚛 H2HFleet Bot - คำสั่งทั้งหมด\n\n📊 ข้อมูล:\n• สรุป\n• รถ\n• เดินทาง\n• รวม\n\n💸 ค่าใช้จ่าย:\n• น้ำมัน\n• ซ่อม\n\n🤖 อื่นๆ:\n• ai\n• แจ้งเตือน\n• id (รับ User ID)",
};

serve(async (req) => {
  if (req.method === "GET") return new Response("OK", { status: 200 });
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  const body = await req.text();

  try {
    const events = JSON.parse(body).events ?? [];

    for (const event of events) {
      if (event.type === "message" && event.message?.type === "text") {
        const text = event.message.text?.trim().toLowerCase() ?? "";
        const replyToken = event.replyToken;

        // คำสั่ง id — ส่ง User ID กลับ
        if (text === "id" || text === "userid" || text === "user id") {
          await fetch(LINE_REPLY_URL, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${CHANNEL_TOKEN}`,
            },
            body: JSON.stringify({
              replyToken,
              messages: [{
                type: "text",
                text: `🆔 LINE User ID ของคุณ:\n\n${event.source?.userId ?? "ไม่พบ User ID"}\n\n📋 Copy ไปวางในแอป H2HFleet\nเมนู LINE Notify → LINE User ID → บันทึก`,
              }],
            }),
          });
          continue;
        }

        let replyText = "🚛 H2HFleet Bot\n\nพิมพ์ 'ช่วย' เพื่อดูคำสั่งทั้งหมด\nหรือพิมพ์ 'id' เพื่อรับ User ID";

        for (const [keywords, response] of Object.entries(commands)) {
          const keywordList = keywords.split("|");
          if (keywordList.some(kw => text.includes(kw.toLowerCase()))) {
            replyText = response;
            break;
          }
        }

        await fetch(LINE_REPLY_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${CHANNEL_TOKEN}`,
          },
          body: JSON.stringify({
            replyToken,
            messages: [
              { type: "text", text: replyText },
              { type: "text", text: "📱 เปิดแอป H2HFleet\nhttps://rnai-io.github.io/H2Hfleet/" },
            ],
          }),
        });
      }
    }
  } catch (_) {}

  return new Response("OK", { status: 200 });
});
