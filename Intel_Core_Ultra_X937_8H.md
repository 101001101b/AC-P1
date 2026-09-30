---
asignatura: "[[AC]]"
pdf: ""
fecha: 2026-09-26
---
#### 1. Els que determinen la k-via del processador. La quantitat d’instruccions per cicle que poden arribar a tractar: fetch, decode, issue i commit.
##### Fetch
igual que LionCove, 48B/cicle
##### Decode
8 instrucciones/cicle -- 8 decodificadores
##### Issue
8 microops/cicle
##### Commit
8 instruccions/cicle

#### 2. Els que determinen la mida dels buffers que emmagatzemen instruccions: finestra instruccions (ruu) i cua d'accés a memòria (lsq).
##### ruu
- 576 entrades -> 512
##### LSQ 
-  Load queue: 189
- Store queue: 120
- Total LSQ = 309 -> 256/512 entrades

#### 3. Els que determinen les caches L1 i L2. Si manipulen per separat instruccions i dades i les que determinen la mida, associativitat i algoritme de reemplaçament.
##### cache L1
- Divisió instruccions/dades: Sí
- Mida (per core):
	- L1 Instruccions: 64KB
	- L1 Dades: 48KB (de la L0)
- Associativitat:
	- L1 Instruccions: 16 vies
	- L1 Dades: 12 vies
##### cache L2
- Divisió instruccions/dades: No
- Mida: 2,5MB fins a 3MB
- Associativitat: 12 vies
##### Algoritme reemplaçament
- LRU (en realitat un Tree-Based Pseudo LRU)
#### 4. Els que determinen l'ample del BUS i la latència de la memòria principal.
[[latencia_memoria]]
>LPDDR5X-9600

- Amplada de banda: GB/s
- Latència:
- Bus width:
##### ample bus
##### latència DRAM per al [[simplescalar_mapeo_parametros]]
- CPU_clock: 5.0 GHz ->
- Memory_clock: 4800 MHz
- CAS:
- tRCD:
- Memory_data_rate: 9600 MT/s

$first chunk = (CPU clock * (CAS + tRCD))/ Memory Clock$

$inter chunk = CPU Clock / Memory Data Rate$

#### 5. Els que determinen els recursos a nivell d'unitats funcionals: números d'ALUs aritmètiques i multiplicació d'integers, ALUs aritmètiques i multiplicació de coma flotant i el nombre de ports d'accés a memòria de primer nivell de cache
- ALUs aritmètiques d'enters: 6
	- Multiplicació d'enters: 3
- ALUs de coma flotant: 4
	- Multiplicació de coma flotant: 2
- Ports d'accés a la cache L1