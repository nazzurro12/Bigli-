from pathlib import Path
import re
import build_performance_patch as builder


# Conservamos el renderer optimizado generado por el constructor, pero corregimos
# la sustitución circular de effect_time_ms. Para df_main usamos la versión estable
# de la rama base: el primer constructor envolvió bloques de _process() de forma
# demasiado agresiva y produjo una indentación inválida en Godot.
_original_patch_renderer = builder.patch_renderer


def repaired_patch_main() -> str:
    source_path = builder.ROOT / "df_mode" / "df_main.gd"
    return source_path.read_text(encoding="utf-8")


def repaired_patch_renderer() -> str:
    text = _original_patch_renderer()
    broken = "var effect_time_ms: float = float(effect_time_ms)"
    fixed = "var effect_time_ms: float = float(Time.get_ticks_msec())"
    if broken not in text:
        raise RuntimeError("No se encontró la declaración circular de effect_time_ms")
    return text.replace(broken, fixed, 1)


def safe_validate(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    functions = re.findall(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(", text)
    duplicates = sorted({name for name in functions if functions.count(name) > 1})
    if duplicates:
        raise RuntimeError(f"{path}: funciones duplicadas: {duplicates}")
    if "\r" in text:
        raise RuntimeError(f"{path}: contiene retornos CR inesperados")

    # Comprobación mínima adicional para los dos fallos detectados por Godot.
    if path.name == "df_renderer.gd" and broken_declaration_present(text):
        raise RuntimeError(f"{path}: effect_time_ms se usa en su propia declaración")


def broken_declaration_present(text: str) -> bool:
    return "var effect_time_ms: float = float(effect_time_ms)" in text


builder.patch_main = repaired_patch_main
builder.patch_renderer = repaired_patch_renderer
builder.validate_gdscript = safe_validate
builder.main()
