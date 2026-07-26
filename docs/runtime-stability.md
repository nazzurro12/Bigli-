# Puerta de estabilidad de Bigli

Esta prueba valida el proyecto con el motor real antes de continuar ampliando la simulación.

## Ejecutar en Windows

Desde la raíz del proyecto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_godot_smoke.ps1 -GodotPath "C:\ruta\Godot_v4.7-stable_win64.exe"
```

Si Godot está instalado en `C:\Program Files\Godot` o disponible como comando `godot`, puede omitirse `-GodotPath`.

La puerta realiza tres fases:

1. Ejecuta el verificador de ámbitos en modo estricto y rechaza variables locales ambiguas.
2. Importa el proyecto en modo headless y rechaza errores de parseo o carga.
3. Carga todos los scripts, instancia `df_mode/df_main.tscn` y permite varios fotogramas de inicialización.

Los registros quedan en `test-results/`. La actualización no debe continuar al siguiente bloque mientras esta prueba falle.

## Criterio del Bloque 0

- cero variables locales duplicadas en el mismo ámbito;
- cero errores de parseo;
- cero scripts que no puedan cargarse;
- la escena principal puede instanciarse;
- el proceso termina con código cero;
- los errores quedan registrados de manera reproducible.
