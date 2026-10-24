"""Writes MONETIZATION.md (every game's passes + developer products with prices) and a 512x512
icon PNG per pass/product in monetization/icons/<Game>/, ready to upload in the Creator Dashboard."""
import json, os, re, hashlib, textwrap
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRY = re.compile(r'\{\s*Key = "(\w+)",\s*Name = "([^"]+)",\s*Price = (\d+),\s*Description = "([^"]+)"\s*\}')
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()

def icon(path, title, kind):
    h = hashlib.md5(title.encode()).digest()
    c1 = (60 + h[0] % 180, 60 + h[1] % 180, 60 + h[2] % 180)
    c2 = tuple(max(0, v - 70) for v in c1)
    img = Image.new("RGB", (512, 512), c2)
    d = ImageDraw.Draw(img)
    for r in range(256, 0, -4):  # radial-ish glow
        t = r / 256
        col = tuple(int(c1[i] * (1 - t) + c2[i] * t) for i in range(3))
        d.ellipse([256 - r, 256 - r, 256 + r, 256 + r], fill=col)
    d.rounded_rectangle([12, 12, 500, 500], radius=60, outline=(255, 255, 255), width=12)
    lines = textwrap.wrap(title.upper(), 10)[:3]
    size = 96 if max(len(l) for l in lines) <= 7 else 72
    f = font(size)
    y = 256 - len(lines) * (size + 8) / 2
    for line in lines:
        w = d.textlength(line, font=f)
        d.text((256 - w / 2, y), line, font=f, fill=(255, 255, 255), stroke_width=8, stroke_fill=(0, 0, 0))
        y += size + 8
    tag = "GAME PASS" if kind == "pass" else "PRODUCT"
    f2 = font(36)
    w = d.textlength(tag, font=f2)
    d.text((256 - w / 2, 440), tag, font=f2, fill=(255, 230, 120), stroke_width=4, stroke_fill=(0, 0, 0))
    img.save(path)

out = ["# Monetization setup (all games)", "",
       "Every game already has the code for these game passes and developer products. To turn them on:",
       "1. Publish the place (File > Publish to Roblox).",
       "2. Creator Dashboard > your experience > Monetization > **Passes**: create each pass below with its name, price,",
       "   description and the icon from `monetization/icons/<Game>/`.",
       "3. Monetization > **Developer Products**: create each product below the same way.",
       "4. Copy each new ID into the game's `ReplicatedStorage.Shared.Config` ModuleScript (in Studio) where it says `= 0`",
       "   (for example `VIP = 0` becomes `VIP = 123456789`), then publish again.",
       "", "Until an ID is filled in, the shop button still works in Studio test mode so you can try every item.", ""]
total = 0
for g in sorted(os.listdir(os.path.join(ROOT, "games"))):
    cfg = os.path.join(ROOT, "games", g, "src", "shared", "Config.luau")
    proj = os.path.join(ROOT, "games", g, "default.project.json")
    if not os.path.exists(cfg):
        continue
    name = json.load(open(proj))["name"]
    src = open(cfg).read()
    passes_block = src.split("Config.PassInfo", 1)[1].split("}\n", 1)[0] if "Config.PassInfo" in src else ""
    prod_block = src.split("Config.ProductInfo", 1)[1].split("}\n", 1)[0] if "Config.ProductInfo" in src else ""
    d = os.path.join(ROOT, "monetization", "icons", name)
    os.makedirs(d, exist_ok=True)
    out += [f"## {name}  (`build/{name}.rbxlx`)", "", "| Type | Name | Price (R$) | Description | Config key | Icon |", "|---|---|---|---|---|---|"]
    for kind, block in (("pass", passes_block), ("product", prod_block)):
        for key, title, price, desc in ENTRY.findall(block):
            icon(os.path.join(d, f"{key}.png"), title, kind)
            label = "Game Pass" if kind == "pass" else "Dev Product"
            out.append(f"| {label} | {title} | {price} | {desc} | `{key}` | `monetization/icons/{name}/{key}.png` |")
            total += 1
    out.append("")
open(os.path.join(ROOT, "MONETIZATION.md"), "w").write("\n".join(out))
print("items:", total)
