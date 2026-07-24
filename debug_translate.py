import json, os, sys

# Quick check of current state
with open('df_mode/data/creatures.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Check DWARF
for c in data:
    if c['id'] == 'DWARF':
        print(f'DWARF name: {repr(c["name"])}')
        print(f'DWARF desc: {repr(c["description"][:80])}')
        break

# Count untranslated descriptions
untranslated = 0
for c in data:
    d = c.get('description', '')
    if d and not any(ord(ch) > 127 for ch in d):
        untranslated += 1

print(f'\nUntranslated descriptions: {untranslated}')

# Count translated names
translated_names = 0
for c in data:
    n = c.get('name', '')
    if n and any(ord(ch) > 127 for ch in n):
        translated_names += 1

print(f'Translated names: {translated_names}')

# Try a single translate call
print('\nTesting translate...')
sys.stdout.flush()
from deep_translator import GoogleTranslator
t = GoogleTranslator(source='en', target='es')
test = t.translate("A short, sturdy creature fond of drink and industry.")
print(f'Test translate: {test}')
sys.stdout.flush()
