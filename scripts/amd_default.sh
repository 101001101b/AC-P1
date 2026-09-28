#!/bin/bash

#=======  AMD  ========

# caches
# nsets = mida / (bloc * assoc)
nsets_il1=$(( (32 * 1024) / (64 * 8) ))        # 32KB, 64B, 8 vies = 64
nsets_dl1=$(( (32 * 1024) / (64 * 8) ))       # 48KB, 64B, 8 vies = 96 (eren 12 vies)
nsets_ul2=$(( (1 * 1024 * 1024) / (64 * 16) )) # 1MB, 64B, 16 vies = 1024

il1="il1:"$nsets_il1":64:8:l"
dl1="dl1:"$nsets_dl1":64:8:l"
ul2="ul2:"$nsets_ul2":64:16:l"

# pipeline i buffers
fetch=16
decode=8
issue=8
commit=8
ruu=512  # 448
lsq=256  # 168(64+104)

# bus i memoria dram
lat_fc=149  # (<first_chunk> <inter_chunk>)
lat_ic=1
busWidth=16

#recursos
alus_e=6
mult_e=3
alus_fp=4
mult_fp=2
memport=4  # ports acces L1D

inst=100000000
results="/home/milax/AC/results/AMD_default/"
out="_IPC.out"

# ammp test
cd /lib/specs2000/ammp/data/ref
	sim-outorder -fastfwd $inst -max:inst $inst \
	-redir:sim $results"ammp.txt" \
	-fetch:ifqsize $fetch \
	-decode:width $decode \
	-issue:width $issue \
	-commit:width $commit \
	-ruu:size $ruu \
	-lsq:size $lsq \
	-mem:lat $lat_fc $lat_ic \
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
echo "AMMP" > $results$out
grep 'sim_IPC' $results"ammp.txt" >> $results$out

# bzip2 test
cd /lib/specs2000/bzip2/data/ref
	sim-outorder -fastfwd $inst -max:inst $inst \
	-redir:sim $results"bzip2.txt" \
	-fetch:ifqsize $fetch \
	-decode:width $decode \
	-issue:width $issue \
	-commit:width $commit \
	-ruu:size $ruu \
	-lsq:size $lsq \
	-mem:lat $lat_fc $lat_ic \
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
echo "BZIP2" >> $results$out
grep 'sim_IPC' $results"bzip2.txt" >> $results$out

# gap test
cd /lib/specs2000/gap/data/ref
	sim-outorder -fastfwd $inst -max:inst $inst \
	-redir:sim $results"gap.txt" \
	-fetch:ifqsize $fetch \
	-decode:width $decode \
	-issue:width $issue \
	-commit:width $commit \
	-ruu:size $ruu \
	-lsq:size $lsq \
	-mem:lat $lat_fc $lat_ic \
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
echo "GAP" >> $results$out
grep 'sim_IPC' $results"gap.txt" >> $results$out

# swim test
cd /lib/specs2000/swim/data/ref
	sim-outorder -fastfwd $inst -max:inst $inst \
	-redir:sim $results"swim.txt" \
	-fetch:ifqsize $fetch \
	-decode:width $decode \
	-issue:width $issue \
	-commit:width $commit \
	-ruu:size $ruu \
	-lsq:size $lsq \
	-mem:lat $lat_fc $lat_ic \
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
echo "SWIM" >> $results$out
grep 'sim_IPC' $results"swim.txt" >> $results$out

# vpr test
cd /lib/specs2000/vpr/data/ref
	sim-outorder -fastfwd $inst -max:inst $inst \
	-redir:sim $results"vpr.txt" \
	-fetch:ifqsize $fetch \
	-decode:width $decode \
	-issue:width $issue \
	-commit:width $commit \
	-ruu:size $ruu \
	-lsq:size $lsq \
	-mem:lat $lat_fc $lat_ic \
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
echo "VPR" >> $results$out
grep 'sim_IPC' $results"vpr.txt" >> $results$out
