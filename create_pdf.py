from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ลงทะเบียนฟอนต์ที่รองรับภาษาไทย
FONT = "ArialUnicode"
pdfmetrics.registerFont(TTFont(FONT, "/Library/Fonts/Arial Unicode.ttf"))

# สี
BLUE      = colors.HexColor("#1E40AF")
ACCENT    = colors.HexColor("#2563EB")
LIGHT_BG  = colors.HexColor("#EFF6FF")
GRAY      = colors.HexColor("#64748B")
BORDER    = colors.HexColor("#CBD5E1")
WHITE     = colors.white
GREEN     = colors.HexColor("#059669")

W, H = A4

# ─── Styles ────────────────────────────────────────────────────────
def s(name, **kw):
    kw.setdefault("fontName", FONT)
    return ParagraphStyle(name, **kw)

title_style   = s("Title",  fontSize=22, textColor=WHITE,   spaceAfter=4,  leading=28, alignment=1)
sub_style     = s("Sub",    fontSize=11, textColor=colors.HexColor("#BFDBFE"), spaceAfter=2, leading=15, alignment=1)
badge_style   = s("Badge",  fontSize=9,  textColor=colors.HexColor("#93C5FD"), alignment=1)
q_style       = s("Q",      fontSize=10, textColor=ACCENT,  spaceBefore=8,  spaceAfter=2, leading=14)
a_style       = s("A",      fontSize=10, textColor=colors.HexColor("#334155"), spaceAfter=4, leading=15, leftIndent=10)
footer_style  = s("Footer", fontSize=8,  textColor=GRAY,    alignment=1)

# ─── Helper ────────────────────────────────────────────────────────
def section(title):
    return [
        Spacer(1, 8),
        Table(
            [[Paragraph(f"  {title}", s("SH", fontSize=11, textColor=WHITE, leading=16, fontName=FONT))]],
            colWidths=[W - 4*cm],
            style=TableStyle([
                ("BACKGROUND", (0,0), (-1,-1), ACCENT),
                ("ROUNDEDCORNERS", (0,0), (-1,-1), [6,6,6,6]),
                ("TOPPADDING",    (0,0), (-1,-1), 6),
                ("BOTTOMPADDING", (0,0), (-1,-1), 6),
                ("LEFTPADDING",   (0,0), (-1,-1), 10),
            ])
        ),
        Spacer(1, 4),
    ]

def qa(question, answer):
    rows = []
    rows.append(Paragraph(f"Q  {question}", q_style))
    rows.append(Paragraph(f"A  {answer}",   a_style))
    return rows

def bullet_answer(question, items):
    rows = [Paragraph(f"Q  {question}", q_style)]
    for item in items:
        rows.append(Paragraph(f"A  • {item}", a_style))
    return rows

# ─── Document ─────────────────────────────────────────────────────
doc = SimpleDocTemplate(
    "/Users/chanakhongdi/H2Hfleet/H2HFleet_LINE_Reference.pdf",
    pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=1.5*cm, bottomMargin=2*cm,
)

story = []

# Header banner
banner_data = [[
    Paragraph("H2HFleet", title_style),
    Paragraph("ระบบบริหารจัดการรถยนต์สำหรับ SME ไทย", sub_style),
    Paragraph("LINE Official Account: @655jmtme", badge_style),
]]
banner = Table(
    banner_data,
    colWidths=[W - 4*cm],
    style=TableStyle([
        ("BACKGROUND",    (0,0), (-1,-1), BLUE),
        ("TOPPADDING",    (0,0), (-1,-1), 18),
        ("BOTTOMPADDING", (0,0), (-1,-1), 18),
        ("LEFTPADDING",   (0,0), (-1,-1), 20),
        ("RIGHTPADDING",  (0,0), (-1,-1), 20),
        ("ROUNDEDCORNERS",(0,0), (-1,-1), [10,10,10,10]),
    ])
)
story.append(banner)
story.append(Spacer(1, 12))

# ── 1. แนะนำบริการ ────────────────────────────────────────────────
story += section("แนะนำบริการ")
story += qa(
    "H2HFleet คืออะไร?",
    "แอปพลิเคชันบริหารจัดการรถยนต์สำหรับธุรกิจ SME ไทย ช่วยให้เจ้าของธุรกิจติดตามรถ ดูค่าใช้จ่าย และรับสรุปอัจฉริยะจาก AI เป็นภาษาไทย"
)
story += bullet_answer("บริการมีอะไรบ้าง?", [
    "ติดตาม GPS แบบเรียลไทม์ ดูรถบนแผนที่สด",
    "โหมดคนขับ: แอปส่ง GPS อัตโนมัติทุก 60 วินาที",
    "ดูประวัติเส้นทาง ระยะทาง ความเร็ว เวลาจอด",
    "บันทึกค่าใช้จ่าย เช่น น้ำมัน ค่าซ่อม",
    "AI สรุปค่าใช้จ่ายเป็นภาษาไทยทุกวัน",
    "แจ้งเตือนผ่าน LINE Notify",
])

# ── 2. การสมัครใช้งาน ─────────────────────────────────────────────
story += section("การสมัครใช้งาน")
story += qa(
    "สมัครใช้งานอย่างไร?",
    "ดาวน์โหลดแอป H2HFleet กด สมัครสมาชิก กรอกชื่อ อีเมล รหัสผ่าน จากนั้นเพิ่มข้อมูลบริษัทและรถยนต์ได้เลย"
)
story += qa(
    "ใช้ได้กับรถกี่คัน?",
    "ไม่จำกัดจำนวนคัน รองรับทุกประเภท เช่น รถเก๋ง SUV รถกระบะ รถตู้ รถบรรทุก รถปูน รถห้องเย็น"
)
story += qa(
    "ต้องมีอุปกรณ์ GPS พิเศษไหม?",
    "ไม่จำเป็น คนขับใช้โทรศัพท์ที่มีอยู่แล้ว เปิดโหมดคนขับในแอป แอปจะส่ง GPS ให้อัตโนมัติ หากต้องการติดตามแบบไม่พึ่งโทรศัพท์คนขับ สามารถติดตั้งอุปกรณ์ GPS เพิ่มเติมได้"
)

# ── 3. การใช้งาน GPS ──────────────────────────────────────────────
story += section("การใช้งาน GPS")
story += qa(
    "วิธีเริ่มติดตาม GPS?",
    "คนขับเปิดแอป H2HFleet กด โหมดคนขับ เลือกรถ กด เริ่มเดินทาง แอปจะส่งตำแหน่งให้เจ้าของเห็นบนแผนที่ทันที"
)
story += qa(
    "เจ้าของดูรถจากที่ไหน?",
    "เปิดแอป H2HFleet กด แผนที่สด จะเห็นตำแหน่งรถทุกคันแบบ real-time บนแผนที่"
)
story += qa(
    "ดูประวัติการเดินทางได้ไหม?",
    "ได้ เปิดแผนที่ แตะรถ กด ดูเส้นทาง และวิเคราะห์ จะเห็นเส้นทางทั้งวัน ระยะทาง ความเร็ว และเวลาจอด"
)

# ── 4. ค่าใช้จ่ายและ AI ───────────────────────────────────────────
story += section("ค่าใช้จ่ายและ AI")
story += qa(
    "บันทึกค่าใช้จ่ายอย่างไร?",
    "หน้าหลัก กด บันทึกค่าใช้จ่าย เลือกรถ เลือกประเภท (น้ำมัน / ซ่อม / ยาง / อื่นๆ) กรอกจำนวนเงิน กด บันทึก"
)
story += qa(
    "AI สรุปให้ทุกวันไหม?",
    "ใช่ หน้า Dashboard แสดงสรุป AI ภาษาไทยทุกวัน บอกยอดค่าใช้จ่าย เปรียบเทียบกับเมื่อวาน และแนะนำการประหยัด"
)
story += qa(
    "ส่งสรุปไป LINE ได้ไหม?",
    "ได้ กดปุ่ม ส่งสรุปไป LINE ในแอป หรือตั้งค่า LINE Notify ให้ส่งอัตโนมัติทุกวัน"
)

# ── 5. ความปลอดภัย ────────────────────────────────────────────────
story += section("ความปลอดภัย")
story += qa(
    "ข้อมูล GPS ปลอดภัยไหม?",
    "ปลอดภัย ข้อมูลเข้ารหัส SSL/TLS และแต่ละบริษัทเห็นข้อมูลของตัวเองเท่านั้น ไม่มีการแชร์ข้ามบริษัท"
)
story += qa(
    "คนขับต้องยินยอมก่อนไหม?",
    "ใช่ เจ้าของต้องแจ้งและขอความยินยอมจากคนขับก่อนเปิดการติดตาม GPS ตามกฎหมาย PDPA ไทย"
)

# ── 6. ติดต่อและสนับสนุน ──────────────────────────────────────────
story += section("ติดต่อและสนับสนุน")
story += qa(
    "ติดต่อได้ช่องทางไหน?",
    "LINE Official Account: @655jmtme ทีมงานตอบกลับภายใน 24 ชั่วโมง วันจันทร์-เสาร์"
)
story += qa(
    "มีปัญหาใช้งานทำอย่างไร?",
    "ส่งข้อความมาที่ LINE @655jmtme พร้อมอธิบายปัญหา ทีมงานจะช่วยแก้ไขให้โดยเร็ว"
)
story += qa(
    "นโยบายความเป็นส่วนตัวดูได้ที่ไหน?",
    "rnai-io.github.io/H2Hfleet/privacy-policy.html และ rnai-io.github.io/H2Hfleet/terms-of-service.html"
)

# Footer
story.append(Spacer(1, 16))
story.append(HRFlowable(width="100%", thickness=1, color=BORDER))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "H2HFleet  |  LINE: @655jmtme  |  เอกสารอ้างอิงสำหรับ LINE AI Auto-reply",
    footer_style
))

doc.build(story)
print("PDF created: H2HFleet_LINE_Reference.pdf")
