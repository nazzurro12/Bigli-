import json, os, sys, time

DATA_DIR = "df_mode/data"

# --- DICCIONARIO DE NOMBRES ---
DICT = {
    "Dwarf": "Enano", "dwarf": "enano", "DWARF": "ENANO",
    "Elf": "Elfo", "elf": "elfo", "ELF": "ELFO",
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
    "Ettin": "Ettin",
    "Foul blendec": "Blendec inmundo",
    "Grimeling": "Grimeling",
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
}

# --- NOMBRES MULTI-PALABRA (traduccion exacta) ---
MULTI = {
    "gold dust": "Polvo de oro",
    "native gold dust": "Polvo de oro nativo",
    "native aluminum": "Aluminio nativo",
    "native copper": "Cobre nativo",
    "native platinum": "Platino nativo",
    "native silver": "Plata nativa",
    "pig iron": "Hierro colado",
    "bismuth bronze": "Bronce de bismuto",
    "black bronze": "Bronce negro",
    "nickel silver": "Plata de n\u00edquel",
    "rose gold": "Oro rosa",
    "sterling silver": "Plata esterlina",
    "fine pewter": "Peltre fino",
    "lay pewter": "Peltre laminar",
    "trifle pewter": "Peltre menor",
    "horn silver": "Plata c\u00f3rnea",
    "bituminous coal": "Carb\u00f3n bituminoso",
    "petrified wood": "Madera petrificada",
    "rock salt": "Sal gema",
    "fire clay": "Arcilla refractaria",
    "black sand": "Arena negra",
    "red sand": "Arena roja",
    "white sand": "Arena blanca",
    "yellow sand": "Arena amarilla",
    "calcareous ooze": "Cieno calc\u00e1reo",
    "siliceous ooze": "Cieno sil\u00edceo",
    "pelagic clay": "Arcilla pel\u00e1gica",
    "clay loam": "Marga arcillosa",
    "sandy clay": "Arcilla arenosa",
    "silty clay": "Arcilla limosa",
    "sandy loam": "Marga arenosa",
    "silt loam": "Marga limosa",
    "sandy clay loam": "Marga arcillo-arenosa",
    "silty clay loam": "Marga arcillo-limosa",
    "raw adamantine": "Adamantita en bruto",
    "blue jay": "Arrendajo azul",
    "blue jay": "Arrendajo azul",
    "giant bluejay": "Arrendajo gigante",
    "bluejay": "Arrendajo",
    "giant toad": "Sapo gigante",
    "giant fox": "Zorro gigante",
    "giant wolf": "Lobo gigante",
    "giant bear": "Oso gigante",
    "giant eagle": "\u00c1guila gigante",
    "giant bat": "Murci\u00e9lago gigante",
    "giant spider": "Ara\u00f1a gigante",
    "giant cave spider": "Ara\u00f1a de caverna gigante",
    "cave spider": "Ara\u00f1a de caverna",
    "cave crocodile": "Cocodrilo de caverna",
    "saltwater crocodile": "Cocodrilo de agua salada",
    "single-grain wheat": "Trigo de un grano",
    "two-grain wheat": "Trigo de dos granos",
    "soft wheat": "Trigo blando",
    "hard wheat": "Trigo duro",
    "club wheat": "Trigo compacto",
    "durum wheat": "Trigo duro",
    "foxtail millet": "Mijo menor",
    "finger millet": "Mijo africano",
    "pearl millet": "Mijo perla",
    "pearl barley": "Cebada perlada",
    "sugar cane": "Ca\u00f1a de az\u00facar",
    "sugar beet": "Remolacha azucarera",
    "sweet potato": "Batata",
    "bitter vetch": "Alcarce\u00f1a",
    "pendant amaranth": "Amaranto colgante",
    "purple amaranth": "Amaranto p\u00farpura",
    "red spinach": "Espinaca roja",
    "garden cress": "Berro de jard\u00edn",
    "sea kale": "Col marina",
    "tree spinach": "Espinaca de \u00e1rbol",
    "wild ginger": "Jengibre silvestre",
    "prickle berry": "Baya espinosa",
    "sun berry": "Baya solar",
    "fisher berry": "Baya pescadora",
    "quarry bush": "Arbusto de cantera",
    "bloated tuber": "Tub\u00e9rculo hinchado",
    "hide root": "Ra\u00edz escudo",
    "rope reed": "Junco cuerda",
    "sliver barb": "Barba plateada",
    "cave wheat": "Trigo de caverna",
    "pig tail": "Rabicerdal",
    "plump helmet": "Seta regordeta",
    "dimple cup": "Seta hoyuelo",
    "sweet pod": "Vaina dulce",
    "longland grass": "Hierba de tierras largas",
    "sweet bill": "Pico dulce",
    "rat weed": "Hierba rata",
    "river sand": "Arena de r\u00edo",
    "purple tower cap": "Champi\u00f1\u00f3n torre p\u00farpura",
    "bloodthorn": "Espina sangrienta",
    "black cap": "Champi\u00f1\u00f3n negro",
    "spore tree": "\u00c1rbol espora",
    "spelter": "Esp\u00e9lter",
    "copper nuggets": "Pepitas de cobre",
    "gold nuggets": "Pepitas de oro",
    "silver nuggets": "Pepitas de plata",
    "platinum nuggets": "Pepitas de platino",
    "tower-cap": "Champi\u00f1\u00f3n torre",
    "tower cap": "Champi\u00f1\u00f3n torre",
    "canary grass": "Alpiste",
    "bambara groundnut": "Cacahuete de Bambara",
    "hemp": "C\u00e1\u00f1amo",
    "alfalfa": "Alfalfa",
    "quinoa": "Quinua",
    "kaniwa": "Ka\u00f1iwa",
    "single-grain wheat": "Trigo de un grano",
    "two-grain wheat": "Trigo de dos granos",
    "soft wheat": "Trigo blando",
    "hard wheat": "Trigo duro",
    "durum wheat": "Trigo duro",
    "club wheat": "Trigo compacto",
    "breadfruit": "\u00c1rbol del pan",
    "durian": "Durian",
    "mangosteen": "Mangost\u00e1n",
    "rambutan": "Rambut\u00e1n",
    "loganberry": "Loganberry",
    "boysenberry": "Boysenberry",
    "elderberry": "Sa\u00faco",
    "huckleberry": "Ar\u00e1ndano negro",
    "currant": "Grosella",
    "gooseberry": "Grosella espinosa",
    "lingonberry": "Ar\u00e1ndano rojo",
    "cucumber": "Pepino",
    "okra": "Okra",
    "artichoke": "Alcachofa",
    "eggplant": "Berenjena",
    "asparagus": "Esp\u00e1rrago",
    "celery": "Apio",
    "parsnip": "Chiriv\u00eda",
    "radish": "R\u00e1bano",
    "horseradish": "R\u00e1bano picante",
    "salsify": "Salsif\u00ed",
    "watercress": "Berro",
    "leek": "Puerro",
    "shallot": "Chalote",
    "scallion": "Cebolleta",
    "turnip": "Nabo",
    "rutabaga": "Colinabo",
    "daikon": "Daikon",
    "chervil": "Perifollo",
    "basil": "Albahaca",
    "oregano": "Or\u00e9gano",
    "thyme": "Tomillo",
    "rosemary": "Romero",
    "sage": "Salvia",
    "mint": "Menta",
    "dill": "Eneldo",
    "tarragon": "Estrag\u00f3n",
    "coriander": "Cilantro",
    "marjoram": "Mejorana",
    "bay leaf": "Laurel",
    "caraway": "Alcaravea",
    "celery salt": "Apio sal",
    "onion salt": "Cebolla sal",
    "garlic salt": "Ajo sal",
    "brewers yeast": "Levadura de cerveza",
    "rivermist": "Niebla de r\u00edo",
    "creosote": "Creosota",
    "rubber tree": "\u00c1rbol del caucho",
}

def dict_lookup(word):
    """Case-insensitive lookup in DICT."""
    if word in DICT: return DICT[word]
    if word.lower() in DICT: return DICT[word.lower()]
    if word.capitalize() in DICT: return DICT[word.capitalize()]
    if word.title() in DICT: return DICT[word.title()]
    if word.upper() in DICT: return DICT[word.upper()]
    return None

def lookup_name(name, lower):
    if lower in MULTI:
        return MULTI[lower]
    dl = dict_lookup(name)
    if dl: return dl
    if lower.endswith(" man"):
        base = name[:-4].strip()
        bl = base.lower()
        dl = dict_lookup(base)
        if dl: return "Hombre " + dl
        tb = lookup_name(base, bl)
        if tb != base: return "Hombre " + tb
    if lower.endswith(" woman"):
        base = name[:-6].strip()
        bl = base.lower()
        dl = dict_lookup(base)
        if dl: return "Mujer " + dl
        tb = lookup_name(base, bl)
        if tb != base: return "Mujer " + tb
    if lower.startswith("giant "):
        base = name[6:].strip()
        bl = base.lower()
        dl = dict_lookup(base)
        if dl:
            return dl + " gigante"
        tb = lookup_name(base, bl)
        if tb != base:
            if tb[0].isupper():
                return tb[0].upper() + tb[1:] + " gigante"
            return tb + " gigante"
    if lower.startswith("little "):
        base = name[7:].strip()
        bl = base.lower()
        dl = dict_lookup(base)
        if dl: return "Peque\u00f1o " + dl
        tb = lookup_name(base, bl)
        if tb != base: return "Peque\u00f1o " + tb
    return name

def translate_name(name):
    if not name: return name
    return lookup_name(name, name.lower().strip())

def translate_material(name):
    if not name: return name
    lower = name.lower().strip()
    if lower in MULTI: return MULTI[lower]
    if name in DICT: return DICT[name]
    if lower in DICT: return DICT[lower]
    # Google translate fallback for unknown materials
    if any(ord(c) > 127 for c in name): return name
    from deep_translator import GoogleTranslator
    try:
        t = GoogleTranslator(source="en", target="es")
        return t.translate(name)
    except:
        return name


# === DESCRIPCIONES (pre-traducidas) ===
DESC_DICT = {}
DESC_DICT["A squat amphibian with leathery skin, found in relatively dry areas."] = \
    "Un anfibio rechoncho con piel correosa, que se encuentra en \u00e1reas relativamente secas."
DESC_DICT["A dark green man with the distinct head of a toad."] = \
    "Un hombre verde oscuro con la cabeza distintiva de un sapo."
DESC_DICT["A huge monster in the shape of a toad."] = \
    "Un enorme monstruo con forma de sapo."
DESC_DICT["A short, sturdy creature fond of drink and industry."] = \
    "Una criatura baja y robusta aficionada a la bebida y la industria."
DESC_DICT["A medium-sized creature dedicated to the ruthless protection of nature."] = \
    "Una criatura de tama\u00f1o mediano dedicada a la protecci\u00f3n despiadada de la naturaleza."
DESC_DICT["A medium-sized creature prone to great ambition."] = \
    "Una criatura de tama\u00f1o mediano propensa a una gran ambici\u00f3n."
DESC_DICT["A medium-sized humanoid driven to cruelty by its evil nature."] = \
    "Un humanoide de tama\u00f1o mediano impulsado a la crueldad por su naturaleza malvada."
DESC_DICT["A small, squat humanoid with large pointy ears and yellow glowing eyes."] = \
    "Un humanoide peque\u00f1o y rechoncho con grandes orejas puntiagudas y ojos amarillos brillantes."
DESC_DICT["A short, sturdy creature fond of drink and industry."] = \
    "Una criatura baja y robusta aficionada a la bebida y la industria."
DESC_DICT["A tiny, giggling humanoid with lacy wings."] = \
    "Un humanoide diminuto y risue\u00f1o con alas de encaje."
DESC_DICT["A medium-sized humanoid with large colorful wings, prone to wild mood swings."] = \
    "Un humanoide de tama\u00f1o mediano con grandes alas coloridas, propenso a cambios de humor salvajes."
DESC_DICT["A small striped humanoid that lives in tunnels."] = \
    "Un peque\u00f1o humanoide rayado que vive en t\u00faneles."
DESC_DICT["A huge reptilian creature.  It is magical and can breathe fire.  These monsters accumulate hoards of treasure."] = \
    "Una enorme criatura reptiliana. Es m\u00e1gica y puede respirar fuego. Estos monstruos acumulan montones de tesoro."
DESC_DICT["A gigantic humanoid known for its immense strength and low intelligence."] = \
    "Un humanoide gigantesco conocido por su inmensa fuerza y baja inteligencia."
DESC_DICT["A massive humanoid with a single eye in the center of its forehead."] = \
    "Un humanoide masivo con un solo ojo en el centro de su frente."
DESC_DICT["A creature with the head of a bull and the body of a man, confined to labyrinths."] = \
    "Una criatura con cabeza de toro y cuerpo de hombre, confinada a laberintos."
DESC_DICT["A large serpentine creature with multiple heads."] = \
    "Una gran criatura serpentina con m\u00faltiples cabezas."
DESC_DICT["A creature with the upper body of a woman and the lower body of a bird."] = \
    "Una criatura con la parte superior de mujer y la parte inferior de ave."
DESC_DICT["A white horse with a single horn on its forehead."] = \
    "Un caballo blanco con un solo cuerno en la frente."
DESC_DICT["A creature with the body of a lion and the head and wings of an eagle."] = \
    "Una criatura con cuerpo de le\u00f3n y cabeza y alas de \u00e1guila."
DESC_DICT["A creature with the upper body of a man and the lower body of a goat."] = \
    "Una criatura con la parte superior de hombre y la parte inferior de cabra."
DESC_DICT["A large, shaggy humanoid that lives in the coldest mountains."] = \
    "Un gran humanoide peludo que vive en las monta\u00f1as m\u00e1s fr\u00edas."
DESC_DICT["A humanoid with the lower body of a fish."] = \
    "Un humanoide con la parte inferior de pez."
DESC_DICT["A small mischievous creature that likes to break things."] = \
    "Una peque\u00f1a criatura traviesa que le gusta romper cosas."
DESC_DICT["A large flying creature with leathery wings."] = \
    "Una gran criatura voladora con alas cori\u00e1ceas."
DESC_DICT["A slender, ethereal creature that inhabits the deepest caverns."] = \
    "Una criatura esbelta y et\u00e9rea que habita las cavernas m\u00e1s profundas."
DESC_DICT["A writhing mass of tentacles and eyes."] = \
    "Una masa retorcida de tent\u00e1culos y ojos."
DESC_DICT["A formless horror from the depths."] = \
    "Un horror informe de las profundidades."
DESC_DICT["An eight-legged creature that weaves webs to trap its prey."] = \
    "Una criatura de ocho patas que teje telas para atrapar a sus presas."
DESC_DICT["A six-legged creature that can be found in nearly any environment."] = \
    "Una criatura de seis patas que se puede encontrar en casi cualquier entorno."
DESC_DICT["A jumping insect that is a pest in grasslands."] = \
    "Un insecto saltar\u00edn que es una plaga en los pastizales."
DESC_DICT["A small creature that can be found in nearly any environment."] = \
    "Una peque\u00f1a criatura que se puede encontrar en casi cualquier entorno."
DESC_DICT["A four-legged creature commonly found in forests."] = \
    "Una criatura de cuatro patas com\u00fanmente encontrada en bosques."
DESC_DICT["A hoofed mammal that lives in mountainous regions."] = \
    "Un mam\u00edfero con pezu\u00f1as que vive en regiones monta\u00f1osas."
DESC_DICT["A large quadrupedal mammal found in grasslands and savannas."] = \
    "Un gran mam\u00edfero cuadr\u00fapedo que se encuentra en pastizales y sabanas."
DESC_DICT["A domesticated animal used for meat and leather."] = \
    "Un animal domesticado usado para carne y cuero."
DESC_DICT["A domesticated animal valued for its wool."] = \
    "Un animal domesticado valorado por su lana."
DESC_DICT["A common farm animal."] = \
    "Un animal de granja com\u00fan."
DESC_DICT["A small furry mammal."] = \
    "Un peque\u00f1o mam\u00edfero peludo."
DESC_DICT["A small rodent."] = \
    "Un peque\u00f1o roedor."
DESC_DICT["A common bird."] = \
    "Un ave com\u00fan."
DESC_DICT["A large bird that cannot fly."] = \
    "Un ave grande que no puede volar."
DESC_DICT["A bird of prey."] = \
    "Un ave de presa."
DESC_DICT["A waterfowl."] = \
    "Un ave acu\u00e1tica."
DESC_DICT["A flightless bird."] = \
    "Un ave no voladora."
DESC_DICT["A large mammal that lives in the ocean."] = \
    "Un gran mam\u00edfero que vive en el oc\u00e9ano."
DESC_DICT["A predatory fish."] = \
    "Un pez depredador."
DESC_DICT["A small fish found in streams and lakes."] = \
    "Un pez peque\u00f1o que se encuentra en arroyos y lagos."
DESC_DICT["A common shellfish."] = \
    "Un marisco com\u00fan."
DESC_DICT["An insect that lives in colonies."] = \
    "Un insecto que vive en colonias."
DESC_DICT["A venomous arachnid."] = \
    "Un ar\u00e1cnido venenoso."

# Mass-generated descriptions for common patterns
import re
def add_pattern_desc(pattern, template):
    """Add descriptions matching a regex pattern."""
    pass  # We'll add them individually

# Common animal templates
for animal_type, desc in [
    ("A small mammal", "Un peque\u00f1o mam\u00edfero"),
    ("A small omnivore", "Un peque\u00f1o om\u00edvoro"),
    ("A small herbivore", "Un peque\u00f1o herb\u00edvoro"),
    ("A small carnivore", "Un peque\u00f1o carnicero"),
    ("A small bird", "Un ave peque\u00f1a"),
    ("A medium-sized bird", "Un ave de tama\u00f1o mediano"),
    ("A large bird", "Un ave grande"),
    ("A large mammal", "Un gran mam\u00edfero"),
    ("A large predator", "Un gran depredador"),
    ("A common fish", "Un pez com\u00fan"),
    ("A large fish", "Un pez grande"),
    ("A small fish", "Un pez peque\u00f1o"),
    ("A common reptile", "Un reptil com\u00fan"),
    ("A small reptile", "Un reptil peque\u00f1o"),
    ("A common amphibian", "Un anfibio com\u00fan"),
    ("A common insect", "Un insecto com\u00fan"),
    ("A small insect", "Un insecto peque\u00f1o"),
    ("A domestic animal", "Un animal dom\u00e9stico"),
    ("A common domestic animal", "Un animal dom\u00e9stico com\u00fan"),
    ("A wild canine", "Un c\u00e1nido salvaje"),
    ("A wild feline", "Un felino salvaje"),
    ("A common primate", "Un primate com\u00fan"),
    ("An ungulate", "Un ungulado"),
    ("A common ungulate", "Un ungulado com\u00fan"),
    ("A creature of myth and legend", "Una criatura de mito y leyenda"),
    ("A tiny creature", "Una criatura diminuta"),
]:
    DESC_DICT[animal_type] = desc + "."

# Common "found in" completions
for env, env_es in [
    ("forests", "bosques"),
    ("temperate forests", "bosques templados"),
    ("tropical forests", "bosques tropicales"),
    ("grasslands", "pastizales"),
    ("savannas", "sabanas"),
    ("mountains", "monta\u00f1as"),
    ("deserts", "desiertos"),
    ("tundra", "tundra"),
    ("swamps", "pantanos"),
    ("oceans", "oc\u00e9anos"),
    ("rivers", "r\u00edos"),
    ("lakes", "lagos"),
    ("caves", "cavernas"),
    ("the deepest caves", "las cavernas m\u00e1s profundas"),
    ("underground", "subterr\u00e1neo"),
]:
    DESC_DICT[f"found in {env}"] = f"que se encuentra en {env_es}"
    DESC_DICT[f"living in {env}"] = f"que vive en {env_es}"
    DESC_DICT[f"that lives in {env}"] = f"que vive en {env_es}"
    DESC_DICT[f"that inhabits {env}"] = f"que habita en {env_es}"

def translate_desc(text):
    if not text: return text
    if any(ord(c) > 127 for c in text): return text
    if text in DESC_DICT: return DESC_DICT[text]
    # Use Google Translate only for unknown descriptions
    from deep_translator import GoogleTranslator
    try:
        t = GoogleTranslator(source="en", target="es")
        r = t.translate(text)
        time.sleep(0.02)
        return r
    except:
        return text


def translate_text(text):
    if not text: return text
    if any(ord(c) > 127 for c in text): return text
    if text in DESC_DICT: return DESC_DICT[text]
    if text in MULTI: return MULTI[text]
    from deep_translator import GoogleTranslator
    try:
        t = GoogleTranslator(source="en", target="es")
        r = t.translate(text)
        time.sleep(0.02)
        return r
    except:
        return text


print("=== TRADUCIENDO DATOS DF AL ESPA\u00d1OL ===", flush=True)

# 1. CRIATURAS
path = os.path.join(DATA_DIR, "creatures.json")
with open(path, "r", encoding="utf-8") as f:
    creatures = json.load(f)
print(f"\n[1/6] Traduciendo {len(creatures)} criaturas...", flush=True)
for i, c in enumerate(creatures):
    c["name"] = translate_name(c.get("name", ""))
    c["description"] = translate_desc(c.get("description", ""))
    c["caste_names"] = [translate_name(n) for n in c.get("caste_names", [])]
    if (i+1) % 100 == 0:
        print(f"  {i+1}/{len(creatures)}", flush=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(creatures, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(creatures)} criaturas", flush=True)

# 2. MATERIALES
path = os.path.join(DATA_DIR, "materials.json")
with open(path, "r", encoding="utf-8") as f:
    mats = json.load(f)
print(f"\n[2/6] Traduciendo {len(mats)} materiales...", flush=True)
for m in mats:
    m["name"] = translate_material(m.get("name", ""))
with open(path, "w", encoding="utf-8") as f:
    json.dump(mats, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(mats)} materiales", flush=True)

# 3. PLANTAS
path = os.path.join(DATA_DIR, "plants.json")
with open(path, "r", encoding="utf-8") as f:
    plants = json.load(f)
print(f"\n[3/6] Traduciendo {len(plants)} plantas...", flush=True)
for p in plants:
    p["name"] = translate_name(p.get("name", ""))
with open(path, "w", encoding="utf-8") as f:
    json.dump(plants, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(plants)} plantas", flush=True)

# 4. ITEMS
path = os.path.join(DATA_DIR, "items.json")
with open(path, "r", encoding="utf-8") as f:
    items = json.load(f)
print(f"\n[4/6] Traduciendo {len(items)} \u00edtems...", flush=True)
for it in items:
    it["name"] = translate_name(it.get("name", ""))
with open(path, "w", encoding="utf-8") as f:
    json.dump(items, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(items)} \u00edtems", flush=True)

# 5. COLORES
path = os.path.join(DATA_DIR, "colors.json")
with open(path, "r", encoding="utf-8") as f:
    colors = json.load(f)
print(f"\n[5/6] Traduciendo {len(colors)} colores...", flush=True)
for c in colors:
    if "name" in c:
        c["name"] = translate_name(c["name"])
with open(path, "w", encoding="utf-8") as f:
    json.dump(colors, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(colors)} colores", flush=True)

# 6. TEXTOS
path = os.path.join(DATA_DIR, "texts.json")
with open(path, "r", encoding="utf-8") as f:
    texts = json.load(f)
print(f"\n[6/6] Traduciendo {len(texts)} textos...", flush=True)
for t in texts:
    t["lines"] = [translate_text(l) for l in t.get("lines", [])]
with open(path, "w", encoding="utf-8") as f:
    json.dump(texts, f, indent=4, ensure_ascii=False)
print(f"  \u2713 {len(texts)} textos", flush=True)

print("\n\u2705 TRADUCCION COMPLETA", flush=True)
