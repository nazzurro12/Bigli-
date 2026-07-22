import os

path = r'F:\cacaneitor3000\Bigliworld\df_mode\df_renderer.gd'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

# 1. Add quest log variables after fast travel variables (after var _fast_travel_dest_z)
inserted_vars = False
for i, line in enumerate(lines):
    if line.strip().startswith('var _fast_travel_dest_z') and not inserted_vars:
        quest_vars = [
            '',
            '\tvar _quest_log_open: bool = false',
            '\tvar _quest_active_quests: Array = []',
            '\tvar _quest_completed_count: int = 0',
            '\tvar _quest_active_count: int = 0',
            '\tvar _quest_notification: String = ""',
            '\tvar _quest_selected: int = 0',
        ]
        for j, qv in enumerate(quest_vars):
            lines.insert(i + 1 + j, qv)
        inserted_vars = True
        print(f'Added quest vars after line {i+1}')
        break

# 2. Find the _draw_fast_travel_overlay call in _draw() and add quest log overlay call before it
inserted_call = False
for i, line in enumerate(lines):
    if '_draw_fast_travel_overlay()' in line and not inserted_call:
        indent = line[:len(line) - len(line.lstrip())]
        # Add quest notification draw call and quest log overlay
        lines.insert(i, indent + '_draw_quest_notification()')
        lines.insert(i, indent + 'if _quest_log_open:')
        lines.insert(i+2, indent + '\t_draw_quest_log_overlay()')
        inserted_call = True
        print(f'Added quest overlay calls before fast travel overlay at line {i+1}')
        break

# 3. Find after _draw_fast_travel_message_box to add _draw_quest_log_overlay and _draw_quest_notification
inserted_funcs = False
for i in range(len(lines) - 1, 0, -1):
    line_stripped = lines[i].strip()
    if line_stripped.startswith('func _draw_fast_travel_message_box') and not inserted_funcs:
        # Find where this function ends (next function or end of file)
        insert_pos = -1
        for j in range(i + 1, len(lines)):
            ln_stripped = lines[j].strip()
            if ln_stripped.startswith('func ') and j > i:
                insert_pos = j
                break
            if j == len(lines) - 1:
                insert_pos = j + 1
                break
        
        if insert_pos > 0:
            ql_func = [
                '',
                '',
                '# ---- Quest Log Overlay ----',
                'func _draw_quest_log_overlay() -> void:',
                '\tvar vw = int(size.x)',
                '\tvar vh = int(size.y)',
                '\tvar border_x = int(vw * 0.15)',
                '\tvar panel_w = int(vw * 0.7)',
                '\tvar panel_h = int(vh * 0.75)',
                '\tvar panel_x = border_x',
                '\tvar panel_y = int(vh * 0.08)',
                '\t',
                '\t# Fondo del panel',
                '\tdraw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.0, 0.0, 0.0, 0.85))',
                '\tdraw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.4, 0.3, 0.15, 0.9), false, 2.0)',
                '\t',
                '\t# Titulo',
                '\t_draw_word_wrap("REGISTRO DE MISIONES", panel_x + 10, panel_y + 8, Color(1.0, 0.8, 0.3), 16, panel_w - 20)',
                '\tvar title_end_y = panel_y + 28',
                '\t',
                '\t# Separador',
                '\tdraw_line(Vector2(panel_x + 4, title_end_y), Vector2(panel_x + panel_w - 4, title_end_y), Color(0.6, 0.5, 0.3, 0.8), 1.0)',
                '\t',
                '\t# Stats header',
                '\tvar header = "Activas: %d  |  Completadas: %d" % [_quest_active_count, _quest_completed_count]',
                '\t_draw_word_wrap(header, panel_x + 10, title_end_y + 6, Color(0.8, 0.8, 0.8), 14, panel_w - 20)',
                '\tvar content_y = title_end_y + 28',
                '\tvar line_h = 20',
                '\t',
                '\t# Contenido: misiones activas',
                '\tif _quest_active_quests.size() > 0:',
                '\t\tdraw_string(_font, Vector2(panel_x + 12, content_y), "--- ACTIVAS ---", HALIGN_LEFT, -1, 14, Color(0.6, 1.0, 0.6))',
                '\t\tcontent_y += line_h',
                '\t\tvar idx = 0',
                '\t\tfor q in _quest_active_quests:',
                '\t\t\tif content_y > panel_y + panel_h - 20:',
                '\t\t\t\tbreak',
                '\t\t\tvar is_selected = idx == _quest_selected',
                '\t\t\tvar type_name = ""',
                '\t\t\tvar qtype = q.get("type", -1)',
                '\t\t\tmatch qtype:',
                '\t\t\t\t0: type_name = "Eliminar"',
                '\t\t\t\t1: type_name = "Recolectar"',
                '\t\t\t\t2: type_name = "Explorar"',
                '\t\t\t\t3: type_name = "Construir"',
                '\t\t\t\t4: type_name = "Entregar"',
                '\t\t\tvar ttl = q.get("title", "?")',
                '\t\t\tvar tgt = q.get("target_count", 0)',
                '\t\t\tvar cur = q.get("current_count", 0)',
                '\t\t\tvar line_color = Color(0.9, 0.9, 0.9)',
                '\t\t\tif is_selected:',
                '\t\t\t\tdraw_rect(Rect2(panel_x + 4, content_y - 14, panel_w - 8, line_h), Color(0.3, 0.3, 0.4, 0.5))',
                '\t\t\t\tline_color = Color(1.0, 1.0, 0.5)',
                '\t\t\tvar line_str = "%s - %s [%d/%d]" % [type_name, ttl, cur, tgt]',
                '\t\t\t_draw_word_wrap(line_str, panel_x + 14, content_y, line_color, 13, panel_w - 40)',
                '\t\t\tcontent_y += line_h',
                '\t\t\tidx += 1',
                '\telse:',
                '\t\t_draw_word_wrap("(No hay misiones activas. Espera a que el mundo genere algunas.)", panel_x + 14, content_y + 4, Color(0.6, 0.6, 0.6), 13, panel_w - 30)',
                '\t\tcontent_y += line_h + 4',
                '\t',
                '\t# Seccion: Completadas',
                '\tif _quest_completed_count > 0 and content_y < panel_y + panel_h - 30:',
                '\t\tcontent_y += 4',
                '\t\tdraw_string(_font, Vector2(panel_x + 12, content_y), "--- COMPLETADAS (%d) ---" % _quest_completed_count, HALIGN_LEFT, -1, 14, Color(0.6, 0.6, 1.0))',
                '\t',
                '\t# Ayuda inferior',
                '\tdraw_string(_font, Vector2(panel_x + 10, panel_y + panel_h - 6), "Flechas: Navegar  |  J/ESC: Cerrar", HALIGN_LEFT, -1, 12, Color(0.6, 0.6, 0.6))',
                '',
                '',
                '# ---- Quest Notification ----',
                'func _draw_quest_notification() -> void:',
                '\tif _quest_notification == "":',
                '\t\treturn',
                '\tvar vw = int(size.x)',
                '\tvar vh = int(size.y)',
                '\tvar notif_w = int(vw * 0.5)',
                '\tvar notif_x = int((vw - notif_w) / 2)',
                '\tvar notif_y = 4',
                '\tvar notif_h = 28',
                '\t',
                '\tdraw_rect(Rect2(notif_x, notif_y, notif_w, notif_h), Color(0.0, 0.0, 0.0, 0.7))',
                '\tdraw_rect(Rect2(notif_x, notif_y, notif_w, notif_h), Color(0.6, 0.5, 0.2, 0.9), false, 1.0)',
                '\t_draw_word_wrap(_quest_notification, notif_x + 8, notif_y + 6, Color(1.0, 0.9, 0.5), 14, notif_w - 16)',
            ]
            for j, ql in enumerate(ql_func):
                lines.insert(insert_pos + j, ql)
            inserted_funcs = True
            print(f'Added quest overlay functions before line {insert_pos+1}')
        break

if not inserted_funcs:
    print("ERROR: Could not find insertion point for quest overlay functions")

if not inserted_vars:
    print("ERROR: Could not find insertion point for quest vars")

if not inserted_call:
    print("ERROR: Could not find insertion point for quest overlay call")

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'df_renderer.gd updated successfully ({len(lines)} lines)')
