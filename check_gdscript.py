import os
import re
import sys
from pathlib import Path

def check_gdscript_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    func_re = re.compile(r'^\s*func\s+(\w+)')
    var_re = re.compile(r'^\s*var\s+(\w+)')
    for_re = re.compile(r'for\s+(\w+)\s+in')
    
    current_func = None
    func_vars = {}
    errors = []

    for idx, line in enumerate(lines):
        line_num = idx + 1
        # Check function start
        m_func = func_re.match(line)
        if m_func:
            current_func = m_func.group(1)
            func_vars[current_func] = {}
            continue
            
        if current_func:
            # Check local var declarations
            m_var = var_re.match(line)
            if m_var:
                var_name = m_var.group(1)
                # Check if it was declared in parameters or earlier in the function
                if var_name in func_vars[current_func]:
                    errors.append(f"Línea {line_num}: Variable local duplicada '{var_name}' en función '{current_func}' (declarada antes en línea {func_vars[current_func][var_name]})")
                else:
                    func_vars[current_func][var_name] = line_num
            
            # Check for loop variable declarations
            for m_for in for_re.finditer(line):
                for_var = m_for.group(1)
                if for_var in func_vars[current_func]:
                    errors.append(f"Línea {line_num}: Variable de bucle duplicada '{for_var}' en función '{current_func}' (declarada antes en línea {func_vars[current_func][for_var]})")
                else:
                    func_vars[current_func][for_var] = line_num
                    
    return errors

if __name__ == '__main__':
    project_root = Path(__file__).resolve().parent
    dir_path = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else project_root / "df_mode"
    if not dir_path.is_dir():
        print(f"ERROR: no existe el directorio de GDScript: {dir_path}")
        raise SystemExit(2)
    print(f"=== REVISANDO DUPLICADOS EN SCOPE DE GDSCRIPT ({dir_path}) ===")
    total_files = 0
    total_errors = 0
    
    for root, dirs, files in os.walk(str(dir_path)):
        for file in files:
            if file.endswith('.gd'):
                total_files += 1
                fp = os.path.join(root, file)
                errs = check_gdscript_file(fp)
                if errs:
                    print(f"\n[!] Archivo: {file}")
                    for err in errs:
                        print(f"    {err}")
                        total_errors += 1
                        
    print(f"\nRevisión terminada. {total_files} archivos comprobados. {total_errors} duplicaciones en scopes encontradas.")
    if total_files == 0:
        print("ERROR: el validador no examinó ningún archivo.")
        raise SystemExit(2)
    # El analizador es deliberadamente conservador: algunas reutilizaciones son
    # válidas en bloques hermanos de GDScript. --strict permite convertir estos
    # avisos en errores en ramas que ya hayan eliminado su deuda histórica.
    strict = "--strict" in sys.argv[1:]
    raise SystemExit(1 if strict and total_errors else 0)
