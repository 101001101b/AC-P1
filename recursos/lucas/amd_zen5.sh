#!/bin/bash
# ==============================================================================
# PRÁCTICA 1: ARQUITECTURA DE COMPUTADORES (AC-P1)
# MODELADO DEL PROCESADOR: AMD RYZEN 9 9850HX (ZEN 5)
# SIMULADOR: SimpleScalar / Alpha (sim-outorder)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. DIRECTORIOS DE TRABAJO
# ------------------------------------------------------------------------------
RESULTS_DIR="/home/milax/Documents/AC-P1/results/AMD_Zen5"
SPEC_DIR="/lib/specs2000"
RESUMEN="$RESULTS_DIR/_IPC_AMD.out"

mkdir -p "$RESULTS_DIR"

echo "=========================================================="
echo " INICIANDO SIMULACIONES AMD ZEN 5"
echo " Directorio de salida: $RESULTS_DIR"
echo "=========================================================="
echo "=== RESUMEN IPC AMD ZEN 5 ===" > "$RESUMEN"

# ------------------------------------------------------------------------------
# 2. PARÁMETROS DEL MODELO AMD ZEN 5
#    (8-way, buffers potencias de 2, DDR5-5600)
# ------------------------------------------------------------------------------
ARGS="-fastfwd 100000000 -max:inst 100000000 -fetch:ifqsize 16 -decode:width 8 -issue:width 8 -commit:width 8 -ruu:size 512 -lsq:size 256 -cache:il1 il1:64:64:8:l -cache:dl1 dl1:64:64:8:l -cache:dl2 ul2:1024:64:16:l -mem:lat 149 1 -mem:width 16 -res:ialu 6 -res:imult 3 -res:fpalu 4 -res:fpmult 2 -res:memport 4"


# ------------------------------------------------------------------------------
# 3. EJECUCIÓN DE LOS 5 BENCHMARKS
# ------------------------------------------------------------------------------

# [1/5] BZIP2
echo ""
echo "[1/5] Ejecutando bzip2..."
cd "$SPEC_DIR/bzip2/data/ref"|| exit 1
sim-outorder $ARGS -redir:sim "$RESULTS_DIR/bzip2.txt" ../../exe/bzip2.exe input.source 58 > "$RESULTS_DIR/bzip2.out" 2> "$RESULTS_DIR/bzip2.err"
if [ $? -eq 0 ]; then
    echo "      -> [OK] bzip2 finalizado."
    echo "BZIP2:" >> "$RESUMEN"
    grep 'sim_IPC' "$RESULTS_DIR/bzip2.txt" >> "$RESUMEN"
else
    echo "      -> [ERROR] bzip2 ha fallado."
fi


# [2/5] AMMP
echo ""
echo "[2/5] Ejecutando ammp..."
cd "$SPEC_DIR/ammp/data/ref"|| exit 1
sim-outorder $ARGS -redir:sim "$RESULTS_DIR/ammp.txt" ../../exe/ammp.exe < ammp.in > "$RESULTS_DIR/ammp.out" 2> "$RESULTS_DIR/ammp.err"
if [ $? -eq 0 ]; then
    echo "      -> [OK] ammp finalizado."
    echo "AMMP:" >> "$RESUMEN"
    grep 'sim_IPC' "$RESULTS_DIR/ammp.txt" >> "$RESUMEN"
else
    echo "      -> [ERROR] ammp ha fallado."
fi


# [3/5] GAP
echo ""
echo "[3/5] Ejecutando gap..."
cd "$SPEC_DIR/gap/data/ref"|| exit 1
sim-outorder $ARGS -redir:sim "$RESULTS_DIR/gap.txt" ../../exe/gap.exe -l ./ -q -m 192M < ref.in > "$RESULTS_DIR/gap.out" 2> "$RESULTS_DIR/gap.err"
if [ $? -eq 0 ]; then
    echo "      -> [OK] gap finalizado."
    echo "GAP:" >> "$RESUMEN"
    grep 'sim_IPC' "$RESULTS_DIR/gap.txt" >> "$RESUMEN"
else
    echo "      -> [ERROR] gap ha fallado."
fi


# [4/5] SWIM
echo ""
echo "[4/5] Ejecutando swim..."
cd "$SPEC_DIR/swim/data/ref"|| exit 1
sim-outorder $ARGS -redir:sim "$RESULTS_DIR/swim.txt" ../../exe/swim.exe < swim.in > "$RESULTS_DIR/swim.out" 2> "$RESULTS_DIR/swim.err"
if [ $? -eq 0 ]; then
    echo "      -> [OK] swim finalizado."
    echo "SWIM:" >> "$RESUMEN"
    grep 'sim_IPC' "$RESULTS_DIR/swim.txt" >> "$RESUMEN"
else
    echo "      -> [ERROR] swim ha fallado."
fi


# [5/5] VPR
echo ""
echo "[5/5] Ejecutando vpr..."
cd "$SPEC_DIR/vpr/data/ref"|| exit 1
sim-outorder $ARGS -redir:sim "$RESULTS_DIR/vpr.txt" ../../exe/vpr.exe net.in arch.in place.out dum.out -nodisp -place_only -init_t 5 -exit_t 0.005 -alpha_t 0.9412 -inner_num 2 > "$RESULTS_DIR/place_log.out" 2> "$RESULTS_DIR/place_log.err"
if [ $? -eq 0 ]; then
    echo "      -> [OK] vpr finalizado."
    echo "VPR:" >> "$RESUMEN"
    grep 'sim_IPC' "$RESULTS_DIR/vpr.txt" >> "$RESUMEN"
else
    echo "      -> [ERROR] vpr ha fallado."
fi


# ------------------------------------------------------------------------------
# 4. RESUMEN FINAL
# ------------------------------------------------------------------------------
echo ""
echo "=========================================================="
echo " RESUMEN FINAL DE IPC (AMD ZEN 5)"
echo "=========================================================="
cat "$RESUMEN"