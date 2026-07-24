import json, os, sys, time
from deep_translator import GoogleTranslator

DATA_DIR = "df_mode/data"
t = GoogleTranslator(source="en", target="es")

def translate_desc(text):
    if not text or text.strip() == "":
        return text
    if any(ord(c) > 127 for c in text):
        return text
    try:
        r = t.translate(text)
        time.sleep(0.02)
        return r
    except:
        return text

# Check what's still untranslated in creatures
path = os.path.join(DATA_DIR, "creatures.json")
with open(path, "r", encoding="utf-8") as f:
    creatures = json.load(f)

remaining = [(i, c) for i, c in enumerate(creatures) if not any(ord(ch) > 127 for ch in c.get("description", ""))]
print(f"Criaturas con descripcion sin traducir: {len(remaining)}", flush=True)

# Translate remaining descriptions only
for idx, (pos, c) in enumerate(remaining):
    c["description"] = translate_desc(c.get("description", ""))
    if (idx+1) % 20 == 0:
        print(f"  desc {idx+1}/{len(remaining)}", flush=True)

with open(path, "w", encoding="utf-8") as f:
    json.dump(creatures, f, indent=4, ensure_ascii=False)

# Now check materials
path = os.path.join(DATA_DIR, "materials.json")
with open(path, "r", encoding="utf-8") as f:
    mats = json.load(f)

remaining_mats = [m for m in mats if not any(ord(ch) > 127 for ch in m.get("name", ""))]
print(f"\nMateriales sin traducir: {len(remaining_mats)}", flush=True)
for m in remaining_mats:
    m["name"] = translate_desc(m.get("name", ""))

with open(path, "w", encoding="utf-8") as f:
    json.dump(mats, f, indent=4, ensure_ascii=False)

# Check plants
path = os.path.join(DATA_DIR, "plants.json")
with open(path, "r", encoding="utf-8") as f:
    plants = json.load(f)

remaining_plants = [p for p in plants if not any(ord(ch) > 127 for ch in p.get("name", ""))]
print(f"Plantas sin traducir: {len(remaining_plants)}", flush=True)
for p in remaining_plants:
    p["name"] = translate_desc(p.get("name", ""))

with open(path, "w", encoding="utf-8") as f:
    json.dump(plants, f, indent=4, ensure_ascii=False)

# Check items
path = os.path.join(DATA_DIR, "items.json")
with open(path, "r", encoding="utf-8") as f:
    items = json.load(f)

remaining_items = [it for it in items if not any(ord(ch) > 127 for ch in it.get("name", ""))]
print(f"Items sin traducir: {len(remaining_items)}", flush=True)
for it in remaining_items:
    it["name"] = translate_desc(it.get("name", ""))

with open(path, "w", encoding="utf-8") as f:
    json.dump(items, f, indent=4, ensure_ascii=False)

# Check colors
path = os.path.join(DATA_DIR, "colors.json")
with open(path, "r", encoding="utf-8") as f:
    colors = json.load(f)

remaining_colors = [c for c in colors if not any(ord(ch) > 127 for ch in c.get("name", ""))]
print(f"Colores sin traducir: {len(remaining_colors)}", flush=True)
for c in remaining_colors:
    c["name"] = translate_desc(c.get("name", ""))

with open(path, "w", encoding="utf-8") as f:
    json.dump(colors, f, indent=4, ensure_ascii=False)

# Check texts
path = os.path.join(DATA_DIR, "texts.json")
with open(path, "r", encoding="utf-8") as f:
    texts = json.load(f)

total_lines = sum(1 for t in texts for l in t.get("lines", []))
remaining_lines = 0
for t in texts:
    new_lines = []
    for l in t.get("lines", []):
        if l and not any(ord(ch) > 127 for ch in l):
            new_lines.append(translate_desc(l))
            remaining_lines += 1
        else:
            new_lines.append(l)
    t["lines"] = new_lines
print(f"Lineas de texto sin traducir: {remaining_lines}", flush=True)

with open(path, "w", encoding="utf-8") as f:
    json.dump(texts, f, indent=4, ensure_ascii=False)

print("\n\u2705 TODO TRADUCIDO", flush=True)
