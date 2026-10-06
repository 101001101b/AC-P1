#!/bin/bash
# ==============================================================================
# run_all.sh - Ejecuta TODAS las variantes y luego la comparativa
# ------------------------------------------------------------------------------
# Ejecuta cada script de variante que exista en scripts/ (excepto compare.sh y
# run_all.sh). Cada uno tarda ~5-10 min, así que el total es 1-2 horas.
#
# Si algún script no existe, lo salta con aviso (no aborta).
# Al final lanza compare.sh.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lista ordenada de variantes a ejecutar
VARIANTES=(
    amd_zen5.sh
    amd_zen5_mejorado_v1.sh
    intel_cougarcove.sh
    intel_mejorado_v1.sh
)
INICIO=$(date +%s)

for V in "${VARIANTES[@]}"; do
    SCRIPT="$SCRIPT_DIR/$V"
    if [ ! -x "$SCRIPT" ]; then
        echo ""
        echo "=== [SKIP] $V (no existe o no es ejecutable) ==="
        continue
    fi
    echo ""
    echo "##################################################################"
    echo "# EJECUTANDO: $V"
    echo "##################################################################"
    "$SCRIPT"
    if [ $? -ne 0 ]; then
        echo "  [WARN] $V terminó con errores. Se continúa con el siguiente."
    fi
done

echo ""
echo "##################################################################"
echo "# GENERANDO COMPARATIVA"
echo "##################################################################"
"$SCRIPT_DIR/compare.sh"

FIN=$(date +%s)
TOTAL=$((FIN - INICIO))
echo ""
echo "=================================================================="
echo " TODO COMPLETADO en $((TOTAL/60)) min $((TOTAL%60)) s"
echo "=================================================================="