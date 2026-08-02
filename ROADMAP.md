# Bigliworld - Roadmap de Desarrollo Actualizado

> **Proyecto**: Clon de Dwarf Fortress en Godot 4.7
> **Corpus**: `nazzurro12/Bigli-`
> **Estado**: **FASE 1 COMPLETADA Y REFACTORIZADA CON TIPADO ESTRICTO** (2026-08-02)

---

## 🟢 FASE 0 - Estabilización Base (COMPLETADA)
- ✅ Reparación de asignación de trabajos y herramientas en colonos.
- ✅ Rebalanceo de pataletas y tolerancia al estrés.
- ✅ Autonomía de búsqueda de alimentos y bebidas en almacenes.
- ✅ Corrección de crashes de métodos dinámicos en `RefCounted`.

---

## 🟢 FASE 1 - Autonomía Enana, Viviendas Multi-Ambiente y Limpieza (COMPLETADA)

| # | Sistema | Descripción | Estado |
|---|---------|-------------|--------|
| **1.1** | **Movimiento Individual Fluido** | Desincronización del contador de pasos (`move_tick_counter`) por enano para eliminar el avance robótico global en grupo. | ✅ Completado |
| **1.2** | **Casas Multi-Habitación Cómodas** | Rediseño de planos en `df_world_sites.gd` para viviendas de 3 estancias (Recibidor/Comedor, Dormitorio privado con cama y baúl, Despensa/Higiene). | ✅ Completado |
| **1.3** | **Economía Laboral por Monedas (`coins`)** | Salarios en monedas por trabajo realizado; necesidad de costear raciones y cerveza enana en almacenes/taberna. | ✅ Completado |
| **1.4** | **Digestión y Letrinas (`latrine_need`)** | Procesamiento de alimentos ingeridos y búsqueda de letrinas o privados para mantener la higiene corporal. | ✅ Completado |
| **1.5** | **Muerte, Funerales, Miasma y Fantasmas** | Descomposición de cadáveres con miasma pestilente, funerales en ataúdes y aparición de fantasmas si no hay entierro. | ✅ Completado |
| **1.6** | **Tipado Estricto (Type Hints) y Purga** | Adición de tipos GDScript (`-> void`, `: Vector3i`, `: Object`) en más de 300 funciones y eliminación de archivos obsoletos de depuración. | ✅ Completado |

---

## 🟡 FASE 2 - Cavernas Profundas y Bestias Olvidadas (PRÓXIMA ENTREGA)

| # | Sistema | Descripción | Prioridad |
|---|---------|-------------|-----------|
| **2.1** | **Cavernas Subterráneas de 3 Capas** | 3 niveles profundos con bosques de hongos gigantes (*Tower Caps*), lagos abisales y vegetación micológica. | 🔴 Alta |
| **2.2** | **Bestias Olvidadas Procedurales** | Generación de monstruos antiguos con formas corporales, aliento de fuego, nubes tóxicas y registro histórico en crónicas. | 🔴 Alta |
| **2.3** | **Vetas de Adamantina y Magma** | Minería de metales legendarios en las profundidades y forjas de magma. | 🟡 Media |

---

## 🟡 FASE 3 - Nobleza, Mandatos y Clima Dinámico (FUTURO CERCANO)

| # | Sistema | Descripción | Prioridad |
|---|---------|-------------|-----------|
| **3.1** | **Rango de Colonia y Nobleza** | Evaluación de riqueza total; elevación a Baronía, Condado y Reino con nombramiento de nobles. | 🟡 Media |
| **3.2** | **Mandatos y Decretos Reales** | Leyes temporales emitidas por nobles (prohibición de exportar metales, órdenes de forja de armas) con sanciones. | 🟡 Media |
| **3.3** | **Clima Dinámico y Partículas** | Lluvia, ventiscas de nieve, niebla de esporas y ceniza volcánica con animación visual en pantalla. | 🟢 Baja |

---

## 📈 Resumen Técnico de la Base de Código

- **Archivos GDScript**: 77 archivos limpios en `df_mode/` y `core/`.
- **Clases del Motor**: 67 `class_names` registrados.
- **Tipado Estricto**: Cobertura completa en combate, IA, consecuencias y renderizado.
- **Archivos Temporales**: 0 archivos residuales.
