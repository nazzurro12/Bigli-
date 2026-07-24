import json, os

DATA_DIR = "df_mode/data"

DICT = {
    "Dwarf": "Enano", "dwarf": "enano",
    "Elf": "Elfo", "elf": "elfo",
    "Human": "Humano", "human": "humano",
    "Goblin": "Trasgo", "goblin": "trasgo",
    "Kobold": "Kobold", "kobold": "kobold",
    "Troll": "Trol", "troll": "trol",
    "Ogre": "Ogro", "ogre": "ogro",
    "Dragon": "Drag\u00f3n", "dragon": "drag\u00f3n",
    "Giant": "Gigante", "giant": "gigante",
    "Cyclops": "C\u00edclope", "Minotaur": "Minotauro",
    "Hydra": "Hidra", "Harpy": "Arp\u00eda",
    "Unicorn": "Unicornio", "Griffin": "Grifo",
    "Fairy": "Hada", "Pixie": "Pixie",
    "Phoenix": "F\u00e9nix", "Behemoth": "Behemot",
    "Satyr": "S\u00e1tiro", "Yeti": "Yeti",
    "Merperson": "Hombre-pez",
    "Gremlin": "Gremlin", "Nightwing": "Ala nocturna",
    "Strangler": "Estrangulador",
    "Beak dog": "Perro pico",
    "Blizzard man": "Hombre ventisca",
    "Toad": "Sapo", "Fox": "Zorro", "Wolf": "Lobo",
    "Bear": "Oso", "Deer": "Ciervo", "Rabbit": "Conejo",
    "Hare": "Liebre", "Squirrel": "Ardilla", "Rat": "Rata",
    "Bat": "Murci\u00e9lago", "Crow": "Cuervo", "Raven": "Cuervo",
    "Eagle": "\u00c1guila", "Hawk": "Halc\u00f3n", "Owl": "B\u00faho",
    "Parrot": "Loro", "Bluejay": "Arrendajo", "Cardinal": "Cardenal",
    "Finch": "Pinz\u00f3n", "Sparrow": "Gorri\u00f3n", "Swallow": "Golondrina",
    "Duck": "Pato", "Goose": "Ganso", "Swan": "Cisne",
    "Heron": "Garza", "Crane": "Grulla", "Stork": "Cig\u00fce\u00f1a",
    "Pelican": "Pel\u00edcano", "Seagull": "Gaviota",
    "Penguin": "Ping\u00fcino",
    "Turkey": "Pavo", "Chicken": "Gallina", "Rooster": "Gallo",
    "Peacock": "Pavo real", "Ostrich": "Avestruz",
    "Snake": "Serpiente", "Worm": "Gusano",
    "Lizard": "Lagarto", "Skink": "Esliz\u00f3n", "Chameleon": "Camale\u00f3n",
    "Turtle": "Tortuga", "Crocodile": "Cocodrilo",
    "Frog": "Rana", "Salamander": "Salamandra",
    "Fish": "Pez", "Trout": "Trucha", "Salmon": "Salm\u00f3n",
    "Cod": "Bacalao", "Carp": "Carpa", "Catfish": "Bagre",
    "Pike": "Lucio", "Eel": "Anguila",
    "Shark": "Tibur\u00f3n",
    "Whale": "Ballena", "Dolphin": "Delf\u00edn",
    "Octopus": "Pulpo", "Squid": "Calamar",
    "Crab": "Cangrejo", "Lobster": "Langosta",
    "Shrimp": "Camar\u00f3n", "Oyster": "Ostra", "Clam": "Almeja",
    "Mussel": "Mejill\u00f3n", "Snail": "Caracol",
    "Scorpion": "Escorpi\u00f3n",
    "Spider": "Ara\u00f1a",
    "Ant": "Hormiga", "Bee": "Abeja", "Wasp": "Avispa",
    "Fly": "Mosca", "Mosquito": "Mosquito",
    "Moth": "Polilla", "Butterfly": "Mariposa",
    "Dragonfly": "Lib\u00e9lula",
    "Grasshopper": "Saltamontes", "Cricket": "Grillo",
    "Beetle": "Escarabajo", "Ladybug": "Mariquita",
    "Firefly": "Luci\u00e9rnaga",
    "Centipede": "Ciempi\u00e9s", "Millipede": "Milpi\u00e9s",
    "Slug": "Babosa", "Leech": "Sanguijuela",
    "Jellyfish": "Medusa", "Starfish": "Estrella de mar",
    "Horse": "Caballo", "Pony": "Poni", "Donkey": "Burro", "Mule": "Mulo",
    "Cow": "Vaca", "Bull": "Toro", "Calf": "Ternero",
    "Goat": "Cabra", "Sheep": "Oveja", "Ram": "Carnero",
    "Pig": "Cerdo", "Boar": "Jabal\u00ed",
    "Dog": "Perro", "Hound": "Sabueso",
    "Cat": "Gato", "Lion": "Le\u00f3n", "Tiger": "Tigre",
    "Panther": "Pantera", "Leopard": "Leopardo",
    "Cheetah": "Guepardo", "Jaguar": "Jaguar",
    "Hyena": "Hiena", "Elephant": "Elefante",
    "Rhinoceros": "Rinoceronte",
    "Giraffe": "Jirafa", "Zebra": "Cebra", "Camel": "Camello",
    "Monkey": "Mono", "Ape": "Simio",
    "Gorilla": "Gorila", "Chimpanzee": "Chimpanc\u00e9",
    "Baboon": "Mandril", "Sloth": "Perezoso",
    "Armadillo": "Armadillo", "Porcupine": "Puercoesp\u00edn",
    "Skunk": "Mofeta", "Raccoon": "Mapache", "Badger": "Tej\u00f3n",
    "Otter": "Nutria", "Beaver": "Castor", "Mole": "Topo",
    "Hedgehog": "Erizo", "Mouse": "Rat\u00f3n",
    "Weasel": "Comadreja",
    "Mongoose": "Mangosta", "Meerkat": "Suricata",
    "Kangaroo": "Canguro", "Koala": "Koala",
    "Platypus": "Ornitorrinco",
    "Moose": "Alce", "Elk": "Uapit\u00ed", "Bison": "B\u00edsonte",
    "Buffalo": "B\u00fafalo", "Antelope": "Ant\u00edlope",
    "Gazelle": "Gacela", "Wildebeest": "\u00d1u",
    "Warthog": "Jabal\u00ed verrugoso",
    "Tapir": "Tapir", "Capybara": "Capibara",
    " man": " hombre", "MAN": "HOMBRE",
    " woman": " mujer", "WOMAN": "MUJER",
}

def translate_name(name):
    if not name:
        return name
    lower = name.lower()
    
    # Handle "X man" / "X woman" pattern
    if lower.endswith(" man"):
        base = name[:-4]
        tb = translate_name(base)
        if tb != base:
            prefix = "Hombre" if name[0].isupper() else "hombre"
            return prefix + " " + (tb[0].upper() + tb[1:] if tb else "")
        return name
    if lower.endswith(" woman"):
        base = name[:-6]
        tb = translate_name(base)
        if tb != base:
            prefix = "Mujer" if name[0].isupper() else "mujer"
            return prefix + " " + (tb[0].upper() + tb[1:] if tb else "")
        return name
    
    # Handle "Giant X" pattern
    if lower.startswith("giant "):
        base = name[6:]
        tb = translate_name(base)
        if tb != base:
            if name[0].isupper():
                return tb[0].upper() + tb[1:] + " gigante"
            return tb + " gigante"
        return name
    
    # Handle "Little X" pattern
    if lower.startswith("little "):
        base = name[7:]
        tb = translate_name(base)
        if tb != base:
            if name[0].isupper():
                return "Peque\u00f1o " + tb[0].upper() + tb[1:]
            return "peque\u00f1o " + tb
        return name
    
    # Direct lookup
    if name in DICT:
        return DICT[name]
    if lower in DICT:
        return DICT[lower]
    
    return name


print("Translating names...")
for fname in ["creatures.json", "materials.json", "plants.json", "items.json", "colors.json"]:
    path = os.path.join(DATA_DIR, fname)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    count = 0
    for entry in data:
        if isinstance(entry, dict):
            for key in ["name", "description"]:
                if key in entry and entry[key]:
                    old = entry[key]
                    new = translate_name(old)
                    if new != old:
                        entry[key] = new
                        count += 1
            if "caste_names" in entry:
                entry["caste_names"] = [translate_name(n) for n in entry["caste_names"]]
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    print(f"  {fname}: {count}")

print("Done!")
