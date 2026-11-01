# LogiExpress — Motor analítico de vuelos e itinerarios

Asignatura: Tópicos Especiales de Programación (UCAB)
Profesoras: Jannelly Bello / Noraimar Mora

Motor de rutas aéreas entre ciudades implementado bajo dos paradigmas
declarativos: **lógico (SWI-Prolog)** y **funcional (Haskell)**. Ambas
soluciones leen la misma base de datos `vuelos.txt`, exponen el mismo menú
interactivo en consola y resuelven los tres módulos del enunciado:

| Módulo | Funcionalidad | Haskell | Prolog |
|---|---|---|---|
| 1 | Carga dinámica y parseo de `vuelos.txt` | `Parser.hs`, `Grafo.hs` | `carga.pl` |
| 1 | Conversión HH:MM ↔ minutos | `Tiempo.hs` | `tiempo.pl` |
| 1 | TMC configurable, salidas/llegadas por ciudad | `Consultas.hs` | `consultas.pl` |
| 2 | Rutas válidas (frecuencia, TMC, ciclos, límite K) | `Rutas.hs` | `rutas.pl` |
| 3 | Ruta más barata, más rápida y reportes ordenados | `Optimizacion.hs` | `optimizacion.pl` |
| — | Menú interactivo (CLI) | `Main.hs` | `main.pl` |

## Estructura del repositorio

```
LogiExpress-GrupoXX/
├── README.md
├── vuelos.txt              # base de datos de prueba (20 vuelos, 8 ciudades)
├── .gitignore
├── haskell/
│   ├── Main.hs             # CLI e I/O (único módulo impuro)
│   ├── Tipos.hs            # data Vuelo, data Dia, type Ruta, type Grafo
│   ├── Tiempo.hs           # horaAMinutos / minutosAHora
│   ├── Parser.hs           # parseo puro del archivo
│   ├── Grafo.hs            # lista de adyacencia inmutable
│   ├── Consultas.hs        # Módulo 1
│   ├── Rutas.hs            # Módulo 2 (DFS con list comprehensions)
│   ├── Optimizacion.hs     # Módulo 3 (quicksort, mergesort, folds)
│   └── logiexpress.cabal
├── prolog/
│   ├── main.pl             # CLI: iniciar/0 (alias menu/0)
│   ├── tiempo.pl           # hora_a_minutos/2, minutos_a_hora/2
│   ├── carga.pl            # assertz de vuelo/7, tmc/1
│   ├── consultas.pl        # Módulo 1 (findall/setof/bagof)
│   ├── rutas.pl            # Módulo 2 (backtracking + acumuladores)
│   └── optimizacion.pl     # Módulo 3 (quicksort, mergesort sobre listas)
└── docs/
    ├── esquema_informe.md  # guion del Informe Técnico Comparativo
    └── (Informe_Tecnico_Comparativo.pdf — se carga en la entrega final)
```

## Formato de `vuelos.txt`

Un vuelo por línea, campos separados por `|`, horas en formato militar de 24 h:

```
Origen|Destino|HoraSalida|HoraLlegada|Costo|Vuelo|Frecuencia
Pto Ordaz|Maiquetia|07:00|08:00|5600|Vlo#1|Diario
Maiquetia|Porlamar|09:00|10:00|4800|Vlo#2|L-M-Mi-J-V
```

Frecuencia: `Diario` o abreviaturas separadas por `-` (`L` lunes, `M` martes,
`Mi` miércoles, `J` jueves, `V` viernes, `S` sábado, `D` domingo).

Ambos programas buscan el archivo primero en la carpeta actual y luego en la
carpeta superior (`../vuelos.txt`), de modo que pueden ejecutarse desde
`/haskell` o `/prolog` sin copiar el archivo. También puede cargarse cualquier
otra ruta desde la opción 1 del menú.

## Solución Haskell

Requisitos: GHC ≥ 9.0 (probado con 9.4.7). Solo usa paquetes que vienen con GHC
(`base`, `directory`).

```bash
cd haskell

# Opción A: compilar y ejecutar
ghc -O1 -o logiexpress Main.hs
./logiexpress            # Windows: logiexpress.exe

# Opción B: interpretado
runghc Main.hs

# Opción C: desde GHCi
ghci Main.hs
ghci> main

# Opción D: con cabal
cabal run logiexpress
```

Los archivos `.o` y `.hi` que genera `ghc` están excluidos por `.gitignore`.

## Solución Prolog

Requisitos: SWI-Prolog ≥ 8.x (probado con 9.0.4).

```bash
cd prolog

# Opción A: arranca el menú y termina al salir
swipl -q -g iniciar -t halt main.pl

# Opción B: consultar y lanzar el predicado principal
swipl main.pl
?- iniciar.          % o  ?- menu.
```

Predicados principales disponibles también desde el toplevel:

```prolog
?- cargar_vuelos('../vuelos.txt').
?- configurar_tmc(60).
?- salidas_desde('Pto Ordaz', Vs).
?- llegadas_a('Maiquetia', Vs).
?- ruta_valida('Pto Ordaz', 'Porlamar', lunes, sin_limite, R).   % enumera por backtracking
?- todas_las_rutas('Pto Ordaz', 'Porlamar', lunes, 1, Rs).
?- ruta_mas_barata('Pto Ordaz', 'Porlamar', sabado, sin_limite, Costo, R).
?- ruta_mas_rapida('Pto Ordaz', 'Porlamar', sabado, sin_limite, Tiempo, R).
?- rutas_por_costo('Maiquetia', 'Maracaibo', lunes, sin_limite, Pares).
```

## Menú interactivo (idéntico en ambos lenguajes)

```
1. Cargar archivo de vuelos
2. Configurar TMC (tiempo mínimo de conexión)        [por defecto 45 min]
3. Vuelos que salen de una ciudad
4. Vuelos que llegan a una ciudad
5. Vuelos que operan un día de la semana
6. Buscar rutas válidas (origen, destino, día, K opcional)
7. Ruta de costo mínimo y ruta de menor tiempo
8. Reporte de rutas ordenadas por costo o por tiempo
9. Listar ciudades
0. Salir
```

Las ciudades se aceptan sin distinguir mayúsculas (`pto ordaz`); los días
admiten nombre completo con o sin acento (`Miércoles`, `miercoles`) o la
abreviatura del archivo (`Mi`). Dejar K vacío significa sin límite de escalas.

## Casos de verificación

Resultados obtenidos con ambas implementaciones (TMC = 45 min), útiles para
las capturas del informe:

| Consulta | Resultado |
|---|---|
| Pto Ordaz → Porlamar, lunes | 3 rutas: Vlo#1+Vlo#2 (Bs 10400, 180 min), Vlo#1+Vlo#14+Vlo#15 (Bs 13200, 400 min), Vlo#6+Vlo#9 (Bs 11000, 420 min) |
| Pto Ordaz → Porlamar, lunes, K = 0 | 0 rutas (no hay vuelo directo) |
| Pto Ordaz → Porlamar, lunes, K = 1 | 2 rutas (se descarta la de 2 escalas) |
| Pto Ordaz → Porlamar, sábado | más barata Vlo#6+Vlo#9 (Bs 11000); más rápida Vlo#1+Vlo#14+Vlo#15 (400 min) |
| Pto Ordaz → Porlamar, lunes, TMC = 120 | 1 ruta: Vlo#6+Vlo#9 (las esperas de 60 y 70 min ya no cumplen el TMC) |
| Maiquetia → Maracaibo, lunes | 2 rutas: Vlo#10+Vlo#11 (Bs 8100, 180 min) y Vlo#17+Vlo#18 (Bs 14600, 225 min) |

## Notas sobre codificación de caracteres

Los mensajes de consola llevan acentos. En Linux/macOS ambos programas fuerzan
UTF-8; en Windows respetan la página de códigos de la consola. Si en Windows se
ven caracteres extraños, ejecutar antes `chcp 65001`.

## Estado del proyecto

- [x] Módulo 1: carga dinámica, TMC, consultas básicas (Haskell y Prolog)
- [x] Módulo 2: búsqueda de rutas con las cuatro restricciones (Haskell y Prolog)
- [x] Módulo 3: optimización por costo y tiempo, reportes ordenados (Haskell y Prolog)
- [x] Menú interactivo en ambos lenguajes
- [ ] Informe Técnico Comparativo en `/docs` (entrega final: 08/11/2026, tag `v1.0-final`)
