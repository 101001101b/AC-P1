#!/bin/bash
# ==============================================================================
# compare.sh - Genera comparativa de TODAS las variantes
# ------------------------------------------------------------------------------
# Junta los resultados de:
#   - todas las subcarpetas de results/
#   - tomando la ejecución (run_*) MÁS RECIENTE de cada variante
#
# Genera en results/_comparativa/:
#   - _comparativa_larga.csv     (una fila por variante × benchmark)
#   - _comparativa_IPC.csv       (formato ancho, para gnuplot)
#   - _comparativa_L2_miss.csv
#   - _comparativa_RUU_occ.csv
#   - _comparativa_LSQ_occ.csv
#   - _comparativa.md            (tabla Markdown lista para el informe)
#   - grafica_IPC.png            (barras agrupadas por benchmark)
#   - grafica_L2_miss.png
#   - grafica_RUU_occ.png
#   - grafica_LSQ_occ.png
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_ROOT="$PROJECT_DIR/results"
OUT_DIR="$RESULTS_ROOT/_comparativa"
mkdir -p "$OUT_DIR"

# Descubrir variantes (carpetas dentro de results/ que no empiecen por _)
VARIANTS=()
for d in "$RESULTS_ROOT"/*/; do
    name=$(basename "$d")
    [[ "$name" == _* ]] && continue
    [[ -d "$d" ]] && VARIANTS+=("$name")
done

if [ ${#VARIANTS[@]} -eq 0 ]; then
    echo "[ERROR] No hay variantes en $RESULTS_ROOT"
    exit 1
fi

echo "Variantes detectadas: ${VARIANTS[@]}"

# ==============================================================================
# 1. Construir CSV largo
# ==============================================================================
CSV_LARGO="$OUT_DIR/_comparativa_larga.csv"
echo "variante,benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,sim_cycle,sim_num_insn" > "$CSV_LARGO"

for V in "${VARIANTS[@]}"; do
    # Última ejecución (la más reciente alfabéticamente = la más nueva por timestamp)
    LATEST=$(ls -d "$RESULTS_ROOT/$V/run_"* 2>/dev/null | sort | tail -1)
    [ -z "$LATEST" ] && continue
    CSV="$LATEST/_resumen.csv"
    [ -f "$CSV" ] || continue
    tail -n +2 "$CSV" | sed "s/^/$V,/" >> "$CSV_LARGO"
done

echo "[OK] $CSV_LARGO"

# ==============================================================================
# 2. CSVs anchos por métrica (para gnuplot)
# ==============================================================================
BENCHMARKS=(bzip2 ammp gap swim vpr)

# IPC
{
    printf "benchmark"
    for V in "${VARIANTS[@]}"; do printf ",%s" "$V"; done
    printf "\n"
    for B in "${BENCHMARKS[@]}"; do
        printf "%s" "$B"
        for V in "${VARIANTS[@]}"; do
            VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $3}' "$CSV_LARGO")
            printf ",%s" "${VAL:-0}"
        done
        printf "\n"
    done
} > "$OUT_DIR/_comparativa_IPC.csv"

# L2_miss
{
    printf "benchmark"
    for V in "${VARIANTS[@]}"; do printf ",%s" "$V"; done
    printf "\n"
    for B in "${BENCHMARKS[@]}"; do
        printf "%s" "$B"
        for V in "${VARIANTS[@]}"; do
            VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $7}' "$CSV_LARGO")
            printf ",%s" "${VAL:-0}"
        done
        printf "\n"
    done
} > "$OUT_DIR/_comparativa_L2_miss.csv"

# RUU_occ
{
    printf "benchmark"
    for V in "${VARIANTS[@]}"; do printf ",%s" "$V"; done
    printf "\n"
    for B in "${BENCHMARKS[@]}"; do
        printf "%s" "$B"
        for V in "${VARIANTS[@]}"; do
            VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $9}' "$CSV_LARGO")
            printf ",%s" "${VAL:-0}"
        done
        printf "\n"
    done
} > "$OUT_DIR/_comparativa_RUU_occ.csv"

# LSQ_occ
{
    printf "benchmark"
    for V in "${VARIANTS[@]}"; do printf ",%s" "$V"; done
    printf "\n"
    for B in "${BENCHMARKS[@]}"; do
        printf "%s" "$B"
        for V in "${VARIANTS[@]}"; do
            VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $10}' "$CSV_LARGO")
            printf ",%s" "${VAL:-0}"
        done
        printf "\n"
    done
} > "$OUT_DIR/_comparativa_LSQ_occ.csv"

echo "[OK] CSVs anchos generados"

# ==============================================================================
# 3. Tabla Markdown
# ==============================================================================
MD="$OUT_DIR/_comparativa.md"
{
    echo "# Comparativa de variantes"
    echo ""
    echo "Generado: $(date)"
    echo ""
    echo "## IPC por benchmark y variante"
    echo ""
    printf "| Benchmark |"
    for V in "${VARIANTS[@]}"; do printf " %s |" "$V"; done
    printf "\n|---|"
    for V in "${VARIANTS[@]}"; do printf "---:|"; done
    printf "\n"
    for B in "${BENCHMARKS[@]}"; do
        printf "| **%s** |" "$B"
        for V in "${VARIANTS[@]}"; do
            VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $3}' "$CSV_LARGO")
            printf " %s |" "${VAL:--}"
        done
        printf "\n"
    done
    # Media
    printf "| **MEDIA** |"
    for V in "${VARIANTS[@]}"; do
        MEDIA=$(awk -F, -v v="$V" '$1==v {sum+=$3; n++} END {if(n>0) printf "%.4f", sum/n}' "$CSV_LARGO")
        printf " **%s** |" "${MEDIA:--}"
    done
    printf "\n"
} > "$MD"
echo "[OK] $MD"

# ==============================================================================
# 4. Gráficas gnuplot
# ==============================================================================
if ! command -v gnuplot >/dev/null 2>&1; then
    echo "[INFO] gnuplot no instalado, se saltan las gráficas"
    exit 0
fi

plot_metric() {
    local METRIC="$1"    # Nombre  para el título
    local FILE="$2"      # CSV ancho
    local OUT="$3"       # PNG de salida
    local YLABEL="$4"    # Etiqueta del eje Y
    local NCOL
    NCOL=$(head -1 "$FILE" | awk -F, '{print NF}')

    gnuplot -e "
        set datafile separator ',';
        set terminal pngcairo size 1400,600 font 'Arial,10';
        set style data histograms;
        set style histogram clustered gap 1;
        set style fill solid 1.0 border -1;
        set boxwidth 0.9;
        set xtics rotate by -20;
        set grid ytics;
        set ylabel '$YLABEL';
        set xlabel 'Benchmark';
        set title '${METRIC} por variante y benchmark';
        set key outside right;
        set output '$OUT';
        plot for [i=2:$NCOL] '$FILE' using i:xtic(1) title columnhead(i)
    " 2>/dev/null && echo "[OK] $OUT"
}

plot_metric "IPC"       "$OUT_DIR/_comparativa_IPC.csv"     "$OUT_DIR/grafica_IPC.png"     "IPC"
plot_metric "L2 miss"   "$OUT_DIR/_comparativa_L2_miss.csv" "$OUT_DIR/grafica_L2_miss.png" "L2 miss rate"
plot_metric "RUU occ"   "$OUT_DIR/_comparativa_RUU_occ.csv" "$OUT_DIR/grafica_RUU_occ.png" "RUU occupancy"
plot_metric "LSQ occ"   "$OUT_DIR/_comparativa_LSQ_occ.csv" "$OUT_DIR/grafica_LSQ_occ.png" "LSQ occupancy"

echo ""
echo "=================================================================="
echo " COMPARATIVA COMPLETA"
echo " Resultados en: $OUT_DIR"
echo "=================================================================="
ls -la "$OUT_DIR"