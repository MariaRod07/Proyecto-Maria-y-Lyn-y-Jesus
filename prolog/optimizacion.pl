:- encoding(utf8).

costo_ruta(Ruta, Costo) :-
    costo_ruta(Ruta, 0, Costo).

costo_ruta([], Acum, Acum).
costo_ruta([vuelo(_, _, _, _, C, _, _)|Resto], Acum, Costo) :-
    Acum1 is Acum + C,
    costo_ruta(Resto, Acum1, Costo).

tiempo_ruta(Ruta, Minutos) :-
    Ruta = [vuelo(_, _, Salida, _, _, _, _)|_],
    last(Ruta, vuelo(_, _, _, Llegada, _, _, _)),
    Minutos is Llegada - Salida.

esperas([], []).
esperas([_], []).
esperas([vuelo(_, _, _, Llegada1, _, _, _), V2|Resto], [Espera|Esperas]) :-
    V2 = vuelo(_, _, Salida2, _, _, _, _),
    Espera is Salida2 - Llegada1,
    esperas([V2|Resto], Esperas).

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

ordenar_por_costo(Rutas, Ordenados) :-
    findall(c(Costo, Tiempo)-Ruta,
            ( member(Ruta, Rutas), costo_ruta(Ruta, Costo), tiempo_ruta(Ruta, Tiempo) ),
            Pares),
    quicksort(Pares, Ordenados).

ordenar_por_tiempo(Rutas, Ordenados) :-
    findall(t(Tiempo, Costo)-Ruta,
            ( member(Ruta, Rutas), tiempo_ruta(Ruta, Tiempo), costo_ruta(Ruta, Costo) ),
            Pares),
    mergesort(Pares, Ordenados).

mas_barata(Rutas, Costo, Ruta) :-
    ordenar_por_costo(Rutas, [c(Costo, _)-Ruta|_]).

mas_rapida(Rutas, Tiempo, Ruta) :-
    ordenar_por_tiempo(Rutas, [t(Tiempo, _)-Ruta|_]).

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

ruta_mas_barata_setof(Origen, Destino, Dia, K, Costo, Ruta) :-
    setof(C-R,
          ( ruta_valida(Origen, Destino, Dia, K, R), costo_ruta(R, C) ),
          [Costo-Ruta|_]).
