:- encoding(utf8).
/*  rutas.pl - Motor de búsqueda de rutas válidas (Módulo 2)

    La búsqueda explota el backtracking nativo de Prolog: cada llamada a
    vuelo/7 con el origen instanciado deja puntos de elección por cada vuelo
    que sale de esa ciudad; si una restricción falla, el motor retrocede y
    prueba la siguiente arista. No hay un bucle explícito de exploración: la
    búsqueda en profundidad ES la estrategia de resolución de Prolog.

    Acumuladores:
    - Visitados    : ciudades ya recorridas (control de ciclos).
    - LlegadaPrev  : hora de llegada del vuelo anterior ('ninguno' al inicio).
    - Acum         : vuelos tomados, en orden inverso (se invierte al final).
*/

%!  ruta_valida(+Origen, +Destino, +Dia, +K, -Ruta) is nondet.
%
%   Ruta es una lista de hechos vuelo/7 que une Origen con Destino el día
%   Dia cumpliendo todas las restricciones. K es un entero (máximo de
%   escalas) o el átomo sin_limite. En backtracking enumera todas las rutas.
ruta_valida(Origen, Destino, Dia, K, Ruta) :-
    Origen \== Destino,
    buscar(Origen, Destino, Dia, K, [Origen], ninguno, [], RutaInvertida),
    reverse(RutaInvertida, Ruta).

%!  todas_las_rutas(+Origen, +Destino, +Dia, +K, -Rutas) is det.
%
%   Recopila con findall/3 todas las soluciones de ruta_valida/5.
todas_las_rutas(Origen, Destino, Dia, K, Rutas) :-
    findall(Ruta, ruta_valida(Origen, Destino, Dia, K, Ruta), Rutas).

%!  buscar(+Actual, +Destino, +Dia, +K, +Visitados, +LlegadaPrev, +Acum, -Ruta)
%
%   Caso base: la ciudad actual es el destino y se tomó al menos un vuelo.
buscar(Destino, Destino, _, _, _, _, Acum, Acum) :-
    Acum = [_|_].

%   Paso recursivo: tomar un vuelo que salga de Actual y cumpla las cuatro
%   restricciones; cada condición que falla provoca backtracking.
buscar(Actual, Destino, Dia, K, Visitados, LlegadaPrev, Acum, Ruta) :-
    Actual \== Destino,
    dentro_del_limite(K, Acum),                                 % (4) límite de escalas
    vuelo(Actual, Siguiente, Salida, Llegada, Costo, Codigo, Dias), % punto de elección
    memberchk(Dia, Dias),                                       % (1) frecuencia
    \+ memberchk(Siguiente, Visitados),                         % (3) control de ciclos
    conexion_valida(LlegadaPrev, Salida),                       % (2) escala >= TMC
    buscar(Siguiente, Destino, Dia, K,
           [Siguiente|Visitados], Llegada,
           [vuelo(Actual, Siguiente, Salida, Llegada, Costo, Codigo, Dias)|Acum],
           Ruta).

%!  conexion_valida(+LlegadaPrev, +Salida) is semidet.
%
%   El primer vuelo de la ruta no tiene vuelo anterior. Para los demás, la
%   salida debe ser mayor o igual a la llegada anterior más el TMC vigente.
conexion_valida(ninguno, _) :- !.
conexion_valida(LlegadaPrev, Salida) :-
    tmc(TMC),
    Salida >= LlegadaPrev + TMC.

%!  dentro_del_limite(+K, +Acum) is semidet.
%
%   Al tomar un vuelo más, la ruta tendrá N escalas, donde N es la cantidad
%   de vuelos ya acumulados; debe cumplirse N =< K.
dentro_del_limite(sin_limite, _) :- !.
dentro_del_limite(K, Acum) :-
    integer(K),
    length(Acum, N),
    N =< K.

%!  escalas(+Ruta, -N) is det.
escalas(Ruta, N) :-
    length(Ruta, Vuelos),
    N is Vuelos - 1.
