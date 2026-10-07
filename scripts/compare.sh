#!/bin/bash
# ==============================================================================
# compare.sh - Genera comparativa de TODAS las variantes 
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_ROOT="$PROJECT_DIR/results"
OUT_DIR="$RESULTS_ROOT/_comparativa"
mkdir -p "$OUT_DIR"

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
# 1. CSV largo
# ==============================================================================
CSV_LARGO="$OUT_DIR/_comparativa_larga.csv"
echo "variante,benchmark,IPC,CPI,sim_cycle,sim_num_insn,sim_total_insn,sim_exec_BW,avg_sim_slip,ifq_occupancy,ifq_full,ruu_occupancy,ruu_full,ruu_latency,lsq_occupancy,lsq_full,lsq_latency,bpred_dir_rate,ras_rate,il1_miss_rate,dl1_miss_rate,ul2_miss_rate,itlb_miss_rate,dtlb_miss_rate,sim_IPB,bpred_addr_rate,bpred_misses,il1_misses,dl1_misses,ul2_misses" > "$CSV_LARGO"

for V in "${VARIANTS[@]}"; do
    LATEST=$(ls -d "$RESULTS_ROOT/$V/run_"* 2>/dev/null | sort | tail -1)
    [ -z "$LATEST" ] && continue
    CSV="$LATEST/_resumen.csv"
    [ -f "$CSV" ] || continue
    tail -n +2 "$CSV" | sed "s/^/$V,/" >> "$CSV_LARGO"
done
echo "[OK] $CSV_LARGO"

# ==============================================================================
# 2. CSVs anchos por métrica
# ==============================================================================
BENCHMARKS=(bzip2 ammp gap swim vpr)

METRICAS=(
    "IPC:IPC:3"
    "CPI:CPI:4"
    "sim_cycle:sim_cycle:5"
    "sim_num_insn:sim_num_insn:6"
    "sim_total_insn:sim_total_insn:7"
    "sim_exec_BW:sim_exec_BW:8"
    "avg_sim_slip:avg_sim_slip:9"
    "ifq_occupancy:ifq_occupancy:10"
    "ifq_full:ifq_full:11"
    "ruu_occupancy:ruu_occupancy:12"
    "ruu_full:ruu_full:13"
    "ruu_latency:ruu_latency:14"
    "lsq_occupancy:lsq_occupancy:15"
    "lsq_full:lsq_full:16"
    "lsq_latency:lsq_latency:17"
    "bpred_dir_rate:bpred_dir_rate:18"
    "ras_rate:ras_rate:19"
    "il1_miss_rate:il1_miss_rate:20"
    "dl1_miss_rate:dl1_miss_rate:21"
    "ul2_miss_rate:ul2_miss_rate:22"
    "itlb_miss_rate:itlb_miss_rate:23"
    "dtlb_miss_rate:dtlb_miss_rate:24"
    "sim_IPB:sim_IPB:25"
    "bpred_addr_rate:bpred_addr_rate:26"
    "bpred_misses:bpred_misses:27"
    "il1_misses:il1_misses:28"
    "dl1_misses:dl1_misses:29"
    "ul2_misses:ul2_misses:30"
)

for M in "${METRICAS[@]}"; do
    IFS=':' read -r COL_NAME FILE_NAME IDX <<< "$M"
    OUT_CSV="$OUT_DIR/_comparativa_${FILE_NAME}.csv"
    {
        printf "benchmark"
        for V in "${VARIANTS[@]}"; do printf ",%s" "$V"; done
        printf "\n"
        for B in "${BENCHMARKS[@]}"; do
            printf "%s" "$B"
            for V in "${VARIANTS[@]}"; do
                VAL=$(awk -F, -v v="$V" -v b="$B" -v i="$IDX" '$1==v && $2==b {print $i}' "$CSV_LARGO")
                printf ",%s" "${VAL:-0}"
            done
            printf "\n"
        done
    } > "$OUT_CSV"
done
echo "[OK] CSVs anchos (${#METRICAS[@]} métricas)"

# ==============================================================================
# 3. Tabla Markdown
# ==============================================================================
MD="$OUT_DIR/_comparativa.md"
{
    echo "# Comparativa de variantes"
    echo ""
    echo "Generado: $(date)"
    echo ""
    for M in "${METRICAS[@]}"; do
        IFS=':' read -r COL_NAME FILE_NAME IDX <<< "$M"
        echo "## $COL_NAME"
        echo ""
        # Cabecera: benchmark como columnas
        printf "| Variante |"
        for B in "${BENCHMARKS[@]}"; do printf " %s |" "$B"; done
        printf "\n|---|"
        for B in "${BENCHMARKS[@]}"; do printf -- "---:|"; done
        printf "\n"
        # Una fila por variante
        for V in "${VARIANTS[@]}"; do
            printf "| **%s** |" "$V"
            for B in "${BENCHMARKS[@]}"; do
                VAL=$(awk -F, -v v="$V" -v b="$B" -v i="$IDX" '$1==v && $2==b {print $i}' "$CSV_LARGO")
                printf " %s |" "${VAL:--}"
            done
            printf "\n"
        done
        # Fila de medias por variante
        printf "| **MEDIA** |"
        for B in "${BENCHMARKS[@]}"; do
            MEDIA=$(awk -F, -v b="$B" -v i="$IDX" '$2==b {s+=$i; n++} END {if(n>0) printf "%.4f", s/n}' "$CSV_LARGO")
            printf " **%s** |" "${MEDIA:--}"
        done
        printf "\n\n"
    done
} > "$MD"
echo "[OK] $MD"

# ==============================================================================
# 5. Comparativa final base vs mejorado
# ==============================================================================
CSV_FINAL="$OUT_DIR/comparativa_final.csv"

V_AMD_BASE="AMD_Zen5"
V_AMD_MEJ="AMD_Zen5_mejorado"
V_INTEL_BASE="Intel_CougarCove"
V_INTEL_MEJ="Intel_mejorado"

get_ipc() {
    awk -F, -v v="$1" -v b="$2" '$1==v && $2==b {print $3}' "$CSV_LARGO"
}

{
    echo "benchmark,AMD_base,AMD_mejorado,Intel_base,Intel_mejorado"
    for B in "${BENCHMARKS[@]}"; do
        A_BASE=$(get_ipc "$V_AMD_BASE"   "$B")
        A_MEJ=$(get_ipc  "$V_AMD_MEJ"    "$B")
        I_BASE=$(get_ipc "$V_INTEL_BASE" "$B")
        I_MEJ=$(get_ipc  "$V_INTEL_MEJ"  "$B")
        echo "$B,${A_BASE:-0},${A_MEJ:-0},${I_BASE:-0},${I_MEJ:-0}"
    done
    A_BASE_M=$(awk -F, -v v="$V_AMD_BASE"   '$1==v {s+=$3; n++} END {if(n) printf "%.4f", s/n}' "$CSV_LARGO")
    A_MEJ_M=$(awk -F, -v v="$V_AMD_MEJ"     '$1==v {s+=$3; n++} END {if(n) printf "%.4f", s/n}' "$CSV_LARGO")
    I_BASE_M=$(awk -F, -v v="$V_INTEL_BASE" '$1==v {s+=$3; n++} END {if(n) printf "%.4f", s/n}' "$CSV_LARGO")
    I_MEJ_M=$(awk -F, -v v="$V_INTEL_MEJ"   '$1==v {s+=$3; n++} END {if(n) printf "%.4f", s/n}' "$CSV_LARGO")
    echo "MEDIA,${A_BASE_M:-0},${A_MEJ_M:-0},${I_BASE_M:-0},${I_MEJ_M:-0}"
} > "$CSV_FINAL"
echo "[OK] $CSV_FINAL"


echo ""
echo # Tabla resumen transpuesta (benchmarks en columnas)
echo ""
echo "=================================================================="
echo " RESUMEN IPC (transpuesto: métricas en filas, benchmarks en columnas)"
echo "=================================================================="
printf "%-20s" "Métrica"
for B in "${BENCHMARKS[@]}"; do printf " %12s" "$B"; done
printf "\n"
for V in "${VARIANTS[@]}"; do
    printf "%-20s" "$V"
    for B in "${BENCHMARKS[@]}"; do
        VAL=$(awk -F, -v v="$V" -v b="$B" '$1==v && $2==b {print $3}' "$CSV_LARGO")
        printf " %12s" "${VAL:--}"
    done
    printf "\n"
done

echo ""
echo "=================================================================="
echo " COMPARATIVA COMPLETA"
echo " Resultados en: $OUT_DIR"
echo "=================================================================="
ls -la "$OUT_DIR"
ls -la "$OUT_DIR"