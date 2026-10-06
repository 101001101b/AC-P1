#!/bin/bash
# ==============================================================================
# PRÁCTICA 1: ARQUITECTURA DE COMPUTADORES 
# MODELADO: AMD RYZEN 9 9850HX (ZEN 5 - Fire Range)
# SIMULADOR: SimpleScalar / Alpha (sim-outorder)
# ------------------------------------------------------------------------------
# VARIANTE BASE (valores por defecto del procesador real, ajustados a potencias
# de 2 según exige SimpleScalar).
#
# USO:  ./amd_zen5.sh
#
# Genera en results/AMD_Zen5/run_<timestamp>/:
#   - <bench>.log            (stdout+stderr+stats+resumen de cada benchmark)
#   - <bench>.csv            (una fila con las métricas clave)
#   - _resumen.csv           (una fila por benchmark)
#   - grafica_ipc.png        (gráfica de barras)
#
# Para hacer variantes "mejoradas" (L2 2MB, RUU 1024, etc.), copia este script,
# cambia SOLO el bloque "VARIANTE" y el parámetro correspondiente. El resto se
# autogestiona.
# ==============================================================================

# ==============================================================================
# 0. RUTAS PORTABLES
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SPECWORK_DIR="$PROJECT_DIR/specwork"
RESULTS_ROOT="$PROJECT_DIR/results"

# ==============================================================================
# 1. IDENTIFICACIÓN DE LA VARIANTE
# ==============================================================================
VARIANTE="AMD_Zen5_L2_4MB"

# Timestamp para no pisar resultados anteriores
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
RESULTS_DIR="$RESULTS_ROOT/$VARIANTE/run_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# ==============================================================================
# 2. PARÁMETROS ARQUITECTÓNICOS (con comentarios de mejora al lado)
# ==============================================================================

# --- FRONT-END: ancho de etapas del pipeline (k-vía del procesador) ---
FETCH_IFQ=16    # -fetch:ifqsize: instrucciones en la cola de fetch. Zen 5: 8-wide.
                #   Mejora sugerida: FETCH_IFQ=32 (doble cola, sin evidencia de mejora).
DECODE_W=8      # -decode:width : instrucciones decodificadas por ciclo. Zen 5: 8.
                #   Mejora sugerida: DECODE_W=16 (sin evidencia de mejora en tests).
ISSUE_W=8       # -issue:width  : instrucciones emitidas por ciclo. Zen 5: 8.
                #   Mejora sugerida: ISSUE_W=16 (sin evidencia de mejora en tests).
COMMIT_W=8      # -commit:width : instrucciones retiradas por ciclo. Zen 5: 8.
                #   Mejora sugerida: COMMIT_W=16 (sin evidencia de mejora en tests).

# --- BUFFERS: ventana de instrucciones y cola de memoria ---
RUU_SIZE=512    # -ruu:size: Reorder Buffer. Zen 5 real 448 -> 512 (pot. de 2).
                #   Mejora sugerida: RUU_SIZE=1024 (+doble ventana, bueno para swim).
LSQ_SIZE=256    # -lsq:size: Load/Store Queue. Zen 5 real 168 -> 256 (pot. de 2).
                #   Mejora sugerida: LSQ_SIZE=512 (+doble cola, bueno para ammp).

# --- CACHÉS: formato <nombre>:<nsets>:<bsize>:<assoc>:<repl> ---
#   nsets = tamaño_bytes / (bsize * assoc)
IL1="il1:64:64:8:l"          # L1I: 32 KB, bloque 64 B, 8 vías -> 64 sets
                             #   Mejora sugerida: il1:128:64:8:l (64 KB, 8 vías)
DL1="dl1:64:64:8:l"          # L1D: 48 KB reales, 12 vías -> adaptado a 8 vías
                             #   Mejora sugerida: dl1:128:64:8:l (128 KB, 8 vías)
UL2="ul2:4096:64:16:l"       # L2 unificada: 1 MB, bloque 64 B, 16 vías -> 1024 sets
                             #   Mejora sugerida: ul2:2048:64:16:l (2 MB -> ammp ×5.6->esperado)
                             #                    ul2:4096:64:16:l (4 MB -> margen)

# --- MEMORIA PRINCIPAL (DDR5-5600) ---
MEM_LAT_FC=149  # -mem:lat <first_chunk>: ciclos hasta el primer bloque
                #   Mejora sugerida: 100 (DDR5 más rápida, escenario optimista)
MEM_LAT_IC=1    # -mem:lat <inter_chunk>: ciclos por bloque adicional
BUS_WIDTH=16    # -mem:width: ancho del bus en bytes (128 bits)

# --- RECURSOS FUNCIONALES ---
IALU=6          # -res:ialu   : ALUs enteras. Zen 5: 6.
                #   Mejora sugerida: IALU=8 (sin evidencia de mejora)
IMULT=3         # -res:imult  : multiplicadores/divisores enteros. Zen 5: 3.
FPALU=4         # -res:fpalu  : ALUs de coma flotante. Zen 5: 4.
FPMULT=2        # -res:fpmult : multiplicadores/divisores FP. Zen 5: 2.
                #   Mejora sugerida: FPMULT=4 (útil si swim fuera FP-bound)
MEMPORT=4       # -res:memport: puertos de acceso a L1D. Zen 5: 4.

# --- SIMULACIÓN (NO TOCAR: valores exigidos por el enunciado) ---
FASTFWD=100000000   # -fastfwd : 100 M instrucciones de calentamiento
MAX_INST=100000000  # -max:inst: 100 M instrucciones simuladas en detalle

# ==============================================================================
# 3. LISTA FIJA DE BENCHMARKS
# ==============================================================================
BENCHMARKS=(bzip2 ammp gap swim vpr)

# ==============================================================================
# 4. PREPARAR specwork (copia .exe e inputs si faltan)
# ==============================================================================
prepare_specwork() {
    local b="$1"
    mkdir -p "$SPECWORK_DIR/$b"
    # Binario
    if [ ! -f "$SPECWORK_DIR/$b/$b.exe" ] && [ -f "/lib/specs2000/$b/exe/$b.exe" ]; then
        cp -n "/lib/specs2000/$b/exe/$b.exe" "$SPECWORK_DIR/$b/"
    fi
    # Inputs
    if [ -d "/lib/specs2000/$b/data/ref" ]; then
        cp -n /lib/specs2000/$b/data/ref/* "$SPECWORK_DIR/$b/" 2>/dev/null
    fi
}

# ==============================================================================
# 5. CONFIGURACIÓN COMÚN DE sim-outorder
# ==============================================================================
ARGS="-fastfwd $FASTFWD -max:inst $MAX_INST \
-fetch:ifqsize $FETCH_IFQ -decode:width $DECODE_W -issue:width $ISSUE_W -commit:width $COMMIT_W \
-ruu:size $RUU_SIZE -lsq:size $LSQ_SIZE \
-cache:il1 $IL1 -cache:dl1 $DL1 -cache:dl2 $UL2 \
-mem:lat $MEM_LAT_FC $MEM_LAT_IC -mem:width $BUS_WIDTH \
-res:ialu $IALU -res:imult $IMULT -res:fpalu $FPALU -res:fpmult $FPMULT -res:memport $MEMPORT"

# ==============================================================================
# 6. CABECERA DEL CSV GLOBAL
# ==============================================================================
CSV_GLOBAL="$RESULTS_DIR/_resumen.csv"
echo "benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,sim_cycle,sim_num_insn" > "$CSV_GLOBAL"

# ==============================================================================
# 7. BUCLE PRINCIPAL
# ==============================================================================
echo ""
echo "=================================================================="
echo " VARIANTE: $VARIANTE"
echo " Salida:   $RESULTS_DIR"
echo "=================================================================="

for BENCH in "${BENCHMARKS[@]}"; do
    echo ""
    echo "--- [$BENCH] ---"

    prepare_specwork "$BENCH"
    cd "$SPECWORK_DIR/$BENCH" || { echo "  [ERROR] no existe $SPECWORK_DIR/$BENCH"; continue; }

    LOG="$RESULTS_DIR/${BENCH}.log"
    CSV_BENCH="$RESULTS_DIR/${BENCH}.csv"
    SIM_TXT="$RESULTS_DIR/_tmp_${BENCH}.txt"

    # Cabecera del log
    {
        echo "=================================================================="
        echo " BENCHMARK: $BENCH"
        echo " VARIANTE : $VARIANTE"
        echo " FECHA    : $(date)"
        echo " WORKDIR  : $SPECWORK_DIR/$BENCH"
        echo "=================================================================="
    } > "$LOG"

    # Ejecución
    case "$BENCH" in
        bzip2) sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                  ./bzip2.exe input.source 58 >> "$LOG" 2>&1 ;;
        ammp)  sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                  ./ammp.exe < ammp.in >> "$LOG" 2>&1 ;;
        gap)   sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                  ./gap.exe -l ./ -q -m 192M < ref.in >> "$LOG" 2>&1 ;;
        swim)  sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                  ./swim.exe < swim.in >> "$LOG" 2>&1 ;;
        vpr)   sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                  ./vpr.exe net.in arch.in "$RESULTS_DIR/place.out" "$RESULTS_DIR/dum.out" \
                  -nodisp -place_only -init_t 5 -exit_t 0.005 \
                  -alpha_t 0.9412 -inner_num 2 >> "$LOG" 2>&1 ;;
        *) echo "  [ERROR] desconocido: $BENCH"; continue ;;
    esac

    # Comprobar stats
    if ! grep -q 'sim_IPC' "$SIM_TXT" 2>/dev/null; then
        echo "  [AVISO] $BENCH sin sim_IPC (¿fastfwd agotó el programa?)"
        rm -f "$SIM_TXT"
        continue
    fi

    # Resumen rico al log
    {
        echo ""
        echo "--- RESUMEN ---"
        grep -E 'sim_num_insn|sim_cycle|sim_IPC|sim_CPI' "$SIM_TXT"
        echo "--- BUFFERS ---"
        grep -E 'ifq_occupancy|ruu_occupancy|lsq_occupancy' "$SIM_TXT"
        echo "--- BRANCH ---"
        grep -E 'bpred_bimod.bpred_dir_rate' "$SIM_TXT"
        echo "--- CACHÉS ---"
        grep -E '^il1\.(miss_rate|accesses)|^dl1\.(miss_rate|accesses)|^ul2\.(miss_rate|accesses)' "$SIM_TXT"
    } >> "$LOG"

    echo "  [OK] $BENCH"

    # Extraer métricas
    IPC=$(grep -m1 'sim_IPC' "$SIM_TXT" | awk '{print $2}')
    CPI=$(grep -m1 'sim_CPI' "$SIM_TXT" | awk '{print $2}')
    L1I=$(grep -m1 '^il1.miss_rate' "$SIM_TXT" | awk '{print $2}')
    L1D=$(grep -m1 '^dl1.miss_rate' "$SIM_TXT" | awk '{print $2}')
    L2=$(grep -m1 '^ul2.miss_rate' "$SIM_TXT" | awk '{print $2}')
    IFQ=$(grep -m1 'ifq_occupancy' "$SIM_TXT" | awk '{print $2}')
    RUU=$(grep -m1 'ruu_occupancy' "$SIM_TXT" | awk '{print $2}')
    LSQ=$(grep -m1 'lsq_occupancy' "$SIM_TXT" | awk '{print $2}')
    BPR=$(grep -m1 'bpred_bimod.bpred_dir_rate' "$SIM_TXT" | awk '{print $2}')
    CYC=$(grep -m1 'sim_cycle' "$SIM_TXT" | awk '{print $2}')
    NINS=$(grep -m1 'sim_num_insn' "$SIM_TXT" | awk '{print $2}')

    echo "benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,sim_cycle,sim_num_insn" > "$CSV_BENCH"
    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$CYC,$NINS" >> "$CSV_BENCH"
    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$CYC,$NINS" >> "$CSV_GLOBAL"

    rm -f "$SIM_TXT"
done

# ==============================================================================
# 8. RESUMEN FINAL + GRÁFICA
# ==============================================================================
echo ""
echo "=================================================================="
echo " RESUMEN $VARIANTE"
echo "=================================================================="
column -t -s, "$CSV_GLOBAL" 2>/dev/null || cat "$CSV_GLOBAL"

if command -v gnuplot >/dev/null 2>&1; then
    gnuplot -e "
        set datafile separator ',';
        set terminal png size 900,500;
        set style data histograms;
        set style histogram clustered gap 1;
        set style fill solid 1.0 border -1;
        set boxwidth 0.9;
        set xtics rotate by 0;
        set ylabel 'IPC';
        set xlabel 'Benchmark';
        set title 'IPC - $VARIANTE';
        set output '$RESULTS_DIR/grafica_ipc.png';
        plot '$CSV_GLOBAL' using 2:xtic(1) title 'IPC';
    " 2>/dev/null && echo "[OK] $RESULTS_DIR/grafica_ipc.png"
fi

echo ""
echo "Ficheros en: $RESULTS_DIR"