from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

ROOT = Path(r"C:\Users\Uriel\Documents\GitHub\proyecto-lazaro")
OUT = ROOT / "output"
PNG_DIR = OUT / "imagegen"
PDF_DIR = OUT / "pdf"
PNG_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(parents=True, exist_ok=True)

W, H = 2480, 3508  # A4 at 300 DPI
NAVY = "#063B42"
TEAL = "#0A6D73"
GOLD = "#F5B623"
INK = "#102A30"
PAPER = "#FCFCF7"
FONT_BOLD = ROOT / "Art/Fonts/Dekatron-SemiBold.otf"
FONT_REG = ROOT / "Art/Fonts/Exo2-Regular.otf"
ASSETS = {
    "head": Path(r"C:\Users\Uriel\Desktop\5caeeac4-d692-4b0a-ae22-a2d10b8bf3ee.jpg"),
    "hive": Path(r"C:\Users\Uriel\Desktop\511893fe-5328-41a4-bbe5-53818f2235e1.jpg"),
    "brain": Path(r"C:\Users\Uriel\Desktop\1f1918e3-0786-4f4c-ab3e-e9241af9cf91.jpg"),
    "pistol": Path(r"C:\Users\Uriel\Desktop\6ea0b945-98ea-4b7a-8aa3-c9cf5457c03e.jpg"),
    "result": Path(r"C:\Users\Uriel\Desktop\5c4ed417-5035-45dc-b20c-77fe75fd7399.jpg"),
    "logo": ROOT / "Art/Menu/FRANKEN-GUN_Logo2.png",
    "cerberus": Path(r"C:\Users\Uriel\Desktop\24bb103c-588b-4240-92b9-e70952605168.jpg"),
    "dog_head": Path(r"C:\Users\Uriel\Desktop\9372e55f-156a-4122-9cd2-7b8081d41ea8.jpg"),
    "shotgun": Path(r"C:\Users\Uriel\Desktop\307770f2-bd62-40a0-824f-5e0c2911fe44.jpg"),
    "uzi": Path(r"C:\Users\Uriel\Desktop\888af90d-46e0-4576-9844-1b5ff5409ec0.jpg"),
    "saw": Path(r"C:\Users\Uriel\Desktop\eb9ce1ab-879b-40a1-bd8e-78a27f883d27.jpg"),
    "mixer": Path(r"C:\Users\Uriel\Desktop\26fbf922-9577-4b43-b5fb-2463db6c638d.jpg"),
    "motorcycle": Path(r"C:\Users\Uriel\Desktop\92adfcc6-bbe1-4312-92b1-caae652f5e43.jpg"),
    "heavy_metal": Path(r"C:\Users\Uriel\Desktop\a457c46d-3e10-4707-a57b-dc1a5bc21543.jpg"),
}

def font(size, bold=True):
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REG), size)

def centered(draw, text, y, fnt, fill=INK):
    box = draw.textbbox((0, 0), text, font=fnt)
    draw.text(((W - (box[2] - box[0])) / 2, y), text, font=fnt, fill=fill)

def fit_image(canvas_img, source, box, margin=20):
    x, y, bw, bh = box
    img = Image.open(source).convert("RGB")
    img.thumbnail((bw - margin * 2, bh - margin * 2), Image.Resampling.NEAREST)
    px = x + (bw - img.width) // 2
    py = y + (bh - img.height) // 2
    canvas_img.paste(img, (px, py))

def logo(canvas_img):
    image = Image.open(ASSETS["logo"]).convert("RGBA")
    image.thumbnail((360, 210), Image.Resampling.LANCZOS)
    x = (W - image.width) // 2
    canvas_img.paste(image, (x, 35), image)

def arrow(draw, cy):
    draw.polygon([(W//2-42, cy), (W//2+42, cy), (W//2+42, cy+38), (W//2+83, cy+38), (W//2, cy+120), (W//2-83, cy+38), (W//2-42, cy+38)], fill=GOLD)

def header(image, draw, title):
    logo(image)
    centered(draw, title, 272, font(142), NAVY)
    draw.rectangle((140, 450, W-140, 463), fill=GOLD)

def frame(draw, xy, border=GOLD, width=12, fill="#FFFFFF"):
    draw.rounded_rectangle(xy, radius=30, fill=fill, outline=border, width=width)

def label(draw, text, y):
    centered(draw, text, y, font(54), NAVY)

def mind_hive():
    image = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(image)
    header(image, draw, "MENTE COLMENA")
    label(draw, "PISTOLA", 535)
    frame(draw, (520, 625, 1960, 1160), TEAL)
    fit_image(image, ASSETS["pistol"], (520, 625, 1440, 535), 45)
    arrow(draw, 1190)
    label(draw, "EQUIPÁ ESTOS 3 ÍTEMS", 1345)
    cards = [(185, 1460, 840, 2110), (915, 1460, 1570, 2110), (1645, 1460, 2300, 2110)]
    sources = [ASSETS["hive"], ASSETS["brain"], ASSETS["head"]]
    names = ["COLMENA", "CEREBRO", "CABEZA HUMANA"]
    for i, card in enumerate(cards):
        frame(draw, card)
        fit_image(image, sources[i], (card[0], card[1]+20, card[2]-card[0], 440), 20)
        centered_x = (card[0]+card[2])//2
        text_box = draw.textbbox((0, 0), names[i], font=font(40))
        draw.text((centered_x-(text_box[2]-text_box[0])/2, 2025), names[i], font=font(40), fill=NAVY)
    draw.text((850, 1740), "+", font=font(85), fill=TEAL)
    draw.text((1585, 1740), "+", font=font(85), fill=TEAL)
    arrow(draw, 2170)
    frame(draw, (160, 2330, 2320, 3340), GOLD, 18, "#FFF8E7")
    centered(draw, "SINERGIA ACTIVADA", 2400, font(65), NAVY)
    fit_image(image, ASSETS["result"], (360, 2500, 1760, 520), 25)
    centered(draw, "MENTE COLMENA", 3065, font(120), NAVY)
    image.save(PNG_DIR / "mente-colmena-a4.png", dpi=(300, 300))
    return image

def cerberus():
    image = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(image)
    header(image, draw, "CERBERUS")
    label(draw, "ESCOPETA", 535)
    frame(draw, (520, 625, 1960, 1160), TEAL)
    fit_image(image, ASSETS["shotgun"], (520, 625, 1440, 535), 45)
    arrow(draw, 1190)
    label(draw, "EQUIPÁ 3 CABEZAS DE PERRO", 1345)
    cards = [(185, 1460, 840, 2110), (915, 1460, 1570, 2110), (1645, 1460, 2300, 2110)]
    for i, card in enumerate(cards):
        frame(draw, card)
        fit_image(image, ASSETS["dog_head"], (card[0], card[1]+20, card[2]-card[0], 440), 20)
        title = "CABEZA DE PERRO"
        text_box = draw.textbbox((0, 0), title, font=font(34))
        draw.text(((card[0]+card[2]-(text_box[2]-text_box[0]))/2, 2025), title, font=font(34), fill=NAVY)
    draw.text((850, 1740), "+", font=font(85), fill=TEAL)
    draw.text((1585, 1740), "+", font=font(85), fill=TEAL)
    arrow(draw, 2170)
    frame(draw, (160, 2330, 2320, 3340), GOLD, 18, "#FFF8E7")
    centered(draw, "SINERGIA ACTIVADA", 2400, font(65), NAVY)
    fit_image(image, ASSETS["cerberus"], (360, 2500, 1760, 520), 25)
    centered(draw, "CERBERUS", 3065, font(120), NAVY)
    image.save(PNG_DIR / "cerberus-a4.png", dpi=(300, 300))
    return image

def heavy_metal():
    image = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(image)
    header(image, draw, "HEAVY METAL")
    label(draw, "UZI", 535)
    frame(draw, (520, 625, 1960, 1160), TEAL)
    fit_image(image, ASSETS["uzi"], (520, 625, 1440, 535), 45)
    arrow(draw, 1190)
    label(draw, "EQUIPÁ ESTOS 3 ÍTEMS", 1345)
    cards = [(185, 1460, 840, 2110), (915, 1460, 1570, 2110), (1645, 1460, 2300, 2110)]
    sources = [ASSETS["saw"], ASSETS["mixer"], ASSETS["motorcycle"]]
    names = ["SIERRA CIRCULAR", "MEZCLADORA", "MOTOCICLETA"]
    for i, card in enumerate(cards):
        frame(draw, card)
        fit_image(image, sources[i], (card[0], card[1]+20, card[2]-card[0], 440), 20)
        text_box = draw.textbbox((0, 0), names[i], font=font(34))
        draw.text(((card[0]+card[2]-(text_box[2]-text_box[0]))/2, 2025), names[i], font=font(34), fill=NAVY)
    draw.text((850, 1740), "+", font=font(85), fill=TEAL)
    draw.text((1585, 1740), "+", font=font(85), fill=TEAL)
    arrow(draw, 2170)
    frame(draw, (160, 2330, 2320, 3340), GOLD, 18, "#FFF8E7")
    centered(draw, "SINERGIA ACTIVADA", 2400, font(65), NAVY)
    fit_image(image, ASSETS["heavy_metal"], (360, 2500, 1760, 520), 25)
    centered(draw, "HEAVY METAL", 3065, font(120), NAVY)
    image.save(PNG_DIR / "heavy-metal-a4.png", dpi=(300, 300))
    return image

def generic_template():
    image = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(image)
    logo(image)
    centered(draw, "NOMBRE DE", 278, font(104), NAVY)
    centered(draw, "SINERGIA", 405, font(104), NAVY)
    draw.rectangle((140, 550, W-140, 563), fill=GOLD)
    label(draw, "ARMA", 635)
    frame(draw, (520, 710, 1960, 1190), TEAL)
    centered(draw, "ILUSTRACIÓN DEL ARMA", 885, font(50), "#7C8D90")
    arrow(draw, 1220)
    label(draw, "3 ÍTEMS", 1375)
    cards = [(185, 1490, 840, 2140), (915, 1490, 1570, 2140), (1645, 1490, 2300, 2140)]
    for i, card in enumerate(cards):
        frame(draw, card)
        centered(draw, "", 0, font(1))
        text = f"ÍTEM {i+1}"
        box = draw.textbbox((0, 0), text, font=font(48))
        draw.text(((card[0]+card[2]-(box[2]-box[0]))/2, 1770), text, font=font(48), fill="#7C8D90")
    draw.text((850, 1770), "+", font=font(85), fill=TEAL)
    draw.text((1585, 1770), "+", font=font(85), fill=TEAL)
    arrow(draw, 2200)
    frame(draw, (160, 2360, 2320, 3340), GOLD, 18, "#FFF8E7")
    centered(draw, "SINERGIA ACTIVADA", 2430, font(65), NAVY)
    centered(draw, "ILUSTRACIÓN FINAL", 2730, font(55), "#7C8D90")
    centered(draw, "NOMBRE DE SINERGIA", 3070, font(82), NAVY)
    image.save(PNG_DIR / "plantilla-sinergias-a4.png", dpi=(300, 300))
    return image

mind = mind_hive()
cerberus_poster = cerberus()
heavy_metal_poster = heavy_metal()
template = generic_template()
pdf = canvas.Canvas(str(PDF_DIR / "guia-y-plantilla-sinergias-a4.pdf"), pagesize=(595.276, 841.890))
for page in [mind, cerberus_poster, heavy_metal_poster, template]:
    pdf.drawImage(ImageReader(page), 0, 0, width=595.276, height=841.890)
    pdf.showPage()
pdf.save()
