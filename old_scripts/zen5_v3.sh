#!/bin/bash
# ==============================================================================
# PRÁCTICA 1: ARQUITECTURA DE COMPUTADORES (AC-P1)
# MODELADO: AMD RYZEN 9 9850HX (ZEN 5)
# SIMULADOR: SimpleScalar / Alpha (sim-outorder)
# ------------------------------------------------------------------------------
# Este script SIEMPRE ejecuta los 5 benchmarks:
#   bzip2, ammp, gap, swim, vpr
#
# Genera por cada benchmark:
#   - <bench>_AMD_Zen5.log   -> TODO: stdout+stderr del programa + stats + resumen
#   - <bench>_AMD_Zen5.csv   -> una fila con las métricas clave
#
# Genera al final:
#   - _resumen_AMD_Zen5.csv  -> una fila por benchmark (para Excel)
#   - grafica_ipc.png        -> gráfica de barras con gnuplot
# ==============================================================================

# ==============================================================================
# 1. PARÁMETROS ARQUITECTÓNICOS (con explicación)
# ==============================================================================

# --- FRONT-END: ancho de etapas (k-vía del procesador) ---
FETCH_IFQ=16    # -fetch:ifqsize: instrucciones en la cola de fetch. Zen 5: 8-wide.
DECODE_W=8      # -decode:width : instrucciones decodificadas por ciclo. Zen 5: 8.
ISSUE_W=8       # -issue:width  : instrucciones emitidas por ciclo. Zen 5: 8.
COMMIT_W=8      # -commit:width : instrucciones retiradas por ciclo. Zen 5: 8.

# --- BUFFERS ---
RUU_SIZE=512    # -ruu:size: Reorder Buffer. Zen 5 real 448 -> 512 (potencia de 2).
LSQ_SIZE=256    # -lsq:size: Load/Store Queue. Zen 5 real 168 -> 256 (potencia de 2).

# --- CACHÉS ---
# Formato: <nombre>:<nsets>:<bsize>:<assoc>:<repl>
#   nsets = tamaño_bytes / (bsize * assoc)
IL1="il1:64:64:8:l"          # L1I: 32 KB, bloque 64 B, 8 vías -> 64 sets
DL1="dl1:64:64:8:l"          # L1D: 48 KB reales, 12 vías -> adaptado a 8 vías
UL2="ul2:1024:64:16:l"       # L2 unificada: 1 MB, bloque 64 B, 16 vías -> 1024 sets

# --- MEMORIA PRINCIPAL (DDR5-5600) ---
MEM_LAT_FC=149  # -mem:lat <first_chunk>: ciclos hasta el primer bloque
MEM_LAT_IC=1    # -mem:lat <inter_chunk>: ciclos por cada bloque adicional
BUS_WIDTH=16    # -mem:width: ancho del bus en bytes (128 bits)

# --- RECURSOS FUNCIONALES ---
IALU=6          # -res:ialu   : ALUs enteras. Zen 5: 6.
IMULT=3         # -res:imult  : multiplicadores/divisores enteros. Zen 5: 3.
FPALU=4         # -res:fpalu  : ALUs de coma flotante. Zen 5: 4.
FPMULT=2        # -res:fpmult : multiplicadores/divisores FP. Zen 5: 2.
MEMPORT=4       # -res:memport: puertos de acceso a L1D. Zen 5: 4.

# --- SIMULACIÓN ---
FASTFWD=100000000   # -fastfwd : instrucciones a saltar antes de medir
MAX_INST=100000000  # -max:inst: instrucciones a simular en detalle

# ==============================================================================
# 2. RUTAS
# ==============================================================================
BASE_DIR="$HOME/Documents/AC-P1"
RESULTS_DIR="$BASE_DIR/results/AMD_Zen5"
SPEC_DIR="/lib/specs2000"
CSV_GLOBAL="$RESULTS_DIR/_resumen_AMD_Zen5.csv"

mkdir -p "$RESULTS_DIR"

# ==============================================================================
# 3. LISTA FIJA DE BENCHMARKS (siempre los 5)
# ==============================================================================
BENCHMARKS=(bzip2 ammp gap swim vpr)

# ==============================================================================
# 4. CONFIGURACIÓN COMÚN DE sim-outorder
# ==============================================================================
ARGS="-fastfwd $FASTFWD -max:inst $MAX_INST \
-fetch:ifqsize $FETCH_IFQ -decode:width $DECODE_W -issue:width $ISSUE_W -commit:width $COMMIT_W \
-ruu:size $RUU_SIZE -lsq:size $LSQ_SIZE \
-cache:il1 $IL1 -cache:dl1 $DL1 -cache:dl2 $UL2 \
-mem:lat $MEM_LAT_FC $MEM_LAT_IC -mem:width $BUS_WIDTH \
-res:ialu $IALU -res:imult $IMULT -res:fpalu $FPALU -res:fpmult $FPMULT -res:memport $MEMPORT"

# ==============================================================================
# 5. CABECERA DEL CSV GLOBAL
# ==============================================================================
echo "benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,sim_cycle,sim_num_insn" > "$CSV_GLOBAL"

# ==============================================================================
# 6. BUCLE PRINCIPAL
# ==============================================================================
for BENCH in "${BENCHMARKS[@]}"; do
    echo ""
    echo "=========================================================="
    echo " [$BENCH] Ejecutando..."
    echo "=========================================================="

    # Todos los resultados de este benchmark van a un único .log
    LOG="$RESULTS_DIR/${BENCH}_AMD_Zen5.log"
    CSV_BENCH="$RESULTS_DIR/${BENCH}_AMD_Zen5.csv"

    # El .txt de stats de sim-outorder se genera aparte y luego lo
    # volcamos al .log para no dejarlo suelto.
    SIM_TXT="$RESULTS_DIR/_tmp_${BENCH}.txt"

    # Cabecera del log
    {
        echo "=========================================================="
        echo " BENCHMARK: $BENCH"
        echo " VARIANTE : AMD_Zen5"
        echo " FECHA    : $(date)"
        echo "=========================================================="
        echo ""
    } > "$LOG"

    # --- Ejecución específica ---
    case "$BENCH" in
        bzip2)
            cd "$SPEC_DIR/bzip2/data/ref" || continue
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/bzip2.exe input.source 58 \
                >> "$LOG" 2>&1
            ;;
        ammp)
            cd "$SPEC_DIR/ammp/data/ref" || continue
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/ammp.exe < ammp.in \
                >> "$LOG" 2>&1
            ;;
        gap)
            cd "$SPEC_DIR/gap/data/ref" || continue
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/gap.exe -l ./ -q -m 192M < ref.in \
                >> "$LOG" 2>&1
            ;;
        swim)
            cd "$SPEC_DIR/swim/data/ref" || continue
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/swim.exe < swim.in \
                >> "$LOG" 2>&1
            ;;
        vpr)
            cd "$SPEC_DIR/vpr/data/ref" || continue
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/vpr.exe net.in arch.in \
                "$RESULTS_DIR/place.out" "$RESULTS_DIR/dum.out" \
                -nodisp -place_only -init_t 5 -exit_t 0.005 \
                -alpha_t 0.9412 -inner_num 2 \
                >> "$LOG" 2>&1
            ;;
        *)
            echo "  [ERROR] benchmark desconocido: $BENCH"
            continue
            ;;
    esac

    # --- Comprobar si hay stats ---
    if ! grep -q 'sim_IPC' "$SIM_TXT" 2>/dev/null; then
        {
            echo ""
            echo "=========================================================="
            echo " [AVISO] $BENCH no ha generado sim_IPC."
            echo "         Posible causa: el programa se agotó durante el"
            echo "         fastfwd de $FASTFWD instrucciones antes de medir."
            echo "=========================================================="
        } >> "$LOG"
        rm -f "$SIM_TXT"
        echo "  [AVISO] $BENCH no generó sim_IPC. Se omite."
        continue
    fi

    # --- Añadir el resumen rico al mismo .log ---
    {
        echo ""
        echo "=========================================================="
        echo " RESUMEN $BENCH"
        echo "=========================================================="
        echo "--- Rendimiento ---"
        grep -E 'sim_num_insn|sim_cycle|sim_IPC|sim_CPI' "$SIM_TXT"
        echo "--- Buffers ---"
        grep -E 'ifq_occupancy|ifq_full|ruu_occupancy|ruu_full|lsq_occupancy|lsq_full' "$SIM_TXT"
        echo "--- Branch prediction ---"
        grep -E 'bpred_bimod.bpred_dir_rate|bpred_bimod.bpred_addr_rate|bpred_bimod.misses' "$SIM_TXT"
        echo "--- Caché L1I ---"
        grep -E '^il1\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo "--- Caché L1D ---"
        grep -E '^dl1\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo "--- Caché L2 ---"
        grep -E '^ul2\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo ""
        echo "=========================================================="
        echo " STATS COMPLETAS DE sim-outorder"
        echo "=========================================================="
        cat "$SIM_TXT"
    } >> "$LOG"

    echo "  [OK] $BENCH finalizado. Log: $LOG"

    # --- Extraer métricas y escribir CSV individual ---
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

    # --- Añadir fila al CSV global ---
    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$CYC,$NINS" >> "$CSV_GLOBAL"

    # --- Borrar el .txt temporal (ya está volcado al .log) ---
    rm -f "$SIM_TXT"
done

# ==============================================================================
# 7. RESUMEN FINAL POR PANTALLA
# ==============================================================================
echo ""
echo "=========================================================="
echo " RESUMEN FINAL (AMD_Zen5)"
echo "=========================================================="
column -t -s, "$CSV_GLOBAL" 2>/dev/null || cat "$CSV_GLOBAL"

# ==============================================================================
# 8. GRÁFICA CON GNUPLOT (si está instalado)
# ==============================================================================
if command -v gnuplot >/dev/null 2>&1; then
    gnuplot -e "
        set datafile separator ',';
        set terminal png size 800,500;
        set style data histograms;
        set style fill solid 1.0;
        set xtics rotate by -30;
        set ylabel 'IPC';
        set title 'IPC por benchmark - AMD Zen5';
        set output '$RESULTS_DIR/grafica_ipc.png';
        plot '$CSV_GLOBAL' using 2:xtic(1) title 'IPC';
    " 2>/dev/null && echo "[OK] Gráfica: $RESULTS_DIR/grafica_ipc.png"
else
    echo "[INFO] gnuplot no instalado. Instálalo con: sudo apt install gnuplot"
fi

echo ""
echo "Ficheros generados en: $RESULTS_DIR"
echo "  - <bench>_AMD_Zen5.log   (uno por benchmark)"
echo "  - <bench>_AMD_Zen5.csv   (uno por benchmark)"
echo "  - _resumen_AMD_Zen5.csv  (global)"
echo "  - grafica_ipc.png        (gráfica)"