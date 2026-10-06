#!/bin/bash
# ==============================================================================
# PRÁCTICA 1: ARQUITECTURA DE COMPUTADORES (AC-P1)
# MODELADO DEL PROCESADOR: AMD RYZEN 9 9850HX (ZEN 5 - Fire Range)
# SIMULADOR: SimpleScalar / Alpha (sim-outorder)
# ------------------------------------------------------------------------------
# Autor:  milax
# Fecha:  2026-10
# Uso:    ./amd_zen5.sh              -> ejecuta los 5 benchmarks
#         ./amd_zen5.sh bzip2 vpr    -> ejecuta solo bzip2 y vpr
#         ./amd_zen5.sh all          -> ejecuta los 5 benchmarks
# ==============================================================================

# ==============================================================================
# 0. CÓMO USAR ESTE SCRIPT
# ==============================================================================
# Este script:
#   1) Crea una estructura de carpetas organizada bajo $BASE_DIR.
#   2) Copia los inputs necesarios desde /lib/specs2000 a $BASE_DIR/specwork.
#   3) Lanza sim-outorder con la configuración AMD Zen 5 definida abajo.
#   4) Guarda el .txt de stats, un resumen rico (.out) y un CSV por benchmark.
#   5) Al final genera un CSV global con una fila por benchmark.
#   6) (Opcional) Genera gráficas con gnuplot si está instalado.
#
# Para las variantes "mejorado" del enunciado: copia este script a
#   amd_zen5_mejorado.sh
# y modifica SOLO las variables de la sección 2 (por ejemplo RUU_SIZE=1024).
# Todo el resto (carpetas, CSV, resumen) se autogenera con el nombre de variante.
# ==============================================================================


# ==============================================================================
# 1. IDENTIFICACIÓN DE LA VARIANTE (para no pisar resultados entre versiones)
# ==============================================================================
# Nombre corto de la variante. Cambia esto al hacer "mejorado", "ruu1024", etc.
VARIANTE="AMD_Zen5"

# ==============================================================================
# 2. PARÁMETROS ARQUITECTÓNICOS DEL AMD RYZEN 9 9850HX (ZEN 5)
#    Cada parámetro lleva: qué es, qué representa en Zen 5, cómo se busca
#    en las especificaciones del fabricante.
# ==============================================================================

# ------------------------------------------------------------------------------
# 2.1 FRONT-END: ANCHO DE LAS ETAPAS DEL PIPELINE (k-vía del procesador)
# ------------------------------------------------------------------------------
# -fetch:ifqsize : número de instrucciones que caben en la cola de instrucciones
#                  capturadas por el front-end (Instruction Fetch Queue).
#                  En Zen 5 el front-end puede decodificar 8 instrucciones por
#                  ciclo, pero la cola interna de micro-ops es más grande.
#                  Se aproxima con 16 para modelar ese colchón entre fetch y
#                  decode. Se busca en las specs como "Op Cache size" o
#                  "instruction queue entries".
FETCH_IFQ=16

# -decode:width  : número máximo de instrucciones decodificadas por ciclo.
#                  Zen 5: 8 vías de decodificación. Se busca en las specs como
#                  "decode width" o "instructions per cycle decoded".
DECODE_W=8

# -issue:width   : número máximo de instrucciones emitidas (issue) por ciclo
#                  a las unidades funcionales fuera de orden.
#                  Zen 5: 8 vías de emisión. Se busca como "issue width".
ISSUE_W=8

# -commit:width  : número máximo de instrucciones retiradas (commit) por ciclo.
#                  Zen 5: 8 vías de retirada. Se busca como "retire width"
#                  o "commit width".
COMMIT_W=8

# ------------------------------------------------------------------------------
# 2.2 BUFFERS DE INSTRUCCIONES Y MEMORIA
# ------------------------------------------------------------------------------
# -ruu:size      : tamaño de la ventana de instrucciones (Reorder Buffer, ROB).
#                  Zen 5 real: 448 entradas. SimpleScalar exige potencias de 2
#                  estrictas, así que se redondea a 512. Se busca como
#                  "ROB entries" o "reorder buffer size".
RUU_SIZE=512

# -lsq:size      : tamaño de la Load/Store Queue (accesos a memoria en vuelo).
#                  Zen 5 real: 168 (64 load + 104 store). Redondeado a 256 por
#                  la restricción de potencias de 2. Se busca como "LSQ entries"
#                  o "load/store queue depth".
LSQ_SIZE=256

# ------------------------------------------------------------------------------
# 2.3 JERARQUÍA DE CACHÉS L1 Y L2
#     Formato: <nombre>:<nsets>:<bsize>:<assoc>:<repl>
#       nsets = tamaño_total_bytes / (bsize * assoc)
#       bsize = tamaño de bloque en bytes
#       assoc = vías (asociatividad)
#       repl  = 'l' LRU, 'f' FIFO, 'r' random
# ------------------------------------------------------------------------------
# L1I (instrucciones): 32 KB, 64 B/bloque, 8 vías -> 64 sets
#   Zen 5: L1I 32 KB 8-way. Se busca como "L1I cache size/associativity".
IL1="il1:64:64:8:l"

# L1D (datos): 48 KB reales, 12 vías. SimpleScalar exige potencia de 2, así que
#   se adapta a 8 vías (64 sets) manteniendo 64 B de bloque.
#   Zen 5: L1D 48 KB 12-way. Se busca como "L1D cache size/associativity".
DL1="dl1:64:64:8:l"

# L2 (unificada): 1 MB, 64 B/bloque, 16 vías -> 1024 sets
#   Zen 5: L2 1 MB 16-way. Se busca como "L2 cache size/associativity".
UL2="ul2:1024:64:16:l"

# ------------------------------------------------------------------------------
# 2.4 BUS Y LATENCIA DE MEMORIA PRINCIPAL (DDR5-5600)
# ------------------------------------------------------------------------------
# -mem:lat <first_chunk> <inter_chunk>
#   first_chunk : ciclos hasta el primer bloque (latencia CAS + bus).
#                 Estimado a 149 ciclos para DDR5-5600 a ~5.2 GHz de CPU.
#   inter_chunk : ciclos por cada bloque adicional (burst).
#                 DDR5 con burst de 16 bytes por ciclo -> 1 ciclo.
#   Se busca como "DDR5-5600 latency" o "CAS latency to cycles".
MEM_LAT_FC=149
MEM_LAT_IC=1

# -mem:width : ancho del bus en bytes. 16 bytes = 128 bits.
#   Zen 5 usa un bus de 128 bits con la DRAM. Se busca como "memory bus width".
BUS_WIDTH=16

# ------------------------------------------------------------------------------
# 2.5 RECURSOS FUNCIONALES (UNIDADES DE EJECUCIÓN)
# ------------------------------------------------------------------------------
# -res:ialu    : ALUs enteras. Zen 5: 6 ALUs enteras.
# -res:imult   : multiplicadores/divisores enteros. Zen 5: 3.
# -res:fpalu   : ALUs de coma flotante. Zen 5: 4.
# -res:fpmult  : multiplicadores/divisores FP. Zen 5: 2.
# -res:memport : puertos de acceso a L1D. Zen 5: 4 (2 load + 2 store).
#   Se buscan como "integer ALU count", "FP pipes", "AGU count", etc.
IALU=6
IMULT=3
FPALU=4
FPMULT=2
MEMPORT=4

# ------------------------------------------------------------------------------
# 2.6 PARÁMETROS DE SIMULACIÓN (NO del procesador, sino del simulador)
# ------------------------------------------------------------------------------
# -fastfwd  : instrucciones a saltar antes de empezar a medir.
#             El enunciado pide saltar 100 millones.
FASTFWD=100000000

# -max:inst : instrucciones a simular en detalle. El enunciado pide 100 M.
MAX_INST=100000000

# ==============================================================================
# 3. RUTAS DE TRABAJO
# ==============================================================================
BASE_DIR="$HOME/Documents/AC-P1"
RESULTS_DIR="$BASE_DIR/results/$VARIANTE"
WORK_DIR="$BASE_DIR/specwork"
LOG_DIR="$BASE_DIR/logs/$VARIANTE"
CSV_GLOBAL="$RESULTS_DIR/_resumen_$VARIANTE.csv"

mkdir -p "$RESULTS_DIR" "$WORK_DIR" "$LOG_DIR"

# ==============================================================================
# 4. SELECCIÓN DE BENCHMARKS
# ==============================================================================
# Si no se pasan argumentos, o se pasa "all", se ejecutan los 5.
# Si se pasan nombres, solo esos. Ejemplo: ./amd_zen5.sh swim vpr
if [ $# -eq 0 ] || [ "$1" = "all" ]; then
    BENCHMARKS=(ammp bzip2 gap swim vpr)
else
    BENCHMARKS=("$@")
fi

# ==============================================================================
# 5. FUNCIONES AUXILIARES
# ==============================================================================

# Imprime un separador bonito con el nombre del benchmark
print_header() {
    echo "=========================================================="
    echo " $1"
    echo "=========================================================="
}

# Copia los inputs necesarios desde /lib/specs2000 a $WORK_DIR/<bench>/
# Solo copia si el fichero destino no existe, para no repetir trabajo.
prepare_inputs() {
    local bench="$1"
    local src="/lib/specs2000/$bench/data/ref"
    local dst="$WORK_DIR/$bench"
    mkdir -p "$dst"

    case "$bench" in
        bzip2)
            cp -n "$src/input.source" "$dst/" 2>/dev/null
            ;;
        ammp)
            cp -n "$src/ammp.in" "$dst/" 2>/dev/null
            ;;
        gap)
            cp -n "$src/ref.in" "$dst/" 2>/dev/null
            ;;
        swim)
            cp -n "$src/swim.in" "$dst/" 2>/dev/null
            ;;
        vpr)
            cp -n "$src/net.in"  "$dst/" 2>/dev/null
            cp -n "$src/arch.in" "$dst/" 2>/dev/null
            ;;
    esac
}

# Extrae una estadística concreta del .txt de sim-outorder.
# Uso: extract <fichero> <patrón>
extract() {
    grep -m1 "$2" "$1" 2>/dev/null | awk '{print $2}'
}

# Elimina un fichero si está vacío (0 bytes) o no tiene líneas útiles
cleanup_empty() {
    for f in "$@"; do
        if [ -f "$f" ] && [ ! -s "$f" ]; then
            rm -f "$f"
        fi
    done
}

# ==============================================================================
# 6. DUMP DE CONFIGURACIÓN (queda registrado en el log y en pantalla)
# ==============================================================================
print_header "CONFIGURACIÓN DE LA SIMULACIÓN ($VARIANTE)"
echo "--- Front-end ---"
echo "  FETCH_IFQ   = $FETCH_IFQ    (tamaño cola de instrucciones)"
echo "  DECODE_W    = $DECODE_W     (ancho de decodificación)"
echo "  ISSUE_W     = $ISSUE_W      (ancho de emisión)"
echo "  COMMIT_W    = $COMMIT_W     (ancho de retirada)"
echo "--- Buffers ---"
echo "  RUU_SIZE    = $RUU_SIZE     (Reorder Buffer)"
echo "  LSQ_SIZE    = $LSQ_SIZE     (Load/Store Queue)"
echo "--- Cachés ---"
echo "  IL1         = $IL1"
echo "  DL1         = $DL1"
echo "  UL2         = $UL2"
echo "--- Memoria principal ---"
echo "  MEM_LAT_FC  = $MEM_LAT_FC   (latencia primer bloque)"
echo "  MEM_LAT_IC  = $MEM_LAT_IC   (latencia bloques siguientes)"
echo "  BUS_WIDTH   = $BUS_WIDTH    (bytes)"
echo "--- Recursos funcionales ---"
echo "  IALU        = $IALU"
echo "  IMULT       = $IMULT"
echo "  FPALU       = $FPALU"
echo "  FPMULT      = $FPMULT"
echo "  MEMPORT     = $MEMPORT"
echo "--- Simulación ---"
echo "  FASTFWD     = $FASTFWD"
echo "  MAX_INST    = $MAX_INST"
echo "--- Salida ---"
echo "  RESULTS_DIR = $RESULTS_DIR"
echo "  WORK_DIR    = $WORK_DIR"
echo ""

# Guardamos también el dump en un log
CONFIG_LOG="$LOG_DIR/config_$VARIANTE.log"
{
    echo "=== CONFIGURACIÓN $VARIANTE ==="
    date
    echo "FETCH_IFQ=$FETCH_IFQ DECODE_W=$DECODE_W ISSUE_W=$ISSUE_W COMMIT_W=$COMMIT_W"
    echo "RUU_SIZE=$RUU_SIZE LSQ_SIZE=$LSQ_SIZE"
    echo "IL1=$IL1 DL1=$DL1 UL2=$UL2"
    echo "MEM_LAT_FC=$MEM_LAT_FC MEM_LAT_IC=$MEM_LAT_IC BUS_WIDTH=$BUS_WIDTH"
    echo "IALU=$IALU IMULT=$IMULT FPALU=$FPALU FPMULT=$FPMULT MEMPORT=$MEMPORT"
    echo "FASTFWD=$FASTFWD MAX_INST=$MAX_INST"
} > "$CONFIG_LOG"

# ==============================================================================
# 7. CONSTRUCCIÓN DE LOS ARGUMENTOS COMUNES DE sim-outorder
# ==============================================================================
ARGS_COMMON=(
    -fastfwd "$FASTFWD"
    -max:inst "$MAX_INST"
    -fetch:ifqsize "$FETCH_IFQ"
    -decode:width "$DECODE_W"
    -issue:width "$ISSUE_W"
    -commit:width "$COMMIT_W"
    -ruu:size "$RUU_SIZE"
    -lsq:size "$LSQ_SIZE"
    -cache:il1 "$IL1"
    -cache:dl1 "$DL1"
    -cache:dl2 "$UL2"
    -mem:lat "$MEM_LAT_FC" "$MEM_LAT_IC"
    -mem:width "$BUS_WIDTH"
    -res:ialu "$IALU"
    -res:imult "$IMULT"
    -res:fpalu "$FPALU"
    -res:fpmult "$FPMULT"
    -res:memport "$MEMPORT"
)

# ==============================================================================
# 8. CABECERA DEL CSV GLOBAL
# ==============================================================================
CSV_HEADER="benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,bpred_miss,sim_cycle,sim_num_insn"
echo "$CSV_HEADER" > "$CSV_GLOBAL"

# ==============================================================================
# 9. BUCLE PRINCIPAL: EJECUCIÓN DE CADA BENCHMARK
# ==============================================================================
for BENCH in "${BENCHMARKS[@]}"; do
    print_header "[$BENCH] Preparando simulación"

    # --- 9.1 Preparar directorio de trabajo y copiar inputs ---
    prepare_inputs "$BENCH"
    cd "$WORK_DIR/$BENCH" || { echo "  [ERROR] no puedo entrar en $WORK_DIR/$BENCH"; continue; }

    # --- 9.2 Ficheros de salida ---
    SIM_TXT="$RESULTS_DIR/${BENCH}_$VARIANTE.txt"
    SUM_OUT="$RESULTS_DIR/${BENCH}_$VARIANTE.out"
    ERR_LOG="$LOG_DIR/${BENCH}_$VARIANTE.err"
    PROG_OUT="$LOG_DIR/${BENCH}_$VARIANTE.prog.out"
    CSV_BENCH="$RESULTS_DIR/${BENCH}_$VARIANTE.csv"

    # --- 9.3 Construir la línea de comando específica de cada benchmark ---
    case "$BENCH" in
        bzip2)
            EXE="/lib/specs2000/bzip2/exe/bzip2.exe"
            CMD=("$EXE" "input.source" "58")
            ;;
        ammp)
            EXE="/lib/specs2000/ammp/exe/ammp.exe"
            CMD=("$EXE" "<" "ammp.in")
            ;;
        gap)
            EXE="/lib/specs2000/gap/exe/gap.exe"
            CMD=("$EXE" "-l" "./" "-q" "-m" "192M" "<" "ref.in")
            ;;
        swim)
            EXE="/lib/specs2000/swim/exe/swim.exe"
            CMD=("$EXE" "<" "swim.in")
            ;;
        vpr)
            EXE="/lib/specs2000/vpr/exe/vpr.exe"
            CMD=("$EXE" "net.in" "arch.in" "place.out" "dum.out" \
                 "-nodisp" "-place_only" "-init_t" "5" "-exit_t" "0.005" \
                 "-alpha_t" "0.9412" "-inner_num" "2")
            ;;
        *)
            echo "  [ERROR] benchmark desconocido: $BENCH"
            continue
            ;;
    esac

    # --- 9.4 Lanzar sim-outorder ---
    # Nota: usamos "eval" para que los '<' se interpreten como redirección.
    echo "  Lanzando sim-outorder..."
    if [[ "$BENCH" == "ammp" || "$BENCH" == "gap" || "$BENCH" == "swim" ]]; then
        # Estos benchmarks usan '<' de stdin
        eval sim-outorder "${ARGS_COMMON[@]}" \
            -redir:sim "$SIM_TXT" \
            "${CMD[@]}" > "$PROG_OUT" 2> "$ERR_LOG"
    else
        # bzip2 y vpr reciben argumentos por línea de comandos
        sim-outorder "${ARGS_COMMON[@]}" \
            -redir:sim "$SIM_TXT" \
            "${CMD[@]}" > "$PROG_OUT" 2> "$ERR_LOG"
    fi

    # --- 9.5 Comprobar si ha producido stats ---
    if grep -q 'sim_IPC' "$SIM_TXT" 2>/dev/null; then
        echo "  [OK] $BENCH ha generado estadísticas."
    else
        echo "  [AVISO] $BENCH no ha generado 'sim_IPC'."
        echo "          Posible causa: el programa se agotó durante el fastfwd"
        echo "          de $FASTFWD instrucciones antes de empezar a medir."
        echo "          Los benchmarks afectados NO aparecerán con IPC en el CSV."
        # Borramos el .out si no hay stats; ya no sirve
        rm -f "$SUM_OUT" "$CSV_BENCH"
        # Limpieza de ficheros vacíos
        cleanup_empty "$ERR_LOG" "$PROG_OUT"
        continue
    fi

    # --- 9.6 Resumen rico en .out ---
    {
        echo "=== RESUMEN $BENCH ($VARIANTE) ==="
        date
        echo "--- Rendimiento ---"
        grep -E 'sim_num_insn|sim_num_refs|sim_num_branches|sim_cycle|sim_IPC|sim_CPI|sim_exec_BW|sim_IPB' "$SIM_TXT"
        echo "--- Ocupación de buffers ---"
        grep -E 'ifq_occupancy|ifq_full|ruu_occupancy|ruu_full|lsq_occupancy|lsq_full|sim_slip|avg_sim_slip' "$SIM_TXT"
        echo "--- Branch prediction ---"
        grep -E 'bpred_bimod.bpred_dir_rate|bpred_bimod.bpred_addr_rate|bpred_bimod.misses|bpred_bimod.updates' "$SIM_TXT"
        echo "--- Caché L1I ---"
        grep -E '^il1\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo "--- Caché L1D ---"
        grep -E '^dl1\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo "--- Caché L2 ---"
        grep -E '^ul2\.(accesses|hits|misses|miss_rate)' "$SIM_TXT"
        echo "--- TLBs ---"
        grep -E '^(itlb|dtlb)\.(accesses|misses|miss_rate)' "$SIM_TXT"
    } > "$SUM_OUT"
    echo "  [OK] Resumen guardado en $SUM_OUT"

    # --- 9.7 Extraer métricas y escribir CSV del benchmark ---
    IPC=$(extract "$SIM_TXT" "sim_IPC")
    CPI=$(extract "$SIM_TXT" "sim_CPI")
    L1I=$(extract "$SIM_TXT" "il1.miss_rate")
    L1D=$(extract "$SIM_TXT" "dl1.miss_rate")
    L2=$(extract "$SIM_TXT" "ul2.miss_rate")
    IFQ=$(extract "$SIM_TXT" "ifq_occupancy")
    RUU=$(extract "$SIM_TXT" "ruu_occupancy")
    LSQ=$(extract "$SIM_TXT" "lsq_occupancy")
    BPR=$(extract "$SIM_TXT" "bpred_bimod.bpred_dir_rate")
    BMISS=$(extract "$SIM_TXT" "bpred_bimod.misses")
    CYC=$(extract "$SIM_TXT" "sim_cycle")
    NINS=$(extract "$SIM_TXT" "sim_num_insn")

    echo "benchmark,IPC,CPI,L1I_miss,L1D_miss,L2_miss,IFQ_occ,RUU_occ,LSQ_occ,BPR_dir,bpred_miss,sim_cycle,sim_num_insn" > "$CSV_BENCH"
    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$BMISS,$CYC,$NINS" >> "$CSV_BENCH"
    echo "  [OK] CSV individual en $CSV_BENCH"

    # --- 9.8 Añadir fila al CSV global ---
    echo "$BENCH,$IPC,$CPI,$L1I,$L1D,$L2,$IFQ,$RUU,$LSQ,$BPR,$BMISS,$CYC,$NINS" >> "$CSV_GLOBAL"

    # --- 9.9 Limpieza de ficheros vacíos ---
    cleanup_empty "$ERR_LOG" "$PROG_OUT"

done

# ==============================================================================
# 10. RESUMEN FINAL POR PANTALLA
# ==============================================================================
print_header "RESUMEN FINAL ($VARIANTE)"
if [ -s "$CSV_GLOBAL" ]; then
    column -t -s, "$CSV_GLOBAL" 2>/dev/null || cat "$CSV_GLOBAL"
else
    echo "  (no se generó ningún resultado)"
fi

echo ""
echo "Ficheros generados:"
echo "  Resultados:  $RESULTS_DIR"
echo "  Logs:        $LOG_DIR"
echo "  CSV global:  $CSV_GLOBAL"

# ==============================================================================
# 11. GRÁFICAS CON GNUPLOT (opcional, si está instalado)
# ==============================================================================
if command -v gnuplot >/dev/null 2>&1; then
    echo ""
    echo "  [OK] gnuplot detectado. Generando gráficas..."

    GNU_SCRIPT="$RESULTS_DIR/plot_$VARIANTE.gnu"
    cat > "$GNU_SCRIPT" <<EOF
set datafile separator ","
set terminal png size 1000,600
set style data histograms
set style histogram clustered gap 1
set style fill solid 1.0 border -1
set boxwidth 0.9
set xtics rotate by -30
set ylabel "IPC"
set title "IPC por benchmark - $VARIANTE"

set output "$RESULTS_DIR/grafica_ipc_$VARIANTE.png"
plot "$CSV_GLOBAL" using 2:xtic(1) title "IPC"
EOF
    gnuplot "$GNU_SCRIPT" 2>/dev/null && echo "  [OK] Gráfica: $RESULTS_DIR/grafica_ipc_$VARIANTE.png"
else
    echo ""
    echo "  [INFO] gnuplot no instalado. Instálalo con: sudo apt install gnuplot"
fi

echo ""
echo "=== FIN ==="