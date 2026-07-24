import json, os

DATA_DIR = "df_mode/data"

files = ["creatures.json", "materials.json", "plants.json", "items.json", "colors.json", "texts.json"]
for fname in files:
    path = os.path.join(DATA_DIR, fname)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    if isinstance(data, list):
        total = len(data)
        translated = 0
        desc_translated = 0
        for entry in data:
            if isinstance(entry, dict):
                n = entry.get("name", "")
                if n and any(ord(c) > 127 for c in n):
                    translated += 1
                d = entry.get("description", "")
                if d and any(ord(c) > 127 for c in d):
                    desc_translated += 1
                if "lines" in entry:
                    lines = entry.get("lines", [])
                    if lines and any(any(ord(c) > 127 for c in l) for l in lines):
                        translated += 1
        
        print(f"{fname}:", flush=True)
        print(f"  Nombres: {translated}/{total} traducidos", flush=True)
        if desc_translated > 0:
            print(f"  Descripciones: {desc_translated}/{total} traducidas", flush=True)
        
        # Show first untranslated sample
        for entry in data:
            if isinstance(entry, dict):
                n = entry.get("name", "")
                if n and not any(ord(c) > 127 for c in n):
                    print(f"  Primer nombre sin traducir: {n[:40]}", flush=True)
                    break
