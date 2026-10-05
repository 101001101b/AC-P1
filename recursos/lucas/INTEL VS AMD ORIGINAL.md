## 0. Resultados originales de los benchmarks

 RESUMEN FINAL (AMD_Zen5)
benchmark  IPC     CPI     L1I_miss  L1D_miss  L2_miss  IFQ_occ  RUU_occ   LSQ_occ   BPR_dir  sim_cycle  sim_num_insn
bzip2      3.4080  0.2934  0.0000    0.0059    0.1781   9.6099   272.4547  96.3940   0.9938   29342341   100000001
ammp       0.1911  5.2325  0.0000    0.1293    0.9893   15.5423  493.1925  245.5709  0.9668   523247136  100000002
gap        3.3523  0.2983  0.0001    0.0301    0.4827   9.7987   266.0072  141.6556  0.9731   12022462   40303291
swim       5.7843  0.1729  0.0000    0.0026    0.5031   13.2747  511.0943  189.3405  0.9999   17288172   100000005
vpr        1.9328  0.5174  0.0000    0.0073    0.2617   5.2841   71.9020   14.8939   0.8599   51739373   100000000
[OK] Gráfica: /home/milax/Documents/AC-P1/results/AMD_Zen5/grafica_ipc.png



Perfecto, ahora sí tenemos la comparación **base vs base**. Aquí tienes el análisis completo, estructurado como pide el enunciado.

## 1. Tabla comparativa (AMD Zen 5 vs Intel Cougar Cove)

| Benchmark   | IPC AMD   | IPC Intel | Δ           | Ganador   |
| ----------- | --------- | --------- | ----------- | --------- |
| bzip2       | 3,408     | 3,461     | +1,6 %      | Intel     |
| **ammp**    | **0,191** | **1,068** | **+459 %**  | **Intel** |
| gap         | 3,352     | 3,337     | −0,5 %      | Empate    |
| swim        | 5,784     | 5,808     | +0,4 %      | Empate    |
| **vpr**     | **1,933** | **2,220** | **+14,9 %** | **Intel** |
| **MITJANA** | **2,934** | **3,133** | **+6,8 %**  | **Intel** |

**Diferencia total**: Intel gana por +6,8 % de media, pero **casi toda la ventaja viene de un solo benchmark: ammp**. Sin ammp, las dos máquinas son prácticamente idénticas.

## 2. Análisis por benchmark

### bzip2 — Empate técnico (IPC ≈ 3,43)

|Métrica|AMD|Intel|
|---|---|---|
|IPC|3,408|3,461|
|L2_miss|0,1781|0,1717|
|RUU_occ|272 / 512 (53 %)|277 / 512 (54 %)|
|LSQ_occ|96 / 256 (38 %)|98 / 256 (38 %)|

Ambos procesadores están **limitados por el ancho de emisión** (8 vías → IPC máx 8, se queda en ~3,4). Ni buffers ni cachés son cuello de botella. La diferencia del 1,6 % viene de la L2 ligeramente mejor de Intel.

### ammp — El benchmark que rompe la comparación

|Métrica|AMD|Intel|Ratio|
|---|---|---|---|
|IPC|0,191|1,068|**5,6×**|
|sim_cycle|523 M|94 M|5,6×|
|**L2_miss**|**0,9893**|**0,0091**|**109×**|
|RUU_occ|493 / 512 (96 %)|406 / 512 (79 %)||
|LSQ_occ|246 / 256 (96 %)|200 / 256 (78 %)||
|IFQ_occ|15,5 / 16 (97 %)|13,5 / 16 (84 %)||
|avg_sim_slip|3824|562|6,8×|

**Aquí está el 90 % de la diferencia entre AMD e Intel.**

La causa es clarísima: **la L2 de AMD (1 MB) se queda corta para el working set de ammp**. Cuando el working set supera 1 MB, cada acceso falla en L2 y va a memoria principal (149 ciclos). Con Intel (2 MB), el working set cabe y la tasa de fallos cae al 0,9 %.

Efecto en cascada:

1. L2 miss 99 % → cada load tarda ~150 ciclos.
    
2. RUU se llena (96 %) esperando a que vuelvan los datos.
    
3. LSQ se llena (96 %) porque no se pueden retirar loads.
    
4. IFQ se llena (97 %) porque el front-end no puede avanzar.
    
5. IPC se hunde a 0,19.
    

**ammp es el caso de manual de "cache-bound por L2 insuficiente".**

### gap — Empate (IPC ≈ 3,35)

|Métrica|AMD|Intel|
|---|---|---|
|IPC|3,352|3,337|
|L2_miss|0,4827|0,4838|
|RUU_occ|266 / 512 (52 %)|266 / 512 (52 %)|
|LSQ_occ|142 / 256 (55 %)|142 / 256 (55 %)|

Idénticos. La L2 falla ~48 % en ambos, pero el programa tolera bien la latencia (poca dependencia de datos). **Ningún recurso saturado** → no hay margen de mejora evidente.

### swim — Empate con RUU al límite (IPC ≈ 5,79)

|Métrica|AMD|Intel|
|---|---|---|
|IPC|5,784|5,808|
|L2_miss|0,5031|0,5031|
|**RUU_occ**|**511 / 512 (99,8 %)**|**511 / 512 (99,8 %)**|
|LSQ_occ|189 / 256 (74 %)|190 / 256 (74 %)|

Aquí hay un dato clave: **la RUU está al 99,8 % en ambos**. Eso significa que **el cuello de botella es la ventana de instrucciones**. Con una RUU más grande, swim podría extraer más paralelismo.

Pero atención: swim da IPC 5,79 con RUU 512. Si subes la RUU a 1024, no esperes el doble; probablemente suba a 6,5–7 y luego se estanque en otro recurso (puertos de memoria, L2, etc.).

### vpr — Intel gana por la L2 (IPC 1,93 vs 2,22)

|Métrica|AMD|Intel|Ratio|
|---|---|---|---|
|IPC|1,933|2,220|1,15×|
|L2_miss|0,2617|0,1909|1,37×|
|RUU_occ|72 / 512 (14 %)|66 / 512 (13 %)||
|LSQ_occ|15 / 256 (6 %)|14 / 256 (6 %)||
|BPR_dir|0,860|0,892|—|

Los buffers están **casi vacíos** (14 % y 6 %). El cuello de botella no es la ventana ni la cola: es **la memoria** (L2 miss 26 % en AMD vs 19 % en Intel) y **el branch predictor** (86 % en AMD vs 89 % en Intel).

La mejora de Intel viene de dos frentes:

- **L2 más grande** (2 MB vs 1 MB) → menos fallos.
    
- **Mejor predictor** (probablemente la config Intel por defecto es más agresiva, o el BPR se beneficia del L2 más grande).
    

## 3. Análisis por bloque del procesador

### Bloque 1 — Front-end (k-vía)

Ambos tienen fetch/decode/issue/commit = 16/8/8/8. **No es cuello de botella** en ninguno de los 5 benchmarks (IFQ nunca está al 100 %). Si acaso, ammp en AMD tiene IFQ al 97 %, pero no es la causa raíz; es consecuencia del bloqueo en memoria.

### Bloque 2 — Buffers (RUU y LSQ)

|Benchmark|RUU_occ (AMD)|Diagnóstico|
|---|---|---|
|bzip2|53 %|Holgado|
|ammp|**96 %**|**Saturado** → culpa de la L2|
|gap|52 %|Holgado|
|swim|**99,8 %**|**Saturado** → culpa de la ventana pequeña|
|vpr|14 %|Holgado|

**swim es el único caso donde la RUU pequeña es la causa raíz** (no consecuencia). En ammp, la RUU está llena porque los datos no llegan, no al revés.

### Bloque 3 — Cachés

|Benchmark|L1I|L1D|L2 (AMD)|L2 (Intel)|
|---|---|---|---|---|
|bzip2|0 %|0,6 %|17,8 %|17,2 %|
|ammp|0 %|13 %|**98,9 %**|**0,9 %**|
|gap|0 %|3,0 %|48,3 %|48,4 %|
|swim|0 %|0,3 %|50,3 %|50,3 %|
|vpr|0 %|0,7 %|26,2 %|19,1 %|

- **L1I**: perfecta, no hay que tocarla.
    
- **L1D**: bien en general, solo ammp tiene un 13 % (aceptable).
    
- **L2**: es el problema. **ammp y swim con ~50–99 % de fallos** son los candidatos claros a mejora.
    

### Bloque 4 — Memoria principal

AMD: DDR5-5600 (`-mem:lat 149 1`).  
Intel: LPDDR5X-9600 (`-mem:lat 142 1`).

Prácticamente iguales. La diferencia de ammp no viene de aquí, viene de la L2.

### Bloque 5 — Recursos funcionales

|Recurso|AMD|Intel|
|---|---|---|
|IALU|6|6|
|IMULT|3|3|
|FPALU|4|4|
|FPMULT|2|2|
|**MEMPORT**|**4**|**3**|

Intel tiene **un puerto de memoria menos**, pero rinde igual o mejor. Conclusión: **el número de puertos no es limitante** en estos benchmarks. No merece la pena subirlo.

## 4. Diagnóstico de cuellos de botella (lo que pide el enunciado)

|Benchmark|Cuello de botella principal|Evidencia|
|---|---|---|
|bzip2|Ancho de emisión (8 IPC teórico)|IPC 3,4 con todo holgado|
|**ammp**|**L2 insuficiente (1 MB)**|L2_miss 99 % + RUU/LSQ/IFQ saturados|
|gap|L2 con 48 % fallos, pero tolerado|IPC 3,35 sin recursos saturados|
|**swim**|**RUU pequeña (512)**|RUU_occ 99,8 %, IPC 5,78|
|**vpr**|**L2 + branch predictor**|L2_miss 26 %, BPR 86 %, buffers vacíos|

## 5. Propuestas de mejora (para la parte del enunciado)

El enunciado pide **mínimo 3 parámetros** con propuesta de mejora. Aquí tienes 4 candidatos, todos justificados con datos:

### Mejora 1 — Ampliar la L2 (1 MB → 2 MB en AMD)

**Justificación**: ammp pasa de L2_miss 99 % a 0,9 % solo por tener 2 MB (lo confirma el propio Intel). IPC de ammp subiría de 0,19 a ~1,07 → **×5,6 en ese benchmark**. La media de AMD subiría de 2,93 a ~3,11.

**Cómo probarlo**:

bash

UL2="ul2:2048:64:16:l"   # 2 MB, 64 B, 16 vías -> 2048 sets

### Mejora 2 — Ampliar la RUU (512 → 1024 en AMD)

**Justificación**: swim tiene la RUU al 99,8 %. Más ventana → más instrucciones en vuelo → más paralelismo. Esperable IPC de swim suba de 5,78 a ~6,5–7.

**Cómo probarlo**:

bash

RUU_SIZE=1024

⚠️ Ojo: ya lo probaste y viste que **ammp empeoró** (0,19 → 0,11) con `RUU=1024 LSQ=512`. Eso es porque al agrandar la ventana, el procesador mete más instrucciones en vuelo, satura antes la L2, y el sistema entra en un estado peor. **No es que la RUU sea mala, es que sin arreglar la L2 primero, agrandar la RUU empeora ammp.** Es un excelente ejemplo de "cuello de botella en cadena".

### Mejora 3 — Ampliar la L2 (2 MB → 4 MB en Intel)

**Justificación**: swim y gap tienen L2_miss ~50 % en Intel también. Si la L2 fuera más grande, ambos mejorarían. Para swim (RUU al 99,8 %), la combinación de L2 más grande **y** RUU más grande sería la ganadora.

**Cómo probarlo**:

bash

UL2="ul2:4096:64:16:l"   # 4 MB -> 4096 sets

### Mejora 4 — Mejorar el branch predictor (bimodal → 2-level)

**Justificación**: vpr tiene BPR del 86 % (AMD) y 89 % (Intel). Un predictor de 2 niveles (gshare) suele dar +3–5 % de acierto. Con 4 % más de aciertos y vpr siendo branch-heavy, el IPC podría subir 5–10 %.

**Cómo probarlo**:

bash

# Añadir a ARGS_COMMON:
-bpred 2lev -bpred:2lev 1 1024 8 0

⚠️ Esto no lo pide el enunciado explícitamente (el enunciado pide front-end, buffers, cachés, memoria, recursos). Pero es una mejora legítima y muy didáctica.

## 6. Recomendación de plan de pruebas para las gráficas

El enunciado pide gráficas con IPC por benchmark y media, comparando configuraciones. Te propongo 4 variantes para tener una comparativa rica:

|Variante|Cambio|Archivo|
|---|---|---|
|`AMD_Zen5`|Base|ya lo tienes|
|`AMD_Zen5_L2_2MB`|`UL2="ul2:2048:64:16:l"`|copia y cambia `UL2`|
|`AMD_Zen5_RUU_1024`|`RUU_SIZE=1024`|copia y cambia `RUU_SIZE`|
|`AMD_Zen5_mejorado`|L2 2 MB + RUU 1024 + BPR 2lev|copia y cambia todo|

Con esto tienes una gráfica de 4 barras por benchmark y la media, que es exactamente lo que pide el enunciado (mirar el ejemplo de la página 3 del PDF).

## 7. Resumen ejecutivo (para el informe)

> AMD Zen 5 e Intel Cougar Cove rinden de forma casi idéntica en 4 de los 5 benchmarks (bzip2, gap, swim, vpr). La única diferencia significativa está en **ammp**, donde Intel es **5,6× más rápido** por tener el doble de L2 (2 MB vs 1 MB). El working set de ammp supera 1 MB, lo que provoca un 99 % de fallos en la L2 de AMD, satura la RUU, la LSQ y la IFQ, y hunde el IPC a 0,19. La segunda diferencia está en **vpr**, donde Intel gana un 15 % por mejor L2 y mejor predictor de saltos. Los cuellos de botella identificados son: (1) L2 insuficiente en ammp, (2) RUU pequeña en swim, (3) L2 + branch predictor en vpr. Las mejoras propuestas son ampliar la L2 a 2 MB, ampliar la RUU a 1024 y mejorar el branch predictor a 2 niveles.

`AC-P1/
├── scripts/
│   ├── amd_zen5.sh
│   ├── amd_zen5_L2_2MB.sh          <- copia + 1 cambio
│   ├── amd_zen5_L2_4MB.sh
│   ├── amd_zen5_RUU_1024.sh
│   ├── amd_zen5_LSQ_512.sh
│   ├── amd_zen5_mejorado.sh
│   ├── intel_cougarcove.sh
│   ├── intel_L2_4MB.sh
│   ├── intel_L2_8MB.sh
│   ├── intel_RUU_1024.sh
│   ├── intel_MEMPORT_4.sh
│   ├── intel_mejorado.sh
│   ├── run_all.sh
│   └── compare.sh
├── specwork/
│   ├── bzip2/{bzip2.exe, input.source}
│   ├── ammp/{ammp.exe, ammp.in}
│   ├── gap/{gap.exe, ref.in}
│   ├── swim/{swim.exe, swim.in}
│   └── vpr/{vpr.exe, net.in, arch.in}
├── results/
│   ├── AMD_Zen5/run_2026-10-05_14-30-22/...
│   ├── Intel_CougarCove/run_.../...
│   └── _comparativa/
└── README.md`