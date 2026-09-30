---
asignatura: "[[AC]]"
pdf: ""
fecha: 2026-09-26
---
Para simulación monohilo con benchmarks se toma la frecuencia de trabajo Turbo
porque al simular benchmarks de SPEC CPU2000 los núcleos monohilo trabajan siempre a máxima frecuencia

 DDR5-5600 means DDR5 memory modules rated for 5600 MT/s operation


**Memory_Clock (reloj real de la memoria):**
- Al ser DDR (_Double Data Rate_), el reloj físico del bus es la mitad de la tasa de transferencia:


La **latencia CAS** (o **CL**, por sus siglas en inglés _Column Address Strobe_) es el número de **ciclos de reloj** que transcurren desde que el controlador de memoria envía una solicitud de lectura hasta que los datos solicitados están disponibles en el bus de salida.

 **CAS:** clock cycles between issuing a column address and receiving data.

El **tRCD** (RAS to CAS Delay o Retraso de Dirección de Fila a Dirección de Columna) es un parámetro de latencia que indica el número de ciclos de reloj necesarios para abrir una fila de memoria y acceder a la columna requerida dentro de esa misma fila.

- **Función:** Mide el tiempo que transcurre entre la activación de la señal RAS (dirección de fila) y la validación de la señal CAS (dirección de columna) para leer o escribir datos.