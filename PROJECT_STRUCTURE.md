# Organización de Bigliworld

La estructura nueva está creada sin mover todavía el código que funciona. `df_mode/` sigue siendo el juego actual y conserva todas sus rutas, escenas y datos; por eso el proyecto no pierde compatibilidad.

## Carpetas nuevas

| Carpeta | Responsabilidad | Código actual que migrará después |
|---|---|---|
| `core/simulation/` | Tiempo, entidades, necesidades y guardado de estado | `df_world.gd`, partes de `df_main.gd` |
| `core/ai/` | Decisiones, comportamiento, percepción y grupos | `df_creature.gd`, `df_dwarf.gd` |
| `core/combat/` | Daño, heridas, armas y conflictos | `df_combat.gd`, `df_military.gd` |
| `core/ecology/` | Presas, depredadores, reproducción y migración | lógica de criaturas y plantas |
| `core/economy/` | Recursos, producción, comercio y precios | materiales, objetos, caravanas y talleres |
| `core/jobs/` | Trabajos, prioridades y construcción | `df_job.gd`, `df_workshop.gd` |
| `core/pathfinding/` | Rutas y movimiento | `df_pathfinding.gd` |
| `core/diplomacy/` | Facciones, relaciones, guerra y comercio | `df_entities.gd`, invasiones y caravanas |
| `database/` | Datos que añaden o reemplazan contenido sin código | contenido nuevo en JSON o `DFContentDefinition` |
| `world/` | Escenas y sistemas de mapa/generación | `df_world_gen.gd`, `df_world.gd` |
| `ui/` | Menús, pantallas y paneles del jugador | renderer, ajustes y leyendas |
| `resources/` | Recursos compartidos no pertenecientes a una categoría | futuros temas, configuraciones y plantillas |
| `mods/` | Mods del usuario; se cargan automáticamente | paquetes de datos externos |
| `saves/` | Plantillas y herramientas de guardado; partidas reales siguen en `user://` | `df_save_load.gd` |

## Dónde añadir datos ahora

Puedes poner JSON de criaturas, objetos o materiales tanto en `database/` como en `mods/`. El cargador ya explora esas dos carpetas, además de las rutas antiguas `df_mode/content_packs/` y `df_mode/mods/`.

Ejemplo recomendado: `database/creatures/giant_wolf.json`.

## Regla de migración

No se mueve un archivo grande de `df_mode/` hasta extraer primero una interfaz estable y actualizar sus referencias. Así cada etapa se puede probar y revertir fácilmente. El catálogo de contenido ya usa `core/content/`; las rutas antiguas permanecen como compatibilidad. Las reglas puras de depredador/presa y huida viven en `core/ecology/`, percepción/distancia/activación de disparadores viven en `core/ai/`, y las fórmulas de daño viven en `core/combat/`. Los siguientes bloques serán mundo, trabajos y UI.
