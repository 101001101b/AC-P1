#!/bin/bash
# ==============================================================================
# PRÁCTICA 1: ARQUITECTURA DE COMPUTADORES (AC-P1)
# MODELADO: AMD RYZEN 9 9850HX (ZEN 5)
# SIMULADOR: SimpleScalar / Alpha (sim-outorder)
# ------------------------------------------------------------------------------
# USO:
#   ./amd_zen5.sh              -> ejecuta los 5 benchmarks
#   ./amd_zen5.sh bzip2 vpr    -> ejecuta solo bzip2 y vpr
#   ./amd_zen5.sh all          -> ejecuta los 5 benchmarks
# ==============================================================================

# ==============================================================================
# 1. PARÁMETROS ARQUITECTÓNICOS (variables globales con explicación)
# ==============================================================================

# ------------------------------------------------------------------------------
# FRONT-END: ancho de las etapas del pipeline (k-vía)
# ------------------------------------------------------------------------------
# -fetch:ifqsize: instrucciones en la cola de fetch. Zen 5: front-end 8-wide.
# -decode:width : instrucciones decodificadas por ciclo. Zen 5: 8.
# -issue:width  : instrucciones emitidas por ciclo. Zen 5: 8.
# -commit:width : instrucciones retiradas por ciclo. Zen 5: 8.
FETCH_IFQ=16
DECODE_W=8
ISSUE_W=8
COMMIT_W=8

# ------------------------------------------------------------------------------
# BUFFERS: ventana de instrucciones y cola de memoria
# ------------------------------------------------------------------------------
# -ruu:size: Reorder Buffer. Zen 5 real: 448 -> redondeado a 512 (potencia de 2).
# -lsq:size: Load/Store Queue. Zen 5 real: 168 -> redondeado a 256 (potencia de 2).
RUU_SIZE=512
LSQ_SIZE=256

# ------------------------------------------------------------------------------
# CACHÉS L1/L2
# Formato: <nombre>:<nsets>:<bsize>:<assoc>:<repl>
#   nsets = tamaño_bytes / (bsize * assoc)
# ------------------------------------------------------------------------------
# L1I: 32 KB, bloque 64 B, 8 vías -> nsets = 32768/(64*8) = 64
IL1="il1:64:64:8:l"
# L1D: 48 KB reales, 12 vías -> adaptado a 8 vías por potencia de 2: 64 sets
DL1="dl1:64:64:8:l"
# L2 unificada: 1 MB, bloque 64 B, 16 vías -> nsets = 1048576/(64*16) = 1024
UL2="ul2:1024:64:16:l"

# ------------------------------------------------------------------------------
# MEMORIA PRINCIPAL: bus y latencia (DDR5-5600)
# ------------------------------------------------------------------------------
# -mem:lat <first_chunk> <inter_chunk>
#   first_chunk: ciclos hasta el primer bloque. Estimado 149 para DDR5-5600.
#   inter_chunk: ciclos por bloque adicional. 1 ciclo.
MEM_LAT_FC=149
MEM_LAT_IC=1
# -mem:width: ancho del bus en bytes. 16 bytes = 128 bits.
BUS_WIDTH=16

# ------------------------------------------------------------------------------
# RECURSOS FUNCIONALES
# ------------------------------------------------------------------------------
# -res:ialu   : ALUs enteras. Zen 5: 6.
# -res:imult  : multiplicadores/divisores enteros. Zen 5: 3.
# -res:fpalu  : ALUs de coma flotante. Zen 5: 4.
# -res:fpmult : multiplicadores/divisores FP. Zen 5: 2.
# -res:memport: puertos de acceso a L1D. Zen 5: 4.
IALU=6
IMULT=3
FPALU=4
FPMULT=2
MEMPORT=4

# ------------------------------------------------------------------------------
# SIMULACIÓN
# ------------------------------------------------------------------------------
# -fastfwd : instrucciones a saltar antes de medir. Enunciado: 100 M.
# -max:inst: instrucciones a simular. Enunciado: 100 M.
FASTFWD=100000000
MAX_INST=100000000

# ==============================================================================
# 2. RUTAS
# ==============================================================================
BASE_DIR="$HOME/Documents/AC-P1"
RESULTS_DIR="$BASE_DIR/results/AMD_Zen5"
SPEC_DIR="/lib/specs2000"
CSV_GLOBAL="$RESULTS_DIR/_resumen_AMD_Zen5.csv"

mkdir -p "$RESULTS_DIR"

# ==============================================================================
# 3. SELECCIÓN DE BENCHMARKS
# ==============================================================================
if [ $# -eq 0 ] || [ "$1" = "all" ]; then
    BENCHMARKS=(bzip2 ammp gap swim vpr)
else
    BENCHMARKS=("$@")
fi

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
# 5. CABECERA CSV
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

    SIM_TXT="$RESULTS_DIR/${BENCH}_AMD_Zen5.txt"
    SUM_OUT="$RESULTS_DIR/${BENCH}_AMD_Zen5.out"

    # Ejecución específica por benchmark (esta parte es la que FUNCIONA)
    case "$BENCH" in
        bzip2)
            cd "$SPEC_DIR/bzip2/data/ref" || exit 1
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/bzip2.exe input.source 58 \
                > "$RESULTS_DIR/${BENCH}.out" 2> "$RESULTS_DIR/${BENCH}.err"
            ;;
        ammp)
            cd "$SPEC_DIR/ammp/data/ref" || exit 1
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/ammp.exe < ammp.in \
                > "$RESULTS_DIR/${BENCH}.out" 2> "$RESULTS_DIR/${BENCH}.err"
            ;;
        gap)
            cd "$SPEC_DIR/gap/data/ref" || exit 1
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/gap.exe -l ./ -q -m 192M < ref.in \
                > "$RESULTS_DIR/${BENCH}.out" 2> "$RESULTS_DIR/${BENCH}.err"
            ;;
        swim)
            cd "$SPEC_DIR/swim/data/ref" || exit 1
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/swim.exe < swim.in \
                > "$RESULTS_DIR/${BENCH}.out" 2> "$RESULTS_DIR/${BENCH}.err"
            ;;
        vpr)
            cd "$SPEC_DIR/vpr/data/ref" || exit 1
            sim-outorder $ARGS -redir:sim "$SIM_TXT" \
                ../../exe/vpr.exe net.in arch.in "$RESULTS_DIR/place.out" "$RESULTS_DIR/dum.out" \
                -nodisp -place_only -init_t 5 -exit_t 0.005 -alpha_t 0.9412 -inner_num 2 \
                > "$RESULTS_DIR/place_log.out" 2> "$RESULTS_DIR/place_log.err"
            ;;
        *)
            echo "  [ERROR] benchmark desconocido: $BENCH"
            continue
            ;;
    esac

    # Comprobar si hay stats
    if ! grep -q 'sim_IPC' "$SIM_TXT" 2>/dev/null; then
        echo "  [AVISO] $BENCH no generó sim_IPC. Se omite."
        continue
    fi

    echo "  [OK] $BENCH finalizado."

    # Resumen rico
    {
        echo "=== RESUMEN $BENCH (AMD_Zen5) ==="
        date
        echo "--- Rendimiento ---"
        grep -E 'sim_num_insn|sim_cycle|sim_IPC|sim_CPI' "$SIM_TXT"
        echo "--- Buffers ---"
        grep -E 'ifq_occupancy|ruu_occupancy|lsq_occupancy' "$SIM_TXT"
        echo "--- Branch prediction ---"
        grep -E 'bpred_bimod.bpred_dir_rate' "$SIM_TXT"
        echo "--- Cachés ---"
        grep -E '^il1\.(miss_rate|accesses)|^dl1\.(miss_rate|accesses)|^ul2\.(miss_rate|accesses)' "$SIM_TXT"
    } > "$SUM_OUT"

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

    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$CYC,$NINS" >> "$CSV_GLOBAL"
done

# ==============================================================================
# 7. RESUMEN FINAL Y GRÁFICA
# ==============================================================================
echo ""
echo "=========================================================="
echo " RESUMEN FINAL"
echo "=========================================================="
cat "$CSV_GLOBAL" | column -t -s,

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
fi

echo ""
echo "Ficheros en: $RESULTS_DIR"