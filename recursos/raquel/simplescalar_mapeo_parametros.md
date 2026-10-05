---
asignatura: "[[AC]]"
pdf: "[[Guia_Simple_Spec_P1.pdf]]"
fecha: 2026-09-26
---
bus memoria principal -> en Bytes

## AMD zen5
---
para el [[AMD_Ryzen_9_9850HX]]:
- LD1: 48KB, 12-way --> per a que siguin potencies de 2

**8 o 16 vies?? -> `8`**

**Latència i complexitat:** Una memòria L1D a freq. superiors a 5 GHz casi mai es dissenya amb 16 vies a causa de la sobrecàrrega elèctrica i el retard dels comparadors d'etiquetes (_tag comparators_).

La L2 de Zen5 sí que té 16 vies perquè disposa de 14 cicles de latència per respondre, mentre que la L1D ha de respondre en només 4 cicles.

Configurar 16 vies a la L1D sobrecarregaria artificialment el disseny d'associativitat

El maquinari real té:

$$\text{Zen 5 real}: 64 \text{ conjunts}, 12 \text{ vies} \implies 48 \text{ KB}$$

| Configuració     | nsets         | Vies        | Capacitat total | Comportament respecte al xip real                                                                                                                                                                                                                         |
| :--------------- | :------------ | :---------- | :-------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dl1:64:64:8:l`  | 64 (\(2^6\))  | 8 (\(2^3\)) | 32 KB           | **La més fidel en estructura:** conserva exactament els 64 conjunts d'indexació del maquinari de Zen 5 i l'associativitat clàssica de la família Zen. La taxa de fallades (*miss rate*) serà només lleugerament superior a la real per tenir 16 KB menys. |
| `dl1:128:64:8:l` | 128 (\(2^7\)) | 8 (\(2^3\)) | 64 KB           | **Més fidel si vols evitar penalitzar el volum de dades:** 64 KB dista només +16 KB dels 48 KB reals (el mateix error absolut que 32 KB), però duplica el nombre de conjunts indexables (128 en lloc de 64).                                              |

