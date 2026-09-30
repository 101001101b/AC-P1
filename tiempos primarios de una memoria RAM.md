---
asignatura: "[[AC]]"
pdf: "[[AC_p1_investigación]]"
fecha: 2026-09-26
---
Los **tiempos primarios** de una memoria RAM son cuatro valores que indican la latencia de respuesta del módulo y tienen el mayor impacto en el rendimiento real, expresándose típicamente en el formato **tCL-tRCD-tRP-tRAS**.

- **tCL (Latencia CAS):** Número de ciclos de reloj que tarda la memoria en entregar datos tras recibir una solicitud de lectura a una columna ya abierta.
    
- **tRCD (Retraso RAS a CAS):** Tiempo necesario para activar una fila y acceder a las columnas de su interior; es el retraso entre abrir una fila y leer una columna.
    
- **tRP (Tiempo de Precarga de Fila):** Ciclos necesarios para cerrar una fila activa antes de poder abrir otra nueva.
    
- **tRAS (Tiempo de Fila Activa):** Duración mínima que una fila debe permanecer activa para garantizar el acceso correcto a los datos antes de ser cerrada.
    

Estos parámetros se miden en **ciclos de reloj**, y aunque valores numéricos más bajos suelen sugerir mayor velocidad, la latencia real en nanosegundos también depende de la frecuencia (MT/s) del módulo de memoria.