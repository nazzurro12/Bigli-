import json

# Test the translate_name function
def translate_name(name):
    if not name:
        return name
    lower = name.lower()
    
    if lower.endswith(" man"):
        base = name[:-4]
        print(f"    man pattern: base={repr(base)}")
        return name
    if lower.endswith(" woman"):
        base = name[:-6]
        print(f"    woman pattern: base={repr(base)}")
        return name
    
    if lower.startswith("giant "):
        base = name[6:]
        print(f"    giant pattern: base={repr(base)}")
        return name
    
    return name

# Test specific cases
tests = ["Giant toad", "Toad man", "Toad woman", "Dwarf", "Fox", "Giant eagle"]
for t in tests:
    result = translate_name(t)
    print(f"{t} -> {result}")

# Check material names
with open('df_mode/data/materials.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
print(f'\nFirst 5 materials:')
for m in data[:5]:
    print(f'  id={m["id"]}, name={repr(m["name"])}')
