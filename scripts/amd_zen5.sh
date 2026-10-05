#!/bin/bash

# ==============================================================================
# SCRIPT AMD ZEN 5 - ARQUITECTURA DE COMPUTADORES
# Adaptado exactamente a la estructura funcional de amd_default.sh
# ==============================================================================

# 1. Configuración de Cachés (Cálculos de nsets para potencias de 2)
# nsets = tamaño / (bloque * assoc)
nsets_il1=$(( (32 * 1024) / (64 * 8) ))        # 32KB, 64B, 8 vías = 64
nsets_dl1=$(( (32 * 1024) / (64 * 8) ))        # 32-48KB adaptada a 8 vías = 64
nsets_ul2=$(( (1 * 1024 * 1024) / (64 * 16) )) # 1MB, 64B, 16 vías = 1024

il1="il1:"$nsets_il1":64:8:l"
dl1="dl1:"$nsets_dl1":64:8:l"
ul2="ul2:"$nsets_ul2":64:16:l"

# 2. Pipeline y Buffers
fetch=16
decode=8
issue=8
commit=8
ruu=512   # ROB real 448 adaptado a potencia de 2
lsq=256   # LSQ real 168 adaptado a potencia de 2

# 3. Bus y memoria DRAM (DDR5-5600)
lat_fc=149  # Latencia primer bloque
lat_ic=1    # Latencia bloques intermedios
busWidth=16 # Ancho del bus en bytes (128 bits)

# 4. Recursos funcionales
alus_e=6
mult_e=3
alus_fp=4
mult_fp=2
memport=4

# 5. Parámetros de simulación e informe
inst=100000000
results="/home/milax/Documents/AC-P1/results/AMD_Zen5/"
out="_IPC_AMD.out"

mkdir -p "$results"

echo "=== INICIANDO BENCHMARKS AMD ZEN 5 ==="
echo "Los resultados se guardan en: $results"
echo "--------------------------------------------------------"

# ------------------------------------------------------------------------------
# [1/5] AMMP TEST
# ------------------------------------------------------------------------------
echo "[1/5] Ejecutando AMMP (tarda entre 10 y 20 minutos, paciencia)..."
cd /lib/specs2000/ammp/data/ref
sim-outorder -fastfwd \(inst -max:inst\)inst \
    -redir:sim $results"ammp.txt" \
    -fetch:ifqsize $fetch \
    -decode:width $decode \
    -issue:width $issue \
    -commit:width $commit \
    -ruu:size $ruu \
    -lsq:size $lsq \
    -mem:lat \(lat_fc\)lat_ic \
    -mem:width $busWidth \
    -res:ialu $alus_e \
    -res:imult $mult_e \
    -res:fpalu $alus_fp \
    -res:fpmult $mult_fp \
    -res:memport $memport \
    -cache:dl1 $dl1 \
    -cache:il1 $il1 \
    -cache:dl2 $ul2 \
    ../../exe/ammp.exe < ammp.in > ammp.out 2> ammp.err

echo "AMMP" > \(results\)out
grep 'sim_IPC' \(results"ammp.txt" >>\)results$out
echo "-> AMMP finalizado."

# ------------------------------------------------------------------------------
# [2/5] BZIP2 TEST
# ------------------------------------------------------------------------------
echo "[2/5] Ejecutando BZIP2..."
cd /lib/specs2000/bzip2/data/ref
sim-outorder -fastfwd \(inst -max:inst\)inst \
    -redir:sim $results"bzip2.txt" \
    -fetch:ifqsize $fetch \
    -decode:width $decode \
    -issue:width $issue \
    -commit:width $commit \
    -ruu:size $ruu \
    -lsq:size $lsq \
    -mem:lat \(lat_fc\)lat_ic \
    -mem:width $busWidth \
    -res:ialu $alus_e \
    -res:imult $mult_e \
    -res:fpalu $alus_fp \
    -res:fpmult $mult_fp \
    -res:memport $memport \
    -cache:dl1 $dl1 \
    -cache:il1 $il1 \
    -cache:dl2 $ul2 \
    ../../exe/bzip2.exe input.source 58 > bzip2.out 2> bzip2.err

echo "BZIP2" >> \(results\)out
grep 'sim_IPC' \(results"bzip2.txt" >>\)results$out
echo "-> BZIP2 finalizado."

# ------------------------------------------------------------------------------
# [3/5] GAP TEST
# ------------------------------------------------------------------------------
echo "[3/5] Ejecutando GAP..."
cd /lib/specs2000/gap/data/ref
sim-outorder -fastfwd \(inst -max:inst\)inst \
    -redir:sim $results"gap.txt" \
    -fetch:ifqsize $fetch \
    -decode:width $decode \
    -issue:width $issue \
    -commit:width $commit \
    -ruu:size $ruu \
    -lsq:size $lsq \
    -mem:lat \(lat_fc\)lat_ic \
    -mem:width $busWidth \
    -res:ialu $alus_e \
    -res:imult $mult_e \
    -res:fpalu $alus_fp \
    -res:fpmult $mult_fp \
    -res:memport $memport \
    -cache:dl1 $dl1 \
    -cache:il1 $il1 \
    -cache:dl2 $ul2 \
    ../../exe/gap.exe -l ./ -q -m 192M < ref.in > gap.out 2> gap.err

echo "GAP" >> \(results\)out
grep 'sim_IPC' \(results"gap.txt" >>\)results$out
echo "-> GAP finalizado."

# ------------------------------------------------------------------------------
# [4/5] SWIM TEST
# ------------------------------------------------------------------------------
echo "[4/5] Ejecutando SWIM..."
cd /lib/specs2000/swim/data/ref
sim-outorder -fastfwd \(inst -max:inst\)inst \
    -redir:sim $results"swim.txt" \
    -fetch:ifqsize $fetch \
    -decode:width $decode \
    -issue:width $issue \
    -commit:width $commit \
    -ruu:size $ruu \
    -lsq:size $lsq \
    -mem:lat \(lat_fc\)lat_ic \
    -mem:width $busWidth \
    -res:ialu $alus_e \
    -res:imult $mult_e \
    -res:fpalu $alus_fp \
    -res:fpmult $mult_fp \
    -res:memport $memport \
    -cache:dl1 $dl1 \
    -cache:il1 $il1 \
    -cache:dl2 $ul2 \
    ../../exe/swim.exe < swim.in > swim.out 2> swim.err

echo "SWIM" >> \(results\)out
grep 'sim_IPC' \(results"swim.txt" >>\)results$out
echo "-> SWIM finalizado."

# ------------------------------------------------------------------------------
# [5/5] VPR TEST
# ------------------------------------------------------------------------------
echo "[5/5] Ejecutando VPR..."
cd /lib/specs2000/vpr/data/ref
sim-outorder -fastfwd \(inst -max:inst\)inst \
    -redir:sim $results"vpr.txt" \
    -fetch:ifqsize $fetch \
    -decode:width $decode \
    -issue:width $issue \
    -commit:width $commit \
    -ruu:size $ruu \
    -lsq:size $lsq \
    -mem:lat \(lat_fc\)lat_ic \
    -mem:width $busWidth \
    -res:ialu $alus_e \
    -res:imult $mult_e \
    -res:fpalu $alus_fp \
    -res:fpmult $mult_fp \
    -res:memport $memport \
    -cache:dl1 $dl1 \
    -cache:il1 $il1 \
    -cache:dl2 $ul2 \
    ../../exe/vpr.exe net.in arch.in place.out dum.out -nodisp -place_only -init_t 5 -exit_t 0.005 -alpha_t 0.9412 -inner_num 2 > place_log.out 2> place_log.err

echo "VPR" >> \(results\)out
grep 'sim_IPC' \(results"vpr.txt" >>\)results$out
echo "-> VPR finalizado."

echo ""
echo "=== SIMULACIONES COMPLETADAS CON ÉXITO ==="
cat \(results\)out