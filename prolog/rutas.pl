:- encoding(utf8).

ruta_valida(Origen, Destino, Dia, K, Ruta) :-
    Origen \== Destino,
    buscar(Origen, Destino, Dia, K, [Origen], ninguno, [], RutaInvertida),
    reverse(RutaInvertida, Ruta).

todas_las_rutas(Origen, Destino, Dia, K, Rutas) :-
    findall(Ruta, ruta_valida(Origen, Destino, Dia, K, Ruta), Rutas).

buscar(Destino, Destino, _, _, _, _, Acum, Acum) :-
    Acum = [_|_].

buscar(Actual, Destino, Dia, K, Visitados, LlegadaPrev, Acum, Ruta) :-
    Actual \== Destino,
    dentro_del_limite(K, Acum),
    vuelo(Actual, Siguiente, Salida, Llegada, Costo, Codigo, Dias),
    memberchk(Dia, Dias),
    \+ memberchk(Siguiente, Visitados),
    conexion_valida(LlegadaPrev, Salida),
    buscar(Siguiente, Destino, Dia, K,
           [Siguiente|Visitados], Llegada,
           [vuelo(Actual, Siguiente, Salida, Llegada, Costo, Codigo, Dias)|Acum],
           Ruta).

conexion_valida(ninguno, _) :- !.
conexion_valida(LlegadaPrev, Salida) :-
    tmc(TMC),
    Salida >= LlegadaPrev + TMC.

dentro_del_limite(sin_limite, _) :- !.
dentro_del_limite(K, Acum) :-
    integer(K),
    length(Acum, N),
    N =< K.

escalas(Ruta, N) :-
    length(Ruta, Vuelos),
    N is Vuelos - 1.
