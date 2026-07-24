import os
import re
import json

DF_DATA_PATH = r"f:\cacaneitor3000\bigli\dwarf fortress\data\vanilla"
OUTPUT_DIR = r"f:\cacaneitor3000\bigli\df_mode\data"

ALL_LAND_BIOMES = [
    "mountain_forest", "taiga", "pine_forest", "temperate_forest",
    "rainforest", "dense_temperate_forest", "grassland", "savanna",
    "badlands", "desert", "tundra", "swamp", "glacier",
]
ALL_FOREST_BIOMES = ["taiga", "pine_forest", "temperate_forest", "rainforest", "dense_temperate_forest"]
ALL_TEMPERATE_FOREST_BIOMES = ["pine_forest", "temperate_forest"]
ALL_TROPICAL_FOREST_BIOMES = ["rainforest", "dense_temperate_forest"]
ALL_OCEAN_BIOMES = ["ocean_shallow", "ocean_deep"]
ALL_DESERT_BIOMES = ["desert", "badlands"]

def map_df_biome(df_biome: str) -> list:
    mapping = {
        "mountain": ["mountain_forest"],
        "forest_taiga": ["taiga"],
        "forest_temperate_conifer": ["pine_forest"],
        "forest_temperate_broadleaf": ["temperate_forest"],
        "forest_tropical_conifer": ["rainforest"],
        "forest_tropical_broadleaf": ["dense_temperate_forest"],
        "forest_tropical_dry_broadleaf": ["rainforest"],
        "forest_tropical_moist_broadleaf": ["rainforest"],
        "grassland_temperate": ["grassland"],
        "savanna_temperate": ["savanna"],
        "shrubland_temperate": ["badlands"],
        "grassland_tropical": ["grassland"],
        "savanna_tropical": ["savanna"],
        "shrubland_tropical": ["badlands"],
        "desert_badland": ["badlands"],
        "desert_rock": ["desert"],
        "desert_sand": ["desert"],
        "ocean_tropical": ["ocean_shallow"],
        "ocean_temperate": ["ocean_shallow"],
        "ocean_arctic": ["ocean_deep"],
        "pool_temperate": ["swamp"],
        "pool_tropical": ["swamp"],
        "lake_temperate": ["swamp"],
        "lake_tropical": ["swamp"],
        "river_temperate": ["swamp"],
        "river_tropical": ["swamp"],
        "subterranean_water": ["caves"],
        "subterranean_chasm": ["caves"],
        "subterranean_magma": ["caves"],
        "any_land": ALL_LAND_BIOMES,
        "any_forest": ALL_FOREST_BIOMES,
        "any_temperate_forest": ALL_TEMPERATE_FOREST_BIOMES,
        "any_tropical_forest": ALL_TROPICAL_FOREST_BIOMES,
        "any_ocean": ALL_OCEAN_BIOMES,
        "any_desert": ALL_DESERT_BIOMES,
        "all_main": ALL_LAND_BIOMES,
        "any_grassland": ["grassland"],
        "any_savanna": ["savanna"],
        "any_shrubland": ["badlands"],
        "any_mountain": ["mountain_forest"],
        "any_swamp": ["swamp"],
        "any_wetland": ["swamp"],
        "any_marsh": ["swamp"],
        "any_lake": ["swamp"],
        "any_river": ["swamp"],
        "any_pool": ["swamp"],
        "any_temperate": ALL_TEMPERATE_FOREST_BIOMES + ["grassland", "savanna", "badlands", "swamp"],
        "any_tropical": ALL_TROPICAL_FOREST_BIOMES + ["grassland", "savanna", "badlands", "swamp"],
        "any_temperate_lake": ["swamp"],
        "any_temperate_marsh": ["swamp"],
        "any_temperate_swamp": ["swamp"],
        "any_temperate_river": ["swamp"],
        "any_temperate_wetland": ["swamp"],
        "any_tropical_swamp": ["swamp"],
        "any_tropical_wetland": ["swamp"],
        "any_temperate_freshwater": ["swamp"],
        "any_tropical_freshwater": ["swamp"],
        "all_inland": ALL_LAND_BIOMES + ["swamp", "caves"],
        "subterranean_lava": ["caves"],
        "not_freezing": ["grassland", "temperate_forest", "savanna", "badlands", "rainforest", "dense_temperate_forest"],
    }
    if df_biome in mapping:
        return mapping[df_biome]
    # If no direct match, try pattern-based fallbacks
    if df_biome.startswith("subterranean"):
        return ["caves"]
    if any(x in df_biome for x in ["lake", "pool", "river", "marsh", "swamp", "wetland"]):
        return ["swamp"]
    if "ocean" in df_biome or "sea" in df_biome:
        return ["ocean_shallow"]
    if "tundra" in df_biome or "glacier" in df_biome:
        return ["tundra", "glacier"]
    if "desert" in df_biome:
        return ["desert"]
    if "mountain" in df_biome:
        return ["mountain_forest"]
    return [df_biome]

def get_files_in_dir(subdir, prefix=""):
    full_dir = os.path.join(DF_DATA_PATH, subdir, "objects")
    if not os.path.exists(full_dir):
        return []
    return [os.path.join(full_dir, f) for f in os.listdir(full_dir) if f.startswith(prefix) and f.endswith(".txt")]

def parse_tags(file_path):
    with open(file_path, 'r', encoding='cp1252', errors='ignore') as f:
        content = f.read()
    
    # Extract all [TAG:VAL:VAL] instances
    return re.findall(r'\[(.*?)\]', content)

def parse_creatures():
    files = get_files_in_dir("vanilla_creatures", "creature_")
    creatures = []
    
    current_creature = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name == "CREATURE":
                if current_creature:
                    creatures.append(current_creature)
                current_creature = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "name": "",
                    "description": "",
                    "tile": "c",
                    "color": "#888888",
                    "biomes": [],
                    "size": "medium", # default
                    "caste_names": []
                }
            elif current_creature:
                if tag_name == "NAME" and len(parts) >= 2:
                    current_creature["name"] = parts[1].capitalize()
                elif tag_name == "CASTE_NAME" and len(parts) >= 2:
                    current_creature["caste_names"].append(parts[1].capitalize())
                elif tag_name == "DESCRIPTION" and len(parts) >= 2:
                    current_creature["description"] = parts[1]
                elif tag_name == "CREATURE_TILE" and len(parts) >= 2:
                    raw = parts[1]
                    if raw.startswith("'"):
                        # Quoted literal character: 'U', 'e', 'g' etc.
                        val = raw.replace("'", "")
                        if len(val) == 1:
                            current_creature["tile"] = val
                    elif raw.isdigit():
                        # Numeric CP437 code point: 1 (smiley), 2, 137, 249, 250
                        try:
                            current_creature["tile"] = chr(int(raw))
                        except:
                            pass
                elif tag_name == "COLOR" and len(parts) >= 4:
                    # Very rough color mapping
                    fg = int(parts[1]) if parts[1].isdigit() else 7
                    brightness = int(parts[3]) if parts[3].isdigit() else 0
                    color_map = {
                        0: "#000000", 1: "#0000AA", 2: "#00AA00", 3: "#00AAAA",
                        4: "#AA0000", 5: "#AA00AA", 6: "#AA5500", 7: "#AAAAAA"
                    }
                    bright_map = {
                        0: "#555555", 1: "#5555FF", 2: "#55FF55", 3: "#55FFFF",
                        4: "#FF5555", 5: "#FF55FF", 6: "#FFFF55", 7: "#FFFFFF"
                    }
                    if brightness == 1:
                        current_creature["color"] = bright_map.get(fg, "#FFFFFF")
                    else:
                        current_creature["color"] = color_map.get(fg, "#AAAAAA")
                elif tag_name == "BIOME" and len(parts) >= 2:
                    biome = parts[1].lower()
                    mapped_list = map_df_biome(biome)
                    for m in mapped_list:
                        if m not in current_creature["biomes"]:
                            current_creature["biomes"].append(m)
                elif tag_name == "BODY_SIZE" and len(parts) >= 4:
                    # [BODY_SIZE:0:0:10000]
                    # usually the last size is the adult size in cm^3
                    try:
                        sz = int(parts[3])
                        if sz < 1000:
                            current_creature["size"] = "small"
                        elif sz > 150000:
                            current_creature["size"] = "giant"
                        else:
                            current_creature["size"] = "medium"
                    except:
                        pass
                        
    if current_creature:
        creatures.append(current_creature)
        
    return creatures

def parse_materials():
    files = get_files_in_dir("vanilla_materials", "inorganic_")
    materials = []
    
    current_mat = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name == "INORGANIC":
                if current_mat:
                    materials.append(current_mat)
                current_mat = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "name": "",
                    "color": "#888888",
                    "value": 1,
                    "type": "stone"
                }
            elif current_mat:
                if tag_name == "STATE_NAME" and len(parts) >= 3 and "SOLID" in parts[1]:
                    current_mat["name"] = parts[2].capitalize()
                elif tag_name == "STATE_NAME_ADJ" and len(parts) >= 3 and "SOLID" in parts[1]:
                    if not current_mat["name"]:
                        current_mat["name"] = parts[2].capitalize()
                elif tag_name == "DISPLAY_COLOR" and len(parts) >= 4:
                    fg = int(parts[1]) if parts[1].isdigit() else 7
                    brightness = int(parts[3]) if parts[3].isdigit() else 0
                    color_map = {
                        0: "#000000", 1: "#0000AA", 2: "#00AA00", 3: "#00AAAA",
                        4: "#AA0000", 5: "#AA00AA", 6: "#AA5500", 7: "#AAAAAA"
                    }
                    bright_map = {
                        0: "#555555", 1: "#5555FF", 2: "#55FF55", 3: "#55FFFF",
                        4: "#FF5555", 5: "#FF55FF", 6: "#FFFF55", 7: "#FFFFFF"
                    }
                    if brightness == 1:
                        current_mat["color"] = bright_map.get(fg, "#FFFFFF")
                    else:
                        current_mat["color"] = color_map.get(fg, "#AAAAAA")
                elif tag_name == "MATERIAL_VALUE" and len(parts) >= 2:
                    try:
                        current_mat["value"] = int(parts[1])
                    except:
                        pass
                elif tag_name == "ITEMS_METAL":
                    current_mat["type"] = "metal"
                elif tag_name == "IS_METAL":
                    current_mat["type"] = "metal"
                elif tag_name == "METAL":
                    current_mat["type"] = "metal"
                elif tag_name == "IS_GEM":
                    current_mat["type"] = "gem"
                elif tag_name == "GEM":
                    current_mat["type"] = "gem"
                
    if current_mat:
        materials.append(current_mat)
        
    return materials

def parse_plants():
    files = get_files_in_dir("vanilla_plants", "plant_")
    plants = []
    
    current_plant = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name == "PLANT":
                if current_plant:
                    plants.append(current_plant)
                current_plant = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "name": "",
                    "is_tree": False
                }
            elif current_plant:
                if tag_name == "NAME" and len(parts) >= 2:
                    current_plant["name"] = parts[1].capitalize()
                elif tag_name == "TREE":
                    current_plant["is_tree"] = True
                
    if current_plant:
        plants.append(current_plant)
        
    return plants

def parse_items():
    files = get_files_in_dir("vanilla_items", "item_")
    items = []
    
    current_item = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name.startswith("ITEM_"):
                if current_item:
                    items.append(current_item)
                current_item = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "type": tag_name,
                    "name": "",
                    "size": 100
                }
            elif current_item:
                if tag_name == "NAME" and len(parts) >= 2:
                    current_item["name"] = parts[1].capitalize()
                elif tag_name == "SIZE" and len(parts) >= 2:
                    try:
                        current_item["size"] = int(parts[1])
                    except:
                        pass
                
    if current_item:
        items.append(current_item)
        
    return items

def parse_buildings():
    """Extract custom workshops from building_custom.txt."""
    files = get_files_in_dir("vanilla_buildings", "building_")
    buildings = []
    
    current_bld = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name.startswith("BUILDING_"):
                if current_bld:
                    buildings.append(current_bld)
                current_bld = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "type": tag_name,
                    "name": "",
                    "dim": [1, 1]
                }
            elif current_bld:
                if tag_name == "NAME" and len(parts) >= 2:
                    current_bld["name"] = parts[1]
                elif tag_name == "DIM" and len(parts) >= 3:
                    try:
                        current_bld["dim"] = [int(parts[1]), int(parts[2])]
                    except:
                        pass

    if current_bld:
        buildings.append(current_bld)
    return buildings

def parse_texts():
    """Extract text sets from all text_*.txt files across all directories."""
    texts = []
    search_dirs = ["vanilla_text", "vanilla_creatures"]
    
    for subdir in search_dirs:
        base = os.path.join(DF_DATA_PATH, subdir)
        if not os.path.exists(base):
            continue
        for root, dirs, files in os.walk(base):
            for fname in files:
                if not fname.endswith(".txt") or not fname.startswith("text_"):
                    continue
                fpath = os.path.join(root, fname)
                try:
                    with open(fpath, 'r', encoding='cp1252', errors='ignore') as f:
                        content = f.read()
                except:
                    continue
                tags = re.findall(r'\[(.*?)\]', content)
                current_set = None
                for tag_content in tags:
                    parts = tag_content.split(':')
                    tag_name = parts[0]
                    if tag_name == "TEXT_SET" and len(parts) >= 2:
                        current_set = {"id": parts[1], "lines": []}
                        texts.append(current_set)
                    elif tag_name == "OBJECT":
                        pass
                # Extract text lines between/below TEXT_SET tags
                for tag_content in tags:
                    parts = tag_content.split(':')
                    tag_name = parts[0]
                    if tag_name == "TEXT_SET" and len(parts) >= 2:
                        current_set = {"id": parts[1], "lines": []}
                        texts.append(current_set)
                    elif tag_name == "OBJECT":
                        pass
                if texts:
                    # Parse lines after each [TEXT_SET:] tag
                    lines = content.split('\n')
                    current_lines = []
                    text_set_name = None
                    for line in lines:
                        line = line.strip()
                        if line.startswith('[TEXT_SET:'):
                            if text_set_name and current_lines:
                                # Find and update the existing entry
                                for t in texts:
                                    if t['id'] == text_set_name:
                                        t['lines'] = current_lines
                                        break
                                current_lines = []
                            m = re.match(r'\[TEXT_SET:(\w+)\]', line)
                            if m:
                                text_set_name = m.group(1)
                        elif line.startswith('[') or line.startswith('text_') or line == '':
                            continue
                        else:
                            current_lines.append(line)
                    if text_set_name and current_lines:
                        for t in texts:
                            if t['id'] == text_set_name:
                                t['lines'] = current_lines
                                break
    
    # Deduplicate by id
    seen = set()
    unique = []
    for t in texts:
        if t['id'] not in seen:
            seen.add(t['id'])
            unique.append(t)
    return unique

def parse_entities():
    files = get_files_in_dir("vanilla_entities", "entity_")
    entities = []
    
    current_entity = None
    for f in files:
        tags = parse_tags(f)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name == "ENTITY":
                if current_entity:
                    entities.append(current_entity)
                current_entity = {
                    "id": parts[1] if len(parts) > 1 else "UNKNOWN",
                    "weapons": [],
                    "armor": []
                }
            elif current_entity:
                if tag_name == "WEAPON" and len(parts) >= 2:
                    current_entity["weapons"].append(parts[1])
                elif tag_name == "ARMOR" and len(parts) >= 2:
                    current_entity["armor"].append(parts[1])
                
    if current_entity:
        entities.append(current_entity)
        
    return entities


def parse_entity_creature_biomes():
    """Parse entity files to map creatures to their start/settlement biomes."""
    files = get_files_in_dir("vanilla_entities", "entity_")
    creature_biomes = {}  # creature_id -> list of biomes
    
    current_entity = None
    current_entity_creature = None
    
    for f in files:
        with open(f, 'r', encoding='cp1252', errors='ignore') as fh:
            content = fh.read()
        
        tags = re.findall(r'\[(.*?)\]', content)
        for tag_content in tags:
            parts = tag_content.split(':')
            tag_name = parts[0]
            
            if tag_name == "ENTITY":
                current_entity = parts[1] if len(parts) > 1 else None
                current_entity_creature = None
            elif tag_name == "CREATURE" and len(parts) >= 2:
                current_entity_creature = parts[1]
                if current_entity_creature not in creature_biomes:
                    creature_biomes[current_entity_creature] = []
            elif tag_name in ("START_BIOME", "EXCLUSIVE_START_BIOME", "SETTLEMENT_BIOME") and current_entity_creature:
                if len(parts) >= 2:
                    biome = parts[1].lower()
                    mapped_list = map_df_biome(biome)
                    for m in mapped_list:
                        if m not in creature_biomes[current_entity_creature]:
                            creature_biomes[current_entity_creature].append(m)
    
    return creature_biomes

def main():
    print("Extracting DF RAWs...")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    creatures = parse_creatures()
    print(f"Extracted {len(creatures)} creatures.")
    
    materials = parse_materials()
    print(f"Extracted {len(materials)} materials.")
    
    plants = parse_plants()
    print(f"Extracted {len(plants)} plants.")
    
    items = parse_items()
    print(f"Extracted {len(items)} items.")
    
    entities = parse_entities()
    print(f"Extracted {len(entities)} entities.")

    texts = parse_texts()
    print(f"Extracted {len(texts)} text sets.")
    
    buildings = parse_buildings()
    print(f"Extracted {len(buildings)} buildings.")
    
    # Apply entity biome data to creatures with empty biomes (intelligent races etc.)
    entity_biomes = parse_entity_creature_biomes()
    filled = 0
    for c in creatures:
        if not c["biomes"] and c["id"] in entity_biomes:
            c["biomes"] = entity_biomes[c["id"]]
            filled += 1
    print(f"Filled biomes for {filled} creatures from entity files.")
    
    with open(os.path.join(OUTPUT_DIR, "creatures.json"), "w", encoding="utf-8") as f:
        json.dump(creatures, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "materials.json"), "w", encoding="utf-8") as f:
        json.dump(materials, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "plants.json"), "w", encoding="utf-8") as f:
        json.dump(plants, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "items.json"), "w", encoding="utf-8") as f:
        json.dump(items, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "entities.json"), "w", encoding="utf-8") as f:
        json.dump(entities, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "texts.json"), "w", encoding="utf-8") as f:
        json.dump(texts, f, indent=4)
        
    with open(os.path.join(OUTPUT_DIR, "buildings.json"), "w", encoding="utf-8") as f:
        json.dump(buildings, f, indent=4)
        
    print("Done! Data exported to df_mode/data/")

if __name__ == "__main__":
    main()
