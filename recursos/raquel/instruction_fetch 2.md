---
asignatura: "[[AC]]"
fecha: 2026-09-26
ref: "[[AC_p1_investigación]]"
---
## bytesm o número de instrucciones?

> Pregunta: En los procesadores Intel y AMD al buscar información de cuántas instrucciones entran en la etapa de fetch sólo encuentro cantidad de bytes. A qué es debido?

Tanto Intel [[Intel_Core_Ultra_X937_8H]] como AMD [[AMD_Ryzen_9_9850HX]] fabrican principalmente procesadores que asumen el **ISA X86-64**
[https://es.wikipedia.org/wiki/X86-64](https://es.wikipedia.org/wiki/X86-64)  
  
Este ISA es de tipo **CISC** (Complex Instruction Set Computing).
[https://es.wikipedia.org/wiki/Complex_instruction_set_computing](https://es.wikipedia.org/wiki/Complex_instruction_set_computing)  

El otro tipo de ISA existente, es el conocido como RISC (Reduced Instruction Set Computing)
[https://es.wikipedia.org/wiki/Reduced_instruction_set_computing](https://es.wikipedia.org/wiki/Reduced_instruction_set_computing)  
Existen diferencias sustanciales entre ambos tipos de enfoques teniendo cada uno de ellos sus ventajas y desventajas
[https://techlandia.com/diferencia-cisc-risc-info_291061/](https://techlandia.com/diferencia-cisc-risc-info_291061/)  

En los años 80/90 las diferentes empresas fabricantes de procesadores tomaban uno u otro enfoque para sus diseños. Hoy en día parece claro que el mejor enfoque es asumir un ISA de tipo RISC ya que facilita la decodificación y ejecución de las instrucciones
[https://cs.stanford.edu/people/eroberts/courses/soco/projects/risc/risccisc/](https://cs.stanford.edu/people/eroberts/courses/soco/projects/risc/risccisc/)  

Una vez asumido, que un ISA RISC es mejor que un ISA CISC, las empresas que asumieron inicialmente un enfoque CISC se vieron en un dilema:
	(1) cambiar a RISC pero perder compatibilidad con los códigos ISA CISC utilizados hasta el momento o
	(2) mantener el ISA CISC pero sacrificando rendimiento de los procesadores. 


La solución para mantener compatibilidad y tener un buen rendimiento fue hacer una **traducción de CISC a RISC de manera interna**. Aquí tenéis por ejemplo, el esquema del front end del procesador Intel Nehalem

![[intel_nehalem_frontend.png|485]]


       ┌────────────────────────┐
       │  L1 Instruction Cache  │  (Almacena bytes CISC en bruto)
       └───────────┬────────────┘
                   │ 128 bits / ciclo (16 Bytes / ciclo)
                   ▼
       ┌────────────────────────┐
       │ Instruction Fetch Unit │  (Fetch: capta BYTES, no instrucciones fijas)
       └───────────┬────────────┘
                   │
                   ▼
       ┌────────────────────────┐
       │   Instruction Length   │  (Pre-decode: averigua dónde empieza y acaba
       │      Decoder (ILD)     │   cada instrucción de 1 a 15 bytes)
       └───────────┬────────────┘
                   │ Hasta 6 macro-instrucciones / ciclo
                   ▼
       ┌────────────────────────┐
       │    Instruction Queue   │  (IFQ: almacena macro-instrucciones CISC)
       └───────────┬────────────┘
                   │ Hasta 4 macro-instrucciones / ciclo
                   ▼
       ┌────────────────────────┐
       │  Instruction Decoders  │  (DECODE: traduce macro CISC -> micro RISC)
       │ (3 simples + 1 comple) │
       └───────────┬────────────┘
                   │ Hasta 4 micro-ops / ciclo
                   ▼
       ┌────────────────────────┐
       │ Instruction Decoder Q. │  (IDQ / Buffer de micro-ops)
       └────────────────────────┘

Retomando las diferencias entre un ISA CISC y un ISA RISC, una de ellas es que el tamaño de las instrucciones RISC es siempre el mismo mientras que **el tamaño de las instrucciones CISC es variable**. Un tamaño fijo facilita la decodificación y la ejecución de las instrucciones. 
  
En el caso del ISA X86-64 puede haber instrucciones de unos pocos bytes hasta un tamaño máximo de 15 bytes. 

[https://wiki.osdev.org/X86-64_Instruction_Encoding](https://wiki.osdev.org/X86-64_Instruction_Encoding)  

Por esta razón, la etapa de fetch de los procesadores de Intel y AMD no habla de instrucciones que se pueden captar de memoria en un ciclo, sino de bytes que se pueden captar en un ciclo (que representan un número variable de instrucciones). A posteriori se hace la traducción de instrucciones CISC a instrucciones RISC (una CISC a una RISC o una CISC a varias RISC) y ya a partir de ese momento si que se habla de número de instrucciones en las sucesivas etapas.

## camino tradicional vs microop cache

En x86 moderno coexisten dos vías para alimentar el núcleo:

               ┌────────────────────────┐
               │    Predictor / PC      │
               └───────────┬────────────┘
                           │
           ┌───────────────┴────────────────┐
           ▼                                ▼
    ┌─────────────────────┐          ┌──────────────────────┐
	│     Caché L1I       │          │   µ-OP CACHE (DSB)   │
	│ (Bytes x86 crudos)  ││ (µ-ops ya traducidas)│
	└──────────┬──────────┘          └──────────┬───────────┘
	           │ (Bus de Bytes:                 │ (Atajo rápido:
	           │  48B o 64B/ciclo)              │  8 a 12 µ-ops/ciclo)
	           ▼                                │
	┌─────────────────────┐                     │
	│    Decodificadores  │                     │
	│  (CISC -> µ-ops)    │           │
	└──────────┬──────────┘                     │
	           │                                │
	           └───────────────┬────────────────┘
	                           │ (Multiplexor de entrada)
	                           ▼
	             ┌───────────────────────────┐
	             │ Cola de µ-ops (µ-op Queue)│
	             └─────────────┬─────────────┘
	                           ▼
	             ┌───────────────────────────┐
	             │  Rename / Dispatch / ROB  │
	             └───────────────────────────┘

- **Camino tradicional (L1I $\rightarrow$ Decoders):**
    
    - Pasa por la lectura de bytes en bruto y la decodificación costosa
	    
    - Requiere lógica adicional (_Instruction Length Decoder_) para detectar dónde empieza y termina cada instrucción.
        
- **Camino rápido ($\mu$-op Cache / Decoded Stream Buffer):**
    
    - Almacena fragmentos de código repetitivo (bucles) que ya fueron previamente decodificados a $\mu$-ops[cite: 9].
        
    - **Ventajas:** Apaga temporalmente los decodificadores tradicionales (ahorro térmico y energético), reduce la latencia y elimina el cuello de botella del tamaño en bytes del x86 original, entregando directamente hasta 8–12 $\mu$-ops/ciclo

## Front-End Starvation (Inanición del Front-End)

### ¿Qué es?

Ocurre cuando el motor de ejecución (_Execution Core_) o las colas de despacho (_Dispatch_) se quedan vacíos de instrucciones válidas para procesar porque el Front-End se ha detenido o va demasiado lento. Las unidades de ejecución se quedan ociosas (_bubbles_), hundiendo el IPC

### Principales causas de Starvation:

1. **Fallos en la L1I / L2:**
    
    - Si el código no está en L1I, hay que buscarlo en L2 o memoria principal.
        
    - El caudal físico de Fetch cae en picado (en Lion Cove cae a ~16 B/ciclo al acudir a L2) y añade decenas de ciclos de espera
        
2. **Fallo de predicción de salto (_Branch Misprediction_):**
    
    - El procesador sigue una ruta especulativa equivocada; al detectarse el fallo en el Back-End, se descarta el trabajo y hay que limpiar (_flush_) la tubería y volver a buscar desde la dirección correcta
        
3. **Instrucciones excesivamente largas/complejas en x86:**
    
    - Si una ráfaga de código contiene muchas instrucciones cercanas a los 15 Bytes, el ancho de lectura en bytes (48B/64B) no da abasto para llenar los 8 huecos del decodificador en ese ciclo.
        

### Mecanismos de protección contra Starvation:

- **Colas de desacoplamiento (IFQ / IBQ):** Búfers intermedios entre Fetch y Decode que absorben los picos y valles del flujo
    
- **Predictores de salto agresivos (TAGE, BPU):** Para minimizar vaciados de pipeline.
    
- **Prefetching de instrucciones:** Trae líneas de caché a la L1I antes de que el PC las pida.


- **Principio del embudo y desacoplamiento:** Tanto Intel como AMD sobredimensionan deliberadamente el ancho de banda físico de Fetch (**48 B/ciclo** y **64 B/ciclo**, respectivamente) para que, incluso cuando el programa contenga instrucciones largas, el Fetch pueda suministrar en promedio $\ge 8$ instrucciones completas por ciclo.
    
- **El búfer desacoplador (IFQ / IBQ):** Esas instrucciones leídas en bruto se vierten en una cola intermedia (la _Instruction Queue_ en Intel, o la _IBQ_ de 20/40 entradas en Zen 5). Esta cola actúa como "presa de agua": acumula ráfagas de instrucciones para que los decodificadores nunca sufran falta de suministro (_starvation_).
    
- **El cuello de botella de Decode e Issue:** Aunque el Fetch extraiga el equivalente a 12 o 16 instrucciones/ciclo, la compuerta de **Decode solo puede traducir 8 instrucciones/ciclo** y la etapa de **Issue/Rename solo puede asignar 8 $\mu$-ops/ciclo** al motor fuera de orden. Por tanto, la tasa máxima sostenida del procesador queda limitada por el grado del procesador ($k = 8$).


Dado que [[simplescalar_mapeo_parametros]] modela una arquitectura puramente **RISC (PISA / Alpha):

- **No modela** longitud variable en bytes ni la $\mu$-op cache
    
- **Fetch Width efectivo:** Se calcula como `-decode:width` $\times$ `-fetch:speed` ($8 \times 1 = 8\text{ inst/ciclo}$).
    
- **Búfer desacoplador:** Se configura con `-fetch:ifqsize 16`, que representa la capacidad de la _Instruction Fetch Queue_ (IFQ) encargada de evitar la inanición del decodificador.