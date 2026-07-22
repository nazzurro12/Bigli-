from __future__ import annotations

from pathlib import Path
import re
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "_patch_build"
PATCH_ROOT = BUILD / "Bigliworld_optimizacion_fase1"
DIST = ROOT / "dist"


def fail(message: str) -> None:
    raise RuntimeError(message)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        fail(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return text.replace(old, new, 1)


def indent_block(text: str, start_marker: str, end_marker: str, condition: str, label: str) -> str:
    start = text.find(start_marker)
    if start < 0:
        fail(f"{label}: no se encontró el inicio")
    end = text.find(end_marker, start)
    if end < 0:
        fail(f"{label}: no se encontró el final")
    block = text[start:end]
    indented = "".join(("\t" + line if line.strip() else line) for line in block.splitlines(keepends=True))
    return text[:start] + f"\tif {condition}:\n" + indented + text[end:]


def replace_loop_once(text: str, old: str, new: str, label: str) -> str:
    index = text.find(old)
    if index < 0:
        fail(f"{label}: bucle no encontrado")
    return text[:index] + new + text[index + len(old):]


def function_slice(text: str, function_name: str) -> tuple[int, int]:
    marker = f"func {function_name}"
    start = text.find(marker)
    if start < 0:
        fail(f"Función no encontrada: {function_name}")
    match = re.search(r"\nfunc [A-Za-z0-9_]+", text[start + 1:])
    end = len(text) if match is None else start + 1 + match.start()
    return start, end


def validate_gdscript(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    functions = re.findall(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(", text)
    duplicates = sorted({name for name in functions if functions.count(name) > 1})
    if duplicates:
        fail(f"{path}: funciones duplicadas: {duplicates}")
    if "\r" in text:
        fail(f"{path}: contiene retornos CR inesperados")
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack: list[str] = []
    in_string = False
    escaped = False
    quote = ""
    for char in text:
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                in_string = False
            continue
        if char in ('"', "'"):
            in_string = True
            quote = char
        elif char in pairs:
            stack.append(char)
        elif char in pairs.values():
            if not stack or pairs[stack.pop()] != char:
                fail(f"{path}: delimitadores desbalanceados")
    if stack:
        fail(f"{path}: delimitadores sin cerrar")


def patch_main() -> str:
    source_path = ROOT / "df_mode" / "df_main.gd"
    text = source_path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "var _time_accum: float = 0.0\n",
        "var _time_accum: float = 0.0\n"
        "# La interfaz no necesita duplicar arrays, clima y paneles en cada frame.\n"
        "# La cámara y la posesión siguen actualizándose cada frame.\n"
        "const RENDERER_STATE_SYNC_INTERVAL: float = 0.05\n"
        "var _renderer_state_sync_accumulator: float = 0.0\n",
        "variables de sincronización del renderer",
    )

    process_start, process_end = function_slice(text, "_process(delta: float) -> void:")
    process_text = text[process_start:process_end]
    process_text = replace_once(
        process_text,
        "\n\trenderer.game_hour = _game_hour\n",
        "\n\t_renderer_state_sync_accumulator += delta\n"
        "\tvar sync_renderer_state: bool = _renderer_state_sync_accumulator >= RENDERER_STATE_SYNC_INTERVAL\n"
        "\tif sync_renderer_state:\n"
        "\t\t_renderer_state_sync_accumulator = fmod(_renderer_state_sync_accumulator, RENDERER_STATE_SYNC_INTERVAL)\n\n"
        "\trenderer.game_hour = _game_hour\n",
        "reloj de sincronización en _process",
    )
    process_text = indent_block(
        process_text,
        "\trenderer.game_hour = _game_hour\n",
        "\t# El mundo debe continuar aunque el jugador posea o siga a un enano.\n",
        "sync_renderer_state",
        "sincronización ambiental",
    )
    process_text = indent_block(
        process_text,
        "\tif legends_mode and legends != null:\n",
        "\trenderer.camera_pos = camera_pos\n",
        "sync_renderer_state",
        "sincronización de leyendas",
    )
    process_text = indent_block(
        process_text,
        "\tif dialogue != null:\n",
        "\t# El renderer controla su propia frecuencia de refresco. Redibujar aquí y\n",
        "sync_renderer_state",
        "sincronización de paneles",
    )
    text = text[:process_start] + process_text + text[process_end:]

    cache_marker = "\tvar _fortress_wealth_calc = 0.0\n"
    cache_code = (
        "\tvar _fortress_wealth_calc = 0.0\n"
        "\t# Una sola clasificación espacial/lógica por tick sustituye varios recorridos\n"
        "\t# completos de world.entities. Ninguna entidad deja de simularse.\n"
        "\tvar living_dwarves: Array = []\n"
        "\tvar living_people: Array = []\n"
        "\tvar living_hostiles: Array = []\n"
        "\tvar living_creatures: Array = []\n"
        "\tvar world_items: Array = []\n"
        "\tfor cached_entity: Variant in world.entities:\n"
        "\t\tif cached_entity is DFDwarf:\n"
        "\t\t\tif cached_entity.is_alive:\n"
        "\t\t\t\tliving_people.append(cached_entity)\n"
        "\t\t\t\tif str(cached_entity.get(\"creature_type\")) == \"dwarf\":\n"
        "\t\t\t\t\tliving_dwarves.append(cached_entity)\n"
        "\t\telif cached_entity is DFItem:\n"
        "\t\t\tworld_items.append(cached_entity)\n"
        "\t\telse:\n"
        "\t\t\tvar cached_type: Variant = cached_entity.get(\"creature_type\")\n"
        "\t\t\tvar cached_alive: Variant = cached_entity.get(\"is_alive\")\n"
        "\t\t\tif cached_type != null and str(cached_type) != \"\" and cached_alive == true:\n"
        "\t\t\t\tliving_creatures.append(cached_entity)\n"
        "\t\t\t\tif cached_entity.get(\"is_hostile\") == true:\n"
        "\t\t\t\t\tliving_hostiles.append(cached_entity)\n"
    )
    text = replace_once(text, cache_marker, cache_code, "clasificación de entidades")

    old_stats = (
        "\tif minute_ticked:\n"
        "\t\tfor e in world.entities:\n"
        "\t\t\tvar is_dwarf = e.get(\"creature_type\") == \"dwarf\"\n"
        "\t\t\tif is_dwarf and e.get(\"is_alive\") == true:\n"
        "\t\t\t\tdwarves_count += 1\n"
        "\t\t\t\tmil_strength += e.combat_skill\n"
        "\t\t\t\t_fortress_wealth_calc += 10.0\n"
        "\t\t\telif e is DFItem:\n"
        "\t\t\t\t_fortress_wealth_calc += 1.0\n"
    )
    new_stats = (
        "\tif minute_ticked:\n"
        "\t\tdwarves_count = living_dwarves.size()\n"
        "\t\tfor e: Variant in living_dwarves:\n"
        "\t\t\tmil_strength += float(e.combat_skill)\n"
        "\t\t\t_fortress_wealth_calc += 10.0\n"
        "\t\t_fortress_wealth_calc += float(world_items.size())\n"
    )
    text = replace_once(text, old_stats, new_stats, "estadísticas de fortaleza")

    text = replace_loop_once(text, "\t\tfor e3 in world.entities:\n", "\t\tfor e3 in living_hostiles:\n", "hostiles de combate")
    text = replace_loop_once(text, "\t\t\t\tfor e3b in world.entities:\n", "\t\t\t\tfor e3b in living_dwarves:\n", "objetivos de combate")
    text = replace_loop_once(text, "\tfor e4 in world.entities:\n", "\tfor e4 in living_people:\n", "personas activas")
    text = replace_loop_once(text, "\t\tfor e5 in world.entities:\n", "\t\tfor e5 in living_people:\n", "reproducción")
    text = replace_loop_once(text, "\t\tfor e6 in world.entities:\n", "\t\tfor e6 in living_creatures:\n", "criaturas ecológicas")
    text = replace_loop_once(text, "\t\tfor e7 in world.entities:\n", "\t\tfor e7 in world_items:\n", "degradación de objetos")

    text = replace_once(
        text,
        "\t_recover_orphaned_jobs()\n\t_cleanup_completed_jobs()\n",
        "\t# La vigilancia de trabajos no requiere ejecutarse diez veces por segundo.\n"
        "\tif _absolute_simulation_tick % 5 == 0:\n"
        "\t\t_recover_orphaned_jobs()\n"
        "\t\t_cleanup_completed_jobs()\n",
        "mantenimiento de trabajos",
    )

    text = indent_block(
        text,
        "\t# Check for historical figure/beast deaths to update chronicle DB\n",
        "\nfunc _recover_orphaned_jobs() -> void:\n",
        "_absolute_simulation_tick % 10 == 0",
        "actualización histórica",
    )

    summary_start = "\tif world.invasion_system != null:\n\t\trenderer._invasion_status = world.invasion_system.get_invasion_status()\n"
    summary_end = "\n\tif quest_system != null and minute_ticked:\n"
    text = indent_block(text, summary_start, summary_end, "_absolute_simulation_tick % 5 == 0", "resumen lateral")

    return text


def wrap_matching_draw_calls(draw_text: str, pattern: str) -> str:
    regex = re.compile(pattern, re.MULTILINE)

    def repl(match: re.Match[str]) -> str:
        indent = match.group(1)
        line = match.group(0).lstrip("\t ")
        return f"{indent}if performance_effects_enabled:\n{indent}\t{line}"

    return regex.sub(repl, draw_text)


def patch_renderer() -> str:
    source_path = ROOT / "df_mode" / "df_renderer.gd"
    text = source_path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "const MAP_REDRAW_INTERVAL: float = 1.0 / 60.0\nvar _map_redraw_accumulator: float = 0.0\n",
        "const MAP_REDRAW_INTERVAL: float = 1.0 / 60.0\n"
        "const RENDERER_LOGIC_SYNC_INTERVAL: float = 1.0 / 30.0\n"
        "var _map_redraw_accumulator: float = 0.0\n"
        "var _renderer_logic_accumulator: float = 0.0\n"
        "var performance_effects_enabled: bool = false\n"
        "var performance_overlay_enabled: bool = false\n"
        "var _last_visible_entity_count: int = 0\n",
        "configuración de rendimiento del renderer",
    )

    process_start, process_end = function_slice(text, "_process(delta: float) -> void:")
    process_text = text[process_start:process_end]
    process_text = replace_once(
        process_text,
        "\t_map_redraw_accumulator += delta\n",
        "\t_map_redraw_accumulator += delta\n\t_renderer_logic_accumulator += delta\n",
        "acumulador lógico del renderer",
    )
    process_text = replace_once(
        process_text,
        "\t# Sync data del mundo al renderer cada frame\n",
        "\tif _renderer_logic_accumulator < RENDERER_LOGIC_SYNC_INTERVAL:\n"
        "\t\treturn\n"
        "\t_renderer_logic_accumulator = fmod(_renderer_logic_accumulator, RENDERER_LOGIC_SYNC_INTERVAL)\n\n"
        "\t# Datos ambientales y cursor: 30 Hz son suficientes y evitan trabajo repetido.\n",
        "limitador de lógica visual",
    )
    text = text[:process_start] + process_text + text[process_end:]

    text = replace_once(
        text,
        "\tvar visible_entities: Array = _rebuild_entity_cache(cam_x, cam_z, vw, vh, cam_y)\n",
        "\tvar visible_entities: Array = _rebuild_entity_cache(cam_x, cam_z, vw, vh, cam_y)\n"
        "\t_last_visible_entity_count = visible_entities.size()\n",
        "contador de entidades visibles",
    )

    text = replace_once(
        text,
        "\tif world != null and world.workshops != null:\n\t\tfor ws_item in world.workshops:\n\t\t\t# Precompute 3x3 area around workshop for background darkening\n",
        "\tif world != null and world.workshops != null:\n"
        "\t\tfor ws_item in world.workshops:\n"
        "\t\t\tvar ws_pos: Vector3i = ws_item.tile_pos\n"
        "\t\t\tif ws_pos.x < cam_x - 4 or ws_pos.x > cam_x + vw + 4 or ws_pos.z < cam_z - 4 or ws_pos.z > cam_z + vh + 4 or ws_pos.y != cam_y:\n"
        "\t\t\t\tcontinue\n"
        "\t\t\t# Precompute 3x3 area around workshop for background darkening\n",
        "filtro de talleres visibles",
    )

    draw_start, draw_end = function_slice(text, "_draw() -> void:")
    draw_text = text[draw_start:draw_end]
    draw_text = replace_once(
        draw_text,
        "\tif _tileset == null:\n\t\treturn\n",
        "\tif _tileset == null:\n\t\treturn\n\tvar effect_time_ms: float = float(Time.get_ticks_msec())\n",
        "reloj visual único",
    )
    draw_text = draw_text.replace("Time.get_ticks_msec()", "effect_time_ms")

    draw_text = wrap_matching_draw_calls(
        draw_text,
        r"(?m)^(\s*)draw_circle\(char_pos \+ _char_size / 2\.0, glow_r, Color\(1\.0, 0\.3, 0\.0, glow_alpha\)\)$",
    )

    ao_start = "\t\t\t\t# Draw ambient occlusion (3D wall shadows) on floor tiles next to walls\n"
    ao_end = "\n\t\t\t\t# Draw pulsating miasma gas cloud particles on top\n"
    if ao_start in draw_text and ao_end in draw_text:
        start = draw_text.index(ao_start)
        end = draw_text.index(ao_end, start)
        block = draw_text[start:end]
        indented = "".join(("\t" + line if line.strip() else line) for line in block.splitlines(keepends=True))
        draw_text = draw_text[:start] + "\t\t\t\tif performance_effects_enabled:\n" + indented + draw_text[end:]
    else:
        fail("bloque de oclusión ambiental no encontrado")

    miasma_start = "\t\t\t\t# Draw pulsating miasma gas cloud particles on top\n"
    miasma_end = "\n\t\t\t\t# Entity HP bar (small bar below creatures with health data)\n"
    if miasma_start in draw_text and miasma_end in draw_text:
        start = draw_text.index(miasma_start)
        end = draw_text.index(miasma_end, start)
        block = draw_text[start:end]
        indented = "".join(("\t" + line if line.strip() else line) for line in block.splitlines(keepends=True))
        draw_text = draw_text[:start] + "\t\t\t\tif performance_effects_enabled:\n" + indented + draw_text[end:]
    else:
        fail("bloque de miasma no encontrado")

    draw_text = replace_once(
        draw_text,
        "\telif show_sidebar and world != null:\n\t\tvar side_x = border_x + vw * _char_size.x + 8\n\t\t_draw_sidebar(side_x)\n",
        "\telif show_sidebar and world != null:\n"
        "\t\tvar side_x = border_x + vw * _char_size.x + 8\n"
        "\t\t_draw_sidebar(side_x)\n"
        "\tif performance_overlay_enabled:\n"
        "\t\t_draw_performance_overlay()\n",
        "panel de rendimiento",
    )

    text = text[:draw_start] + draw_text + text[draw_end:]

    text += (
        "\n\n# ---- DIAGNÓSTICO DE RENDIMIENTO ----\n"
        "func _unhandled_key_input(event: InputEvent) -> void:\n"
        "\tif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:\n"
        "\t\tperformance_overlay_enabled = not performance_overlay_enabled\n"
        "\t\tqueue_redraw()\n"
        "\t\tget_viewport().set_input_as_handled()\n\n"
        "func _draw_performance_overlay() -> void:\n"
        "\tvar total_entities: int = world.entities.size() if world != null else 0\n"
        "\tvar lines: Array[String] = [\n"
        "\t\t\"FPS: %d\" % Engine.get_frames_per_second(),\n"
        "\t\t\"Entidades visibles: %d / %d\" % [_last_visible_entity_count, total_entities],\n"
        "\t\t\"Efectos costosos: %s\" % (\"ACTIVOS\" if performance_effects_enabled else \"DESACTIVADOS\"),\n"
        "\t\t\"F3: cerrar diagnóstico\"\n"
        "\t]\n"
        "\tvar panel_pos := Vector2(12, 12)\n"
        "\tvar panel_size := Vector2(260, 20 + lines.size() * 18)\n"
        "\tdraw_rect(Rect2(panel_pos, panel_size), Color(0.0, 0.0, 0.0, 0.82), true)\n"
        "\tdraw_rect(Rect2(panel_pos, panel_size), Color(0.75, 0.75, 0.75, 0.9), false, 1.0)\n"
        "\tfor line_index in range(lines.size()):\n"
        "\t\tdraw_string(_font, panel_pos + Vector2(8, 18 + line_index * 18), lines[line_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)\n"
    )

    return text


def write_patch_file(relative_path: str, content: str) -> None:
    destination = PATCH_ROOT / relative_path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8", newline="\n")


def main() -> None:
    if BUILD.exists():
        shutil.rmtree(BUILD)
    PATCH_ROOT.mkdir(parents=True)
    DIST.mkdir(exist_ok=True)

    main_text = patch_main()
    renderer_text = patch_renderer()
    write_patch_file("df_mode/df_main.gd", main_text)
    write_patch_file("df_mode/df_renderer.gd", renderer_text)

    readme = """BIGLIWORLD — OPTIMIZACIÓN FASE 1
===================================

INSTALACIÓN
1. Cierra Godot.
2. Extrae este ZIP directamente en:
   F:\\cacaneitor3000\\Bigliworld\\
3. Acepta reemplazar los archivos.
4. Elimina la carpeta .godot del proyecto.
5. Abre Godot y prueba primero una partida nueva y luego tu guardado actual.

QUÉ CAMBIA
- No elimina habitantes ni reduce su inteligencia.
- Todos los aldeanos conservan inventario, necesidades, trabajo, familia, relaciones y posición.
- Clasifica entidades una sola vez por tick y reutiliza esas listas.
- Evita búsquedas cuadráticas innecesarias en el combate.
- Actualiza paneles y datos ambientales a 20–30 Hz en vez de duplicarlos en cada frame.
- Revisa trabajos huérfanos y crónicas con frecuencias razonables.
- Solo prepara talleres visibles para el dibujo.
- Desactiva por defecto efectos gráficos costosos por tile: halos, oclusión y nubes animadas.
- F3 abre un panel con FPS y entidades visibles.

IMPORTANTE
Los efectos costosos desactivados son puramente visuales. La simulación no se simplifica.
Este parche es la Fase 1. El índice espacial de recursos y la caché jerárquica de rutas irán en la Fase 2 después de comprobar los FPS reales.
"""
    changes = """ARCHIVOS MODIFICADOS
- df_mode/df_main.gd
- df_mode/df_renderer.gd

CUELLOS DE BOTELLA CORREGIDOS
1. Múltiples recorridos completos de world.entities durante el mismo tick.
2. Búsqueda hostil × todos los objetos del mundo en combate.
3. Copia de estados, arrays de misiones y paneles cada frame.
4. Preparación de talleres fuera de cámara durante cada redibujado.
5. Efectos por tile con senos, círculos, bordes y consultas vecinas cada frame.
6. Limpieza de trabajos y revisión histórica demasiado frecuentes.

VALIDACIÓN
El constructor verifica marcadores esperados, funciones duplicadas y delimitadores balanceados.
No se ejecuta Godot en GitHub Actions; cualquier primer error rojo debe reportarse con archivo y línea exactos.
"""
    write_patch_file("LEEME_PRIMERO.txt", readme)
    write_patch_file("CAMBIOS_TECNICOS.txt", changes)

    validate_gdscript(PATCH_ROOT / "df_mode/df_main.gd")
    validate_gdscript(PATCH_ROOT / "df_mode/df_renderer.gd")

    archive = DIST / "Bigliworld_optimizacion_fase1.zip"
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for file_path in sorted(PATCH_ROOT.rglob("*")):
            if file_path.is_file():
                output.write(file_path, file_path.relative_to(PATCH_ROOT))
    print(f"Parche creado: {archive} ({archive.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
