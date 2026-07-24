import json
import os
import re
import time
from deep_translator import GoogleTranslator

DATA_DIR = "df_mode/data"

translator = GoogleTranslator(source="en", target="es")

# === COMPREHENSIVE TRANSLATION DICTIONARY ===
DICT = {
    "Dwarf": "Enano", "dwarf": "enano", "DWARF": "ENANO",
    "Elf": "Elfo", "elf": "elfo", "ELF": "ELFO",
    "Human": "Humano", "human": "humano",
    "Goblin": "Trasgo", "goblin": "trasgo",
    "Kobold": "Kobold", "kobold": "kobold",
    "Dwarf baby": "Bebe enano",
    "Dwarf children": "Ninos enanos",
    "Troll": "Trol", "troll": "trol",
    "Ogre": "Ogro", "ogre": "ogro",
    "Dragon": "Drag\u00f3n", "dragon": "drag\u00f3n", "DRAGON": "DRAGON",
    "Giant": "Gigante", "giant": "gigante",
    "Cyclops": "C\u00edclope",
    "Minotaur": "Minotauro",
    "Hydra": "Hidra",
    "Harpy": "Arp\u00eda",
    "Unicorn": "Unicornio",
    "Griffin": "Grifo",
    "Fairy": "Hada", "FAIRY": "HADA",
    "Pixie": "Pixie", "PIXIE": "PIXIE",
    "Phoenix": "F\u00e9nix",
    "Behemoth": "Behemot",
    "Satyr": "S\u00e1tiro",
    "Yeti": "Yeti",
    "Merperson": "Hombre-pez",
    "Gremlin": "Gremlin",
    "Nightwing": "Ala nocturna",
    "Strangler": "Estrangulador",
    "Beak dog": "Perro pico",
    "Blizzard man": "Hombre ventisca",
    "Ettin": "Ettin",
    "Foul blendec": "Blendec inmundo",
    "Grimeling": "Grimeling",
    "Rock": "Roca", "bird": "p\u00e1jaro", "roc": "roc",
    "Magma": "Magma", "magma": "magma",
    " man": " hombre", "MAN": "HOMBRE",
    " woman": " mujer", "WOMAN": "MUJER",
    "Toad": "Sapo", "Fox": "Zorro", "Wolf": "Lobo", "WOLF": "LOBO",
    "Bear": "Oso", "Deer": "Ciervo", "Rabbit": "Conejo",
    "Hare": "Liebre", "Squirrel": "Ardilla", "Rat": "Rata",
    "Bat": "Murci\u00e9lago", "BAT": "MURCIELAGO",
    "Crow": "Cuervo", "Raven": "Cuervo", "Eagle": "\u00c1guila",
    "Hawk": "Halc\u00f3n", "Owl": "B\u00faho", "Parrot": "Loro",
    "Bluejay": "Arrendajo", "Cardinal": "Cardenal", "Finch": "Pinz\u00f3n",
    "Sparrow": "Gorri\u00f3n", "Swallow": "Golondrina", "Duck": "Pato",
    "Goose": "Ganso", "Swan": "Cisne", "Heron": "Garza",
    "Crane": "Grulla", "Stork": "Cig\u00fce\u00f1a", "Pelican": "Pel\u00edcano",
    "Seagull": "Gaviota", "Penguin": "Ping\u00fcino", "PENGUIN": "PINGUINO",
    "Turkey": "Pavo", "Chicken": "Gallina", "Rooster": "Gallo",
    "Peacock": "Pavo real", "Ostrich": "Avestruz",
    "Snake": "Serpiente", "Worm": "Gusano", "WORM": "GUSANO",
    "Lizard": "Lagarto", "Skink": "Esliz\u00f3n", "Chameleon": "Camale\u00f3n",
    "Turtle": "Tortuga", "Crocodile": "Cocodrilo", "Alligator": "Caim\u00e1n",
    "Frog": "Rana", "Salamander": "Salamandra", "Newt": "Trit\u00f3n",
    "Fish": "Pez", "Trout": "Trucha", "Salmon": "Salm\u00f3n",
    "Cod": "Bacalao", "Perch": "Perca", "Bass": "Lubina",
    "Carp": "Carpa", "Catfish": "Bagre", "Pike": "Lucio",
    "Eel": "Anguila", "Shark": "Tibur\u00f3n", "SHARK": "TIBURON",
    "Whale": "Ballena", "Dolphin": "Delf\u00edn", "Porpoise": "Marsopa",
    "Octopus": "Pulpo", "Squid": "Calamar",
    "Crab": "Cangrejo", "CRAB": "CANGREJO", "Lobster": "Langosta",
    "Shrimp": "Camar\u00f3n", "Oyster": "Ostra", "Clam": "Almeja",
    "Mussel": "Mejill\u00f3n", "Snail": "Caracol",
    "Scorpion": "Escorpi\u00f3n", "SCORPION": "ESCORPION",
    "Spider": "Ara\u00f1a", "SPIDER": "ARANIA",
    "Ant": "Hormiga", "ANT": "HORMIGA", "Bee": "Abeja",
    "Wasp": "Avispa", "Fly": "Mosca", "Mosquito": "Mosquito",
    "Moth": "Polilla", "Butterfly": "Mariposa",
    "Dragonfly": "Lib\u00e9lula", "DAMSELFLY": "LIBELULA",
    "Grasshopper": "Saltamontes", "Cricket": "Grillo",
    "Beetle": "Escarabajo", "Ladybug": "Mariquita",
    "Firefly": "Luci\u00e9rnaga", "Locust": "Langosta",
    "Centipede": "Ciempi\u00e9s", "Millipede": "Milpi\u00e9s",
    "Slug": "Babosa", "Leech": "Sanguijuela",
    "Jellyfish": "Medusa", "Starfish": "Estrella de mar",
    "Anemone": "An\u00e9mona",
    "Horse": "Caballo", "Pony": "Poni", "Donkey": "Burro", "Mule": "Mulo",
    "Cow": "Vaca", "Bull": "Toro", "Calf": "Ternero",
    "Goat": "Cabra", "Sheep": "Oveja", "Ram": "Carnero", "Lamb": "Cordero",
    "Pig": "Cerdo", "Hog": "Cerdo", "Boar": "Jabal\u00ed",
    "Dog": "Perro", "DOG": "PERRO", "Hound": "Sabueso", "Puppy": "Cachorro",
    "Cat": "Gato", "Kitten": "Gatito",
    "Lion": "Le\u00f3n", "Tiger": "Tigre", "Panther": "Pantera",
    "Leopard": "Leopardo", "Cheetah": "Guepardo", "Jaguar": "Jaguar",
    "Hyena": "Hiena", "Elephant": "Elefante",
    "Rhinoceros": "Rinoceronte", "Hippopotamus": "Hipop\u00f3tamo",
    "Giraffe": "Jirafa", "Zebra": "Cebra", "Camel": "Camello",
    "Llama": "Llama", "Monkey": "Mono", "Ape": "Simio",
    "Gorilla": "Gorila", "Chimpanzee": "Chimpanc\u00e9",
    "Orangutan": "Orangut\u00e1n", "Baboon": "Mandril",
    "Lemur": "L\u00e9mur", "Sloth": "Perezoso",
    "Armadillo": "Armadillo", "Porcupine": "Puercoesp\u00edn",
    "Skunk": "Mofeta", "Raccoon": "Mapache", "Badger": "Tej\u00f3n",
    "Otter": "Nutria", "Beaver": "Castor", "Mole": "Topo",
    "Hedgehog": "Erizo", "Shrew": "Musara\u00f1a",
    "Mouse": "Rat\u00f3n", "Vole": "Campo\u00f1ol",
    "Weasel": "Comadreja", "Ferret": "Huron",
    "Mongoose": "Mangosta", "Meerkat": "Suricata",
    "Kangaroo": "Canguro", "Wallaby": "Ualab\u00ed",
    "Koala": "Koala", "Platypus": "Ornitorrinco",
    "Wombat": "Uombat",
    "Tasmanian devil": "Demonio de Tasmania",
    "Moose": "Alce", "Elk": "Uapit\u00ed", "Bison": "B\u00edsonte",
    "Buffalo": "B\u00fafalo", "Antelope": "Ant\u00edlope",
    "Gazelle": "Gacela", "Impala": "Impala",
    "Wildebeest": "\u00d1u", "Zebra": "Cebra",
    "Gnu": "\u00d1u", "Okapi": "Okapi",
    "Warthog": "Jabal\u00ed verrugoso",
    "Tapir": "Tapir", "Capybara": "Capibara",
    "Agouti": "Agut\u00ed", "Marmoset": "Tit\u00ed",
    "Howler monkey": "Mono aullador",
    "Spider monkey": "Mono ara\u00f1a",
    "Saki monkey": "Saki",
}

# Multi-word names that need special handling
MULTI_WORD = {
    "giant toad": "sapo gigante",
    "giant fox": "zorro gigante",
    "giant wolf": "lobo gigante",
    "giant bear": "oso gigante",
    "giant deer": "ciervo gigante",
    "giant rabbit": "conejo gigante",
    "giant hare": "liebre gigante",
    "giant squirrel": "ardilla gigante",
    "giant rat": "rata gigante",
    "giant bat": "murci\u00e9lago gigante",
    "giant crow": "cuervo gigante",
    "giant raven": "cuervo gigante",
    "giant eagle": "\u00e1guila gigante",
    "giant hawk": "halc\u00f3n gigante",
    "giant owl": "b\u00faho gigante",
    "giant parrot": "loro gigante",
    "giant bluejay": "arrendajo gigante",
    "giant cardinal": "cardenal gigante",
    "giant finch": "pinz\u00f3n gigante",
    "giant sparrow": "gorri\u00f3n gigante",
    "giant swallow": "golondrina gigante",
    "giant duck": "pato gigante",
    "giant goose": "ganso gigante",
    "giant swan": "cisne gigante",
    "giant heron": "garza gigante",
    "giant crane": "grulla gigante",
    "giant stork": "cig\u00fce\u00f1a gigante",
    "giant pelican": "pel\u00edcano gigante",
    "giant seagull": "gaviota gigante",
    "giant penguin": "ping\u00fcino gigante",
    "giant turkey": "pavo gigante",
    "giant chicken": "gallina gigante",
    "giant snake": "serpiente gigante",
    "giant worm": "gusano gigante",
    "giant lizard": "lagarto gigante",
    "giant turtle": "tortuga gigante",
    "giant frog": "rana gigante",
    "giant salamander": "salamandra gigante",
    "giant fish": "pez gigante",
    "giant crab": "cangrejo gigante",
    "giant lobster": "langosta gigante",
    "giant scorpion": "escorpi\u00f3n gigante",
    "giant spider": "ara\u00f1a gigante",
    "giant ant": "hormiga gigante",
    "giant bee": "abeja gigante",
    "giant wasp": "avispa gigante",
    "giant fly": "mosca gigante",
    "giant mosquito": "mosquito gigante",
    "giant moth": "polilla gigante",
    "giant butterfly": "mariposa gigante",
    "giant dragonfly": "lib\u00e9lula gigante",
    "giant grasshopper": "saltamontes gigante",
    "giant cricket": "grillo gigante",
    "giant beetle": "escarabajo gigante",
    "giant snail": "caracol gigante",
    "giant leech": "sanguijuela gigante",
    "giant jellyfish": "medusa gigante",
    "giant starfish": "estrella de mar gigante",
    "giant anemone": "an\u00e9mona gigante",
    "giant slug": "babosa gigante",
    "giant tortoise": "tortuga gigante",
    "giant toad": "sapo gigante",
    "giant capybara": "capibara gigante",
    "giant skink": "esliz\u00f3n gigante",
    "giant chameleon": "camale\u00f3n gigante",
    "giant armadillo": "armadillo gigante",
    "giant porcupine": "puercoesp\u00edn gigante",
    "giant skunk": "mofeta gigante",
    "giant raccoon": "mapache gigante",
    "giant badger": "tej\u00f3n gigante",
    "giant otter": "nutria gigante",
    "giant beaver": "castor gigante",
    "giant mole": "topo gigante",
    "giant hedgehog": "erizo gigante",
    "giant shrew": "musara\u00f1a gigante",
    "giant mouse": "rat\u00f3n gigante",
    "giant vole": "campo\u00f1ol gigante",
    "giant weasel": "comadreja gigante",
    "giant ferret": "hur\u00f3n gigante",
    "giant mongoose": "mangosta gigante",
    "giant meerkat": "suricata gigante",
    "giant kangaroo": "canguro gigante",
    "giant wallaby": "ualab\u00ed gigante",
    "giant koala": "koala gigante",
    "giant platypus": "ornitorrinco gigante",
    "giant wombat": "uombat gigante",
    "giant moose": "alce gigante",
    "giant elk": "uapit\u00ed gigante",
    "giant bison": "b\u00edsonte gigante",
    "giant antelope": "ant\u00edlope gigante",
    "giant gazelle": "gacela gigante",
    "giant wildebeest": "\u00f1u gigante",
    "giant zebra": "cebra gigante",
    "giant okapi": "okapi gigante",
    "giant tapir": "tapir gigante",
    "giant agouti": "agut\u00ed gigante",
    "giant warthog": "jabal\u00ed verrugoso gigante",
}

def translate_name(name: str) -> str:
    """Translate a name using dictionary with pattern matching."""
    if not name:
        return name
    
    lower = name.lower().strip()
    
    # Check multi-word dict
    if lower in MULTI_WORD:
        result = MULTI_WORD[lower]
        if name[0].isupper():
            return result[0].upper() + result[1:]
        return result
    
    # Check exact match
    if name in DICT:
        return DICT[name]
    if lower in DICT:
        return DICT[lower]
    
    # Handle "X man" / "X woman" pattern
    if lower.endswith(" man"):
        base = lower[:-4]
        translated_base = translate_name(base)
        if translated_base != base:
            if name[0].isupper():
                return "Hombre " + translated_base[0].upper() + translated_base[1:]
            return "hombre " + translated_base
    if lower.endswith(" woman"):
        base = lower[:-6]
        translated_base = translate_name(base)
        if translated_base != base:
            if name[0].isupper():
                return "Mujer " + translated_base[0].upper() + translated_base[1:]
            return "mujer " + translated_base
    
    # Handle "Giant X" pattern
    if lower.startswith("giant "):
        base = lower[6:]
        translated_base = translate_name(base)
        if translated_base != base:
            if name[0].isupper():
                return translated_base[0].upper() + translated_base[1:] + " gigante"
            return translated_base + " gigante"
    
    # Handle "Little X" pattern
    if lower.startswith("little "):
        base = lower[7:]
        translated_base = translate_name(base)
        if translated_base != base:
            if name[0].isupper():
                return "Peque\u00f1o " + translated_base[0].upper() + translated_base[1:]
            return "peque\u00f1o " + translated_base
    
    # Word-by-word fallback
    parts = name.split(" ")
    translated_parts = []
    for p in parts:
        if p in DICT:
            translated_parts.append(DICT[p])
        elif p.lower() in DICT:
            tp = DICT[p.lower()]
            if p[0].isupper():
                tp = tp[0].upper() + tp[1:]
            translated_parts.append(tp)
        else:
            translated_parts.append(p)
    
    result = " ".join(translated_parts)
    return result


def translate_description(text: str) -> str:
    """Translate full description sentences using Google Translate."""
    if not text or text.strip() == "":
        return text
    if any(ord(c) > 127 for c in text):
        return text  # Already translated
    try:
        result = translator.translate(text)
        time.sleep(0.03)
        return result
    except Exception as e:
        print(f"  Error: {e}")
        return text


def process_file(fname: str, name_fields: list, desc_fields: list = None):
    path = os.path.join(DATA_DIR, fname)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    name_count = 0
    desc_count = 0
    
    if isinstance(data, list):
        for entry in data:
            if isinstance(entry, dict):
                for key in name_fields:
                    if key in entry and entry[key]:
                        old = entry[key]
                        new = translate_name(old)
                        if new != old:
                            entry[key] = new
                            name_count += 1
                if desc_fields:
                    for key in desc_fields:
                        if key in entry and entry[key]:
                            old = entry[key]
                            if not any(ord(c) > 127 for c in old):
                                new = translate_description(old)
                                if new != old:
                                    entry[key] = new
                                    desc_count += 1
                if "caste_names" in entry:
                    entry["caste_names"] = [translate_name(n) for n in entry["caste_names"]]
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    
    print(f"{fname}: {name_count} names, {desc_count} descriptions")
    return name_count, desc_count


def main():
    print("=== Translating DF data to Spanish ===\n")
    
    process_file("creatures.json", ["name"], ["description"])
    process_file("materials.json", ["name"])
    process_file("plants.json", ["name"])
    process_file("items.json", ["name"])
    process_file("colors.json", ["name"])
    
    # Texts - use dictionary + google translate
    path = os.path.join(DATA_DIR, "texts.json")
    with open(path, "r", encoding="utf-8") as f:
        texts = json.load(f)
    count = 0
    for t in texts:
        new_lines = []
        for line in t.get("lines", []):
            new_line = translate_name(line)
            if new_line == line:
                new_line = translate_description(line)
            if new_line != line:
                count += 1
            new_lines.append(new_line)
        t["lines"] = new_lines
    with open(path, "w", encoding="utf-8") as f:
        json.dump(texts, f, indent=4, ensure_ascii=False)
    print(f"texts.json: {count} translated")
    
    print("\n=== Translation complete! ===")

if __name__ == "__main__":
    main()
