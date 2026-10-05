
| BENCHMARK | LUCAS<br>AMD_out | RAQUEL | DIFERENCIA | VEREDICTO                  |
| --------- | ---------------- | ------ | ---------- | -------------------------- |
| BZIP2     | 3.4080           | 3.4080 | 0          |                            |
| AMMP      | 0.1911           | 0.1911 | 0          |                            |
| GAP       | 3.3523           | 3.3524 | 0.0001     | ($\Delta \approx 0.003\%$) |
| SWIM      | 5.7843           | 5.7843 | 0          |                            |
| VPR       | 1.9328           | 1.9328 | 0          |                            |
### Análisis detallado de las ejecuciones

1. La leve variación en GAP ($3.3523$ vs $3.3524$):
    
    - En el log de tu compañera se completaron $40\,303\,269$ instrucciones retiradas en $12\,022\,316$ ciclos:

$$\text{IPC} = \frac{40\,303\,269}{12\,022\,316} \approx 3.352372 \implies \mathbf{3.3524}$$

- En tu corrida previa se retiraron $40\,303\,291$ instrucciones en $12\,022\,462$ ciclos:

$$\text{IPC} = \frac{40\,303\,291}{12\,022\,462} \approx 3.352331 \implies \mathbf{3.3523}$$

- La discrepancia es de apenas 22 instrucciones en más de 40 millones, lo cual es normal en el intérprete de GAP al manejar señales de temporización POSIX en entornos virtuales distintos.

### Comparativa directa de parámetros compartidos

- **Fase y duración:**
    
    - Ambos usáis `-fastfwd 100000000 -max:inst 100000000` (100 millones de instrucciones omitidas y 100 millones evaluadas)..
        
- **k-vía del procesador (etapas):**
    
    - Ambos tenéis `-fetch:ifqsize 16 -decode:width 8 -issue:width 8 -commit:width 8`.
        
- **Ventana de instrucciones y memoria:**
    
    - Ambos tenéis `-ruu:size 512 -lsq:size 256`.
        
- **Cachés:**
    
    - L1 Instrucciones: `il1:64:64:8:l` (32 KB, 8 vías, bloque 64 B).
        
    - L1 Datos: `dl1:64:64:8:l` (32 KB efectivos adaptados a 8 vías por restricción de potencia de 2).
        
    - L2 Unificada: `ul2:1024:64:16:l` (1 MB, 16 vías, bloque 64 B).
        
- **Memoria DRAM y bus:**
    
    - Ambos tenéis `-mem:lat 149 1 -mem:width 16`.
        
- **Recursos funcionales:**
    
    - Ambos tenéis `-res:ialu 6 -res:imult 3 -res:fpalu 4 -res:fpmult 2 -res:memport 4`.


### Sobre la estructura del script

1. **¿Quieres que el script recorra los 5 benchmarks siempre, o que sea configurable** (por ejemplo, un array `BENCHMARKS=("bzip2" "ammp" "gap" "swim" "vpr")` fácil de comentar/descomentar)?
    me gustaría que se pudiese elegir que benchmarcks usar 
2. **¿Quieres que los parámetros estén en la parte de arriba como variables globales** (estilo `amd_default.sh`) o prefieres un array de argumentos `COMMON_ARGS=( ... )` para que sea más legible?
    pues me gustan los parametros como variables globales pero quieor que metas comentarios de que representan esas variables, que significan e incluso que significa/representa ese valor 
3. **¿Un solo benchmark por ejecución o los 5 de golpe?** Si quieres uno por ejecución, se puede añadir `./script.sh bzip2` o `./script.sh all`.
    como? no entiendo.

### Sobre el resumen y la salida

4. **¿Quieres el `_IPC.out` con solo la línea `sim_IPC`**, o prefieres un resumen más rico: IPC, CPI, miss rates L1I/L1D/L2, ocupación RUU, ocupación LSQ, etc.?
    prefiero un resumen mas rico que incluya lo maximo que pueda incluir de manera clara
5. **¿Quieres un CSV** además del `.out`, para pegarlo en Excel/gnuplot y hacer las gráficas que pide el enunciado?
    tambien me gustaria un cvs para ponerlo en excel y que salgan las graficas tal cual pide el enunciado
6. **¿Quieres que el script detecte automáticamente si swim/vpr han llegado a las 100 M de instrucciones** y avise en vez de dejar el IPC vacío?
    bueno, no estaria mal, aunque que continue el resto de benchmarks 

### Sobre el problema de fondo (swim y vpr)

7. **¿Quieres que el script se lance desde un directorio de trabajo propio** (por ejemplo `~/Documents/AC-P1/specwork/<bench>/`) para no depender de escribir en `/lib/specs2000`? Esto elimina el problema de `costs.out` de vpr de raíz.
   explicame que haria esto porque no lo entiendo
    
8. **¿Quieres que el script copie los inputs REF desde `/lib/specs2000/.../data/ref/` a tu carpeta de trabajo**, o los referencie por ruta absoluta?
    quiero que se pueda tener lo maximo en la carpeta del proyecto posible. a demas, me gustaria que si no hay errores o algun archivo creado no tiene contenido (Está vacio) que no se genere, como los .err o .out 
9. **¿El profesor exige que los binarios se ejecuten desde el directorio `data/ref` original**, o puedes ejecutarlos desde donde quieras pasando rutas absolutas? Esto es importante porque, si él exige el cwd original, no podemos usar la solución "limpia" y hay que recurrir a `sudo chown`. creo que da igual, no pide que se ejecuten desde ningun sitio en especifico, pero recuerdo que comento algo sobre que funcionaria mejor si estuviese todo en una misma carpeta
    

### Sobre el nivel de explicaciones

10. **¿Las explicaciones las quieres como comentarios `#` dentro del script**, o prefieres además un `echo` al usuario explicando qué hace cada fase cuando se ejecuta?
    pues ambas. principalmente quiero que haya explicacion extensa en forma de comentario, pero si quieres poner tambien mientras se ejecuta mejor, asi puedo saber por donde va 
11. **¿Quieres que el script haga eco de la configuración al inicio** (un dump de todos los parámetros con sus valores y su justificación) para que quede registrado en un log?
    no hace falta, o si? pra que serviria esto?

### Sobre tu entorno concreto

12. **¿Tienes `sudo` sin contraseña?** Porque si sí, la opción más simple para arreglar vpr es `sudo chown` de `/lib/specs2000/vpr/data/ref` a `milax`.
    yiene contraseña el sudo
13. **¿Tu compañera obtiene IPC en swim y vpr porque su `swim.in` es distinto**, o porque su usuario puede escribir en `/lib`? Si puedes mirar `ls -la` de su carpeta (o preguntarle por MD5 de sus inputs), me lo confirmas.
    pues a mi ya me funciona con el ultimo script que te pase, ya no tengo problema
14. **¿El enunciado permite usar `-fastfwd 0`** para swim y vpr, o exige estrictamente 100 M + 100 M para todos? Si exige 100+100 y swim no tiene suficientes instrucciones, es problema del input y hay que buscarlo REF.
    exige saltar 10M siempre

### Sobre el objetivo final

15. **¿Quieres que el script sirva además como plantilla** para las variantes "mejorado" del enunciado (por ejemplo, un `AMD_Zen5_mejorado.sh` que cambie solo `ruu` a 1024, o `lsq` a 512)? Es decir, ¿quieres que sea fácil parametrizar para las gráficas comparativas?
    SI POR FAVOR, ES UN MUST
    
16. **¿Quieres que el script genere automáticamente las gráficas** (con `gnuplot` o similar) a partir del CSV, o con el CSV te basta?
    VALE, 