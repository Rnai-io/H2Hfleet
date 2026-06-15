import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CHANNEL_SECRET = Deno.env.get("LINE_CHANNEL_SECRET") ?? "";
const CHANNEL_TOKEN = Deno.env.get("LINE_CHANNEL_TOKEN") || "KlxTUlAtEC4NNmBbAcWvo83SCTzirO5zOHOiicwpiWlXKExRUf9SbfTtv8+tW9+cZc/uS5/mhUt/WZEzPRV+EgYoqlCnyv19BtEaqSULuCFkBzX0FBWLeg47H6UEKvD4h2xYzvKKKuaUnfwezepwLQdB04t89/1O/w1cDnyilFU=";
const LINE_REPLY_URL = "https://api.line.me/v2/bot/message/reply";

const commands: Record<string, string> = {
  "สรุป|summary|รายงาน": "📊 ค่าใช้จ่ายวันนี้\n\nรายละเอียด:\n• ค่าใช้จ่ายรวม: ฿0\n• รายการ: 0 รายการ\n\n💡 เปิดแอป H2HFleet เพื่อดูข้อมูลเต็มรูปแบบและวิเคราะห์เสมือน",

  "รถ|vehicle|status": "🚛 สถานะรถออนไลน์\n\n• รถที่ใช้งาน: 1 คัน\n• คนขับออนไลน์: 1 คน\n• ตำแหน่ง: ดูแผนที่สด\n\n💡 เปิดแอป H2HFleet → แผนที่สด เพื่อดูตำแหน่งรถ GPS เรียลไทม์",

  "รวม|total|sum": "💰 สรุปค่าใช้จ่าย\n\n📅 วันนี้: ฿0\n📅 สัปดาห์นี้: ฿0\n📅 เดือนนี้: ฿0\n\n📈 เทรนด์: ลดลง 5% จากเดือนที่แล้ว",

  "เดินทาง|route|เส้นทาง": "🗺️ ประวัติการเดินทาง\n\n• ระยะทาง: 0 กม.\n• เวลา: 0 ชม.\n• ความเร็วเฉลี่ย: 0 กม./ชม.\n• เวลาจอด: 0 นาที\n\n💡 ดูรายละเอียดเต็มในแอป → เลือกรถ → ดูเส้นทาง",

  "น้ำมัน|oil|fuel": "⛽ ค่าน้ำมัน\n\n• วันนี้: ฿0\n• สัปดาห์นี้: ฿0\n• เดือนนี้: ฿0\n\n📊 ค่าเฉลี่ย: 0 บาท/วัน",

  "ซ่อม|repair|maintenance": "🔧 ค่าซ่อมบำรุง\n\n• วันนี้: ฿0\n• สัปดาห์นี้: ฿0\n• เดือนนี้: ฿0\n\n⚠️ รถถัดไปที่ต้องตรวจสอบ: ไม่มี",

  "ai|สรุป ai|อัจฉริยะ": "🤖 AI สรุปการจัดการรถ\n\nAI วิเคราะห์:\n✅ ค่าใช้จ่ายการจัดการรถ\n✅ เส้นทางและระยะทาง\n✅ ประสิทธิภาพการขับขี่\n✅ ข้อแนะนำการประหยัด\n\n💡 เปิดแอป → Dashboard → ดูสรุป AI ประจำวัน",

  "แจ้งเตือน|notification|alert": "🔔 ตั้งค่าแจ้งเตือน\n\n• แจ้งเตือนค่าใช้จ่าย: ✅ เปิด\n• แจ้งเตือนรถออนไลน์: ✅ เปิด\n• แจ้งเตือนสรุป AI: ✅ เปิด\n\n📲 คุณจะได้รับ notification ทั้ง LINE และแอป",

  "ช่วย|help|คำสั่ง|help|command": `🚛 H2HFleet Bot - คำสั่งทั้งหมด\n\n📊 สถิติและข้อมูล:\n• สรุป - ค่าใช้จ่ายวันนี้\n• รถ - สถานะรถออนไลน์\n• เดินทาง - ประวัติเส้นทาง\n• รวม - สรุปค่าใช้จ่าย\n\n💸 รายละเอียดค่า:\n• น้ำมัน - ค่าน้ำมัน\n• ซ่อม - ค่าซ่อมบำรุง\n\n🤖 ความเพิ่มเติม:\n• AI - สรุป AI\n• แจ้งเตือน - ตั้งค่า\n\n💡 พิมพ์คำสั่งใดก็ได้ เราจะช่วยแสดงข้อมูล`,
};

serve(async (req) => {
  if (req.method === "GET") return new Response("OK", { status: 200 });
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  const body = await req.text();
  const signature = req.headers.get("x-line-signature") ?? "";

  if (CHANNEL_SECRET && signature) {
    try {
      const enc = new TextEncoder();
      const key = await crypto.subtle.importKey(
        "raw",
        enc.encode(CHANNEL_SECRET),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
      );
      const sig = await crypto.subtle.sign("HMAC", key, enc.encode(body));
      const expected = btoa(String.fromCharCode(...new Uint8Array(sig)));
      if (signature !== expected) return new Response("Unauthorized", { status: 401 });
    } catch (_) {}
  }

  try {
    const events = JSON.parse(body).events ?? [];

    for (const event of events) {
      if (event.type === "message" && event.message?.type === "text") {
        const text = event.message.text?.trim().toLowerCase() ?? "";
        const replyToken = event.replyToken;

        // ตอบ User ID เมื่อพิมพ์ "id"
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
                text: `🆔 LINE User ID ของคุณ:\n\n${event.source?.userId ?? "ไม่พบ User ID"}\n\n📋 Copy ไปวางในแอป H2HFleet\nSettings → LINE Notify → LINE User ID`,
              }],
            }),
          });
          continue;
        }

        let replyText = "🚛 H2HFleet Bot\n\nพิมพ์ 'ช่วย' เพื่อดูคำสั่งทั้งหมด";

        // ค้นหาคำสั่งที่ตรงกัน
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
              {
                type: "text",
                text: "📱 เปิดแอป H2HFleet\nhttps://rnai-io.github.io/H2Hfleet/",
              },
            ],
          }),
        });
      }
    }
  } catch (_) {}

  return new Response("OK", { status: 200 });
});
