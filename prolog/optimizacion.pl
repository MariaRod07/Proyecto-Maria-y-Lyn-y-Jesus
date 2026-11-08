:- encoding(utf8).
/*  optimizacion.pl - Optimización por doble criterio y ordenamiento (Módulo 3)

    Métricas de una ruta (costo total, tiempo total, esperas), dos
    algoritmos de ordenamiento sobre listas de pares Clave-Ruta (quicksort y
    mergesort) y la selección de la ruta de costo mínimo y de menor tiempo.

    Los pares Clave-Ruta se comparan con el orden estándar de términos
    (@</2, @=</2), lo que permite usar como clave un número o un término
    compuesto como c(Costo, Tiempo) para desempatar.
*/

% ---------------------------------------------------------------------------
% Métricas
% ---------------------------------------------------------------------------

%!  costo_ruta(+Ruta, -Costo) is det.
%
%   Sumatoria de los boletos con recursión sobre [Cabeza|Cola] y acumulador.
costo_ruta(Ruta, Costo) :-
    costo_ruta(Ruta, 0, Costo).

costo_ruta([], Acum, Acum).
costo_ruta([vuelo(_, _, _, _, C, _, _)|Resto], Acum, Costo) :-
    Acum1 is Acum + C,
    costo_ruta(Resto, Acum1, Costo).

%!  tiempo_ruta(+Ruta, -Minutos) is det.
%
%   Diferencia entre la llegada del último vuelo y la salida del primero.
%   Al medirse entre extremos incluye las esperas en cada escala.
tiempo_ruta(Ruta, Minutos) :-
    Ruta = [vuelo(_, _, Salida, _, _, _, _)|_],
    last(Ruta, vuelo(_, _, _, Llegada, _, _, _)),
    Minutos is Llegada - Salida.

%!  esperas(+Ruta, -Esperas) is det.
%
%   Tiempo de espera en cada escala. El patrón [V1, V2|Resto] examina dos
%   vuelos consecutivos a la vez.
esperas([], []).
esperas([_], []).
esperas([vuelo(_, _, _, Llegada1, _, _, _), V2|Resto], [Espera|Esperas]) :-
    V2 = vuelo(_, _, Salida2, _, _, _, _),
    Espera is Salida2 - Llegada1,
    esperas([V2|Resto], Esperas).

% ---------------------------------------------------------------------------
% Ordenamiento implementado sobre listas (pares Clave-Valor)
% ---------------------------------------------------------------------------

%!  quicksort(+Pares, -Ordenados) is det.
%
%   Elige la cabeza como pivote, particiona el resto en menores y mayores
%   (o iguales), ordena ambas particiones recursivamente y concatena.
quicksort([], []).
quicksort([Pivote|Resto], Ordenados) :-
    particion(Pivote, Resto, Menores, Mayores),
    quicksort(Menores, MenoresOrd),
    quicksort(Mayores, MayoresOrd),
    append(MenoresOrd, [Pivote|MayoresOrd], Ordenados).

particion(_, [], [], []).
particion(P-V, [K-X|Resto], [K-X|Menores], Mayores) :-
    K @< P, !,
    particion(P-V, Resto, Menores, Mayores).
particion(Pivote, [Par|Resto], Menores, [Par|Mayores]) :-
    particion(Pivote, Resto, Menores, Mayores).

%!  mergesort(+Pares, -Ordenados) is det.
%
%   Divide la lista en dos mitades (alternando elementos), ordena cada mitad
%   y fusiona. Es estable: ante claves iguales conserva el orden original.
mergesort([], []) :- !.
mergesort([X], [X]) :- !.
mergesort(Pares, Ordenados) :-
    partir_mitades(Pares, Izquierda, Derecha),
    mergesort(Izquierda, IzquierdaOrd),
    mergesort(Derecha, DerechaOrd),
    fusionar(IzquierdaOrd, DerechaOrd, Ordenados).

partir_mitades([], [], []).
partir_mitades([X], [X], []).
partir_mitades([X, Y|Resto], [X|Izquierda], [Y|Derecha]) :-
    partir_mitades(Resto, Izquierda, Derecha).

fusionar([], Ys, Ys) :- !.
fusionar(Xs, [], Xs) :- !.
fusionar([K1-X|Xs], [K2-Y|Ys], [K1-X|Resto]) :-
    K1 @=< K2, !,
    fusionar(Xs, [K2-Y|Ys], Resto).
fusionar(Xs, [K2-Y|Ys], [K2-Y|Resto]) :-
    fusionar(Xs, Ys, Resto).

% ---------------------------------------------------------------------------
% Reportes ordenados y óptimos
% ---------------------------------------------------------------------------

%!  ordenar_por_costo(+Rutas, -Pares) is det.
%
%   Lista de pares c(Costo, Tiempo)-Ruta ordenada por costo con quicksort/2.
%   La clave compuesta desempata por tiempo gracias al orden estándar de
%   términos (c(5600, 60) @< c(5600, 90)).
ordenar_por_costo(Rutas, Ordenados) :-
    findall(c(Costo, Tiempo)-Ruta,
            ( member(Ruta, Rutas), costo_ruta(Ruta, Costo), tiempo_ruta(Ruta, Tiempo) ),
            Pares),
    quicksort(Pares, Ordenados).

%!  ordenar_por_tiempo(+Rutas, -Pares) is det.
%
%   Lista de pares t(Tiempo, Costo)-Ruta ordenada por tiempo con mergesort/2.
ordenar_por_tiempo(Rutas, Ordenados) :-
    findall(t(Tiempo, Costo)-Ruta,
            ( member(Ruta, Rutas), tiempo_ruta(Ruta, Tiempo), costo_ruta(Ruta, Costo) ),
            Pares),
    mergesort(Pares, Ordenados).

%!  mas_barata(+Rutas, -Costo, -Ruta) is semidet.
%!  mas_rapida(+Rutas, -Tiempo, -Ruta) is semidet.
%
%   El óptimo es la cabeza de la lista ordenada. Fallan si Rutas es [].
mas_barata(Rutas, Costo, Ruta) :-
    ordenar_por_costo(Rutas, [c(Costo, _)-Ruta|_]).

mas_rapida(Rutas, Tiempo, Ruta) :-
    ordenar_por_tiempo(Rutas, [t(Tiempo, _)-Ruta|_]).

%!  rutas_por_costo(+Origen, +Destino, +Dia, +K, -Pares) is det.
%!  rutas_por_tiempo(+Origen, +Destino, +Dia, +K, -Pares) is det.
%!  ruta_mas_barata(+Origen, +Destino, +Dia, +K, -Costo, -Ruta) is semidet.
%!  ruta_mas_rapida(+Origen, +Destino, +Dia, +K, -Tiempo, -Ruta) is semidet.
%
%   Versiones de conveniencia para el toplevel: ejecutan la búsqueda del
%   Módulo 2 y aplican el ordenamiento u optimización sobre el resultado.
rutas_por_costo(Origen, Destino, Dia, K, Ordenados) :-
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    ordenar_por_costo(Rutas, Ordenados).

rutas_por_tiempo(Origen, Destino, Dia, K, Ordenados) :-
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    ordenar_por_tiempo(Rutas, Ordenados).

ruta_mas_barata(Origen, Destino, Dia, K, Costo, Ruta) :-
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    mas_barata(Rutas, Costo, Ruta).

ruta_mas_rapida(Origen, Destino, Dia, K, Tiempo, Ruta) :-
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    mas_rapida(Rutas, Tiempo, Ruta).

%!  ruta_mas_barata_setof(+Origen, +Destino, +Dia, +K, -Costo, -Ruta) is semidet.
%
%   Alternativa declarativa: setof/3 ya devuelve las soluciones ordenadas por
%   el orden estándar de la plantilla Costo-Ruta, así que el mínimo es la
%   cabeza. Se incluye para contrastar con la versión de ordenamiento propio.
ruta_mas_barata_setof(Origen, Destino, Dia, K, Costo, Ruta) :-
    setof(C-R,
          ( ruta_valida(Origen, Destino, Dia, K, R), costo_ruta(R, C) ),
          [Costo-Ruta|_]).
