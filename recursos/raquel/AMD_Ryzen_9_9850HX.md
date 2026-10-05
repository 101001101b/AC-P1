---
asignatura: "[[AC]]"
pdf: ""
fecha: 2026-09-26
---
#### 1. Els que determinen la k-via del processador. La quantitat d’instruccions per cicle que poden arribar a tractar: fetch, decode, issue i commit.
##### Fetch
llegeix fins a 2 blocs de 32B cada cicle → 64 B/cicle
##### Decode
8 instrucciones/ciclo (2 clústers paralelos de decodificación de 4 + 4 vías)
##### Issue
8 wide dispatch → 8  microops/cicle despachadas hacia las colas de enteros y vectores
##### Commit
8 instruccions/cicle

#### 2. Els que determinen la mida dels buffers que emmagatzemen instruccions: finestra instruccions (ruu) i cua d'accés a memòria (lsq).
##### ruu
- 448 entrades -> 512
##### LSQ
- Load queue: 64 
- Store queue: 104 
- Total LSQ = 168 -> 256 entrades

#### 3. Els que determinen les caches L1 i L2. Si manipulen per separat instruccions i dades i les que determinen la mida, associativitat i algoritme de reemplaçament.
##### cache L1
- Divisió instruccions/dades: Sí
- Mida (per core):
	- L1 Instruccions: 32KB 
	- L1 Dades: 48KB -> 32KB
- Associativitat:
	- L1 Instruccions: 8 vies
	- L1 Dades: 12 vies -> 8
##### cache L2
- Divisió instruccions/dades: No
- Mida (per core): 1MB
- Associativitat: 16 vies
##### Algoritme reemplaçament
- LRU (Least Recently Used)
#### 4. Els que determinen l'ample del BUS i la latència de la memòria principal.
[[latencia_memoria]]
>utilitza DDR5-5600

- Amplada de banda: 89.6 GB/s
- Latència: 14.28 ns
- Ample bus: 128b -> 16B

> Latencia (ns)= (CL×2000)/Velocidad en MT/s​
##### latència DRAM per al [[simplescalar_mapeo_parametros]]

 - CPU_clock: 5.2 GHz -> 5200 MHz
- Memory_clock: 2800 MHz
- CAS: 40 cicles
- tRCD: 40 cicles
- Memory_data_rate: 5600 MT/s (5600MHz de tasa)

$first chunk = (CPU clock * (CAS + tRCD))/ Memory Clock$

(5200x(40+40))/2800 = 149 cicles

$inter chunk = CPU Clock / Memory Data Rate$

5200/5600 = 0.93 = 1 ciclo
#### 5. Els que determinen els recursos a nivell d'unitats funcionals: números d'ALUs aritmètiques i multiplicació d'integers, ALUs aritmètiques i multiplicació de coma flotant i el nombre de ports d'accés a memòria de primer nivell de cache

- ALUs aritmètiques d'enters: 6
	- Multiplicació d'enters: 3
- ALUs de coma flotant: 4
	- Multiplicació de coma flotant: 2
- Ports d'accés a la cache L1


### Fuentes
--- 
Especificaciones:
	[AMD Ryzen 9 9850HX Specs \| TechPowerUp CPU Database](https://www.techpowerup.com/cpu-specs/ryzen-9-9850hx.c4038)

Documentación Zen5:
	[AMD Zen5 Software Optimization Guide \| PDF \| Cpu Cache \| Central Processing Unit](https://es.scribd.com/document/830344700/58455-1-00) 
	
Memory data rate:
	[Details of AMD Ryzen 9 9850HX](https://www.eatyourbytes.com/cpu-detail/amd-ryzen-9-9850hx/)

DDR5-5600 CAS
	 [Is DDR5-5600 RAM Good Enough? What You Need to Know Before Buying](https://electronics.alibaba.com/question/ddr5-5600-ram-is-it-right-for-your-build)

### Mesures de rendiment
---
[AMD Ryzen 9 9850HX Benchmark](https://www.cpubenchmark.net/cpu.php?cpu=AMD+Ryzen+9+9850HX&id=6859)
