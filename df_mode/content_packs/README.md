# Contenido ampliable de Bigliworld

Bigliworld carga automáticamente recursos desde estas carpetas:

- `df_mode/content_packs/`: contenido propio del juego.
- `df_mode/mods/`: contenido de mods.

## Opción visual: Resource de Godot

En el panel **FileSystem**: clic derecho → **Create New Resource** → `DFContentDefinition`.
Configura `category`, un `id` único y los campos de `data` que usa el juego. Por ejemplo, una criatura usa `tile`, `color`, `size` y `biomes`.

### Campos de criatura disponibles

Además de `id`, `name`, `tile`, `color`, `size` y `biomes`, puedes controlar:

- Combate: `max_hp` (0–100), `attack_damage`, `armor`, `move_speed`, `sight_range`, `hearing_range`.
- Conducta: `aggression` (`passive`, `territorial`, `hostile`, `predator`), `attack_triggers`, `flee_hp_threshold`, `group_behavior`, `nocturnal`.
- Ecología: `prey_types`, `predator_types`, `competition_types` (listas de IDs).
- Aparición: `spawn_group_min`, `spawn_group_max`, `spawn_weight`, `day_spawn`, `night_spawn`.
- Asentamiento: `has_settlement`, `settlement_type`, `settlement_size`, `settlement_chance`, `patrol_radius`.

Los disparadores actualmente conectados a la IA son `on_sight_player`, `on_sight_prey` y `on_attacked`. Los demás campos se guardan desde ahora como datos para los siguientes sistemas de aparición, asentamientos y ecología.

## Opción práctica: JSON

Copia `example_forest_animals.json`, cambia los valores y reinicia el juego. Se admiten estas categorías: `creatures`, `plants`, `materials`, `items`, `entities`, `buildings` y `reactions`.

Si el `id` coincide con uno del contenido base, el paquete lo reemplaza: sirve para balancear o modificar datos sin tocar archivos del motor. Si el `id` es nuevo, lo añade.

Los datos existentes del juego se conservan tal cual. Esta capa sólo añade o sustituye definiciones durante la carga de `DFData`.
