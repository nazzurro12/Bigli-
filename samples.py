import json

with open('df_mode/data/creatures.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Show first 10 entries
for c in data[:10]:
    print(f'id={c["id"]}: name={c["name"]}, desc={c["description"][:60]}')
