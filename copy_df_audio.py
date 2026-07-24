import os, shutil, glob

SRC = r"F:\cacaneitor3000\bigli\dwarf fortress\data\sound"
DST = r"F:\cacaneitor3000\bigli\assets\df_sounds"

MAPPINGS = {
    "ambience": {
        "dst": "ambient",
        "files": {
            "Blizzard.ogg": "blizzard.ogg",
            "Cavern.ogg": "cavern.ogg",
            "Combat.ogg": "combat.ogg",
            "Desert.ogg": "desert.ogg",
            "Evil.ogg": "evil.ogg",
            "Forest.ogg": "forest.ogg",
            "Glacier.ogg": "glacier.ogg",
            "Good.ogg": "good.ogg",
            "Grasslands.ogg": "grasslands.ogg",
            "Magma_Close.ogg": "magma_close.ogg",
            "Magma_Far.ogg": "magma_far.ogg",
            "Magma_Low.ogg": "magma_low.ogg",
            "Neutral_Cavern.ogg": "neutral_cavern.ogg",
            "Neutral_Winds.ogg": "neutral_winds.ogg",
            "Neutral_Winds_2.ogg": "neutral_winds_2.ogg",
            "Outside.ogg": "outside.ogg",
            "Rainforest.ogg": "rainforest.ogg",
            "River_High.ogg": "river_high.ogg",
            "River_Low.ogg": "river_low.ogg",
            "River_Medium.ogg": "river_medium.ogg",
            "Siege.ogg": "siege_ambient.ogg",
            "Swamp.ogg": "swamp.ogg",
            "Tavern.ogg": "tavern.ogg",
            "Terrifying.ogg": "terrifying.ogg",
            "Thunderstorm.ogg": "thunderstorm.ogg",
            "Trade_Depot.ogg": "trade_depot.ogg",
            "Workshop.ogg": "workshop.ogg",
        }
    },
    "sounds": {
        "dst": "sfx",
        "files": {
            "adamantine.ogg": "adamantine.ogg",
            "alert.ogg": "alert.ogg",
            "ambush.ogg": "ambush.ogg",
            "artifact_created.ogg": "artifact_created.ogg",
            "baby_born.ogg": "baby_born.ogg",
            "cavern_break.ogg": "cavern_break.ogg",
            "demon_attack.ogg": "demon_attack.ogg",
            "Giant_Step_1.ogg": "giant_step_1.ogg",
            "Giant_Step_2.ogg": "giant_step_2.ogg",
            "Giant_Step_3.ogg": "giant_step_3.ogg",
            "Howl_1.ogg": "howl_1.ogg",
            "Howl_2.ogg": "howl_2.ogg",
            "Howl_3.ogg": "howl_3.ogg",
            "Howl_4.ogg": "howl_4.ogg",
            "Howl_5.ogg": "howl_5.ogg",
            "megabeast.ogg": "megabeast.ogg",
            "siege.ogg": "siege_horn.ogg",
            "strange_mood.ogg": "strange_mood.ogg",
            "wedding.ogg": "wedding.ogg",
        }
    },
}


def copy_files(category, mapping):
    src_dir = os.path.join(SRC, category)
    dst_dir = os.path.join(DST, mapping["dst"])
    os.makedirs(dst_dir, exist_ok=True)
    count = 0
    for src_name, dst_name in mapping["files"].items():
        src_path = os.path.join(src_dir, src_name)
        dst_path = os.path.join(dst_dir, dst_name)
        if os.path.exists(src_path):
            shutil.copy2(src_path, dst_path)
            count += 1
    return count


def copy_music():
    music_dirs = [
        "another_year", "craftsdwarfship", "death_spiral",
        "drink_&_industry", "dwarf_fortress", "expansive_cavern",
        "first_year", "forgotten_beast", "hill_dwarf",
        "koganusan", "mountainhome", "strange_moods",
        "strike_the_earth!", "vile_force_of_darkness",
        "winter_entombs_you", "cards"
    ]
    dst_dir = os.path.join(DST, "music")
    os.makedirs(dst_dir, exist_ok=True)
    count = 0
    for md in music_dirs:
        # Music albums are under tracks/ subdirectory
        src_dir = os.path.join(SRC, "tracks", md)
        if not os.path.exists(src_dir):
            continue
        album_dst = os.path.join(dst_dir, md.replace("&", "and").replace("!", ""))
        os.makedirs(album_dst, exist_ok=True)
        for f in os.listdir(src_dir):
            if f.endswith(".ogg") and not f.endswith(".ogg.import"):
                shutil.copy2(os.path.join(src_dir, f), os.path.join(album_dst, f.lower().replace(" ", "_")))
                count += 1
    return count


def main():
    print("Copying DF audio files to project...")

    amb = copy_files("ambience", MAPPINGS["ambience"])
    print(f"  Ambient: {amb} files")

    sfx = copy_files("sounds", MAPPINGS["sounds"])
    print(f"  SFX: {sfx} files")

    music = copy_music()
    print(f"  Music: {music} tracks across 16 albums")

    print(f"\nDone! Total: {amb + sfx + music} files copied to {DST}")


if __name__ == "__main__":
    main()
