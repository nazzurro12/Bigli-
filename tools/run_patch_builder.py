from pathlib import Path
import re
import build_performance_patch as builder


def safe_validate(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    functions = re.findall(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(", text)
    duplicates = sorted({name for name in functions if functions.count(name) > 1})
    if duplicates:
        raise RuntimeError(f"{path}: funciones duplicadas: {duplicates}")
    if "\r" in text:
        raise RuntimeError(f"{path}: contiene retornos CR inesperados")


builder.validate_gdscript = safe_validate
builder.main()
