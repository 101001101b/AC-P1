


1. Els que determinen la mida dels buffers que emmagatzemen instruccions: finestra instruccions (ruu) i cua d'accés a memòria (lsq). 
2. Els que determinen les caches L1 i L2. Si manipulen per separat instruccions i dades i les que determinen la mida, associativitat i algoritme de reemplaçament. 
3. Els que determinen l'ample del BUS i la latència de la memòria principal. 
4. Els que determinen els recursos a nivell d'unitats funcionals: números d'ALUs aritmètiques i multiplicació d'integers, ALUs aritmètiques i multiplicació de coma flotant i el nombre de ports d'accés a memòria de primer nivell de cache
--------------------------------------------------------------------
1. Els que determinen la k-via del processador. La quantitat d’instruccions per cicle que poden arribar a tractar: fetch, decode, issue i commit. 

`fetch:ifqsize :` número de instrucciones que caben en la cola de instrucciones capturadas por el front-end (instrucciones fetch queue). En este caso puede decodificar 8 instrucciones por ciclo, pero la cola insterna de micro-ops es mas grande.
*se aproxima con 16 para modelar ese colchón entre fetch y decode. Se busca en las specs como "Op caché size" o "instruction queue entries"*

	`FETCH_IFQ=16`

`decode:width :` nuero maximo de instrucciones decodificadas por ciclo.

