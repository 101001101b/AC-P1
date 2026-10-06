# Práctica 1 AC — Simulador Superscalar SimpleScalar

Análisis del rendimiento de dos procesadores (AMD Zen 5 y Intel Cougar Cove)
mediante el simulador `sim-outorder` de SimpleScalar, ejecutando 5 benchmarks
SPEC CPU2000 (bzip2, ammp, gap, swim, vpr).

## Estructura del proyecto

- `scripts/` — scripts de simulación y comparación.
- `specwork/` — binarios e inputs de los benchmarks (autosuficiente, no
  depende de `/lib/specs2000`).
- `results/` — resultados por variante y ejecución.
  - `<variante>/run_<timestamp>/` — cada lanzamiento en su propia carpeta.
  - `_comparativa/` — CSVs y gráficas comparativas.

## Cómo ejecutar

```bash
# Todas las variantes + comparativa (tarda ~1-2 h)
./scripts/run_all.sh

# Una sola variante
./scripts/amd_zen5.sh
./scripts/amd_zen5_L2_2MB.sh
# etc.

# Solo la comparativa (si ya tienes los resultados)
./scripts/compare.sh