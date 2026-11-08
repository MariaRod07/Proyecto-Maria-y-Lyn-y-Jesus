:- encoding(utf8).

% Todos los vuelos que salen de Ciudad, ordenados por hora de salida.
salidas_desde(Ciudad, Vuelos) :-
    findall(S-vuelo(Ciudad, D, S, L, C, V, F),
            vuelo(Ciudad, D, S, L, C, V, F),
            Pares),
    keysort(Pares, Ordenados),
    pares_a_valores(Ordenados, Vuelos).

% Todos los vuelos que llegan a Ciudad, ordenados por hora de llegada.
llegadas_a(Ciudad, Vuelos) :-
    (   setof(L-vuelo(O, Ciudad, S, L, C, V, F),
              vuelo(O, Ciudad, S, L, C, V, F),
              Pares)
    ->  pares_a_valores(Pares, Vuelos)
    ;   Vuelos = []
    ).

% Vuelos que operan en un dia dado.
vuelos_del_dia(Dia, Vuelos) :-
    (   bagof(vuelo(O, D, S, L, C, V, Dias),
              ( vuelo(O, D, S, L, C, V, Dias), memberchk(Dia, Dias) ),
              Vuelos)
    ->  true
    ;   Vuelos = []
    ).

% Todas las ciudades (origenes y destinos) sin repetidos.
ciudades(Ciudades) :-
    (   setof(C,
              D^S^L^Co^V^F^( vuelo(C, D, S, L, Co, V, F)
                           ; vuelo(D, C, S, L, Co, V, F) ),
              Ciudades)
    ->  true
    ;   Ciudades = []
    ).

% Localiza una ciudad ignorando mayusculas/minusculas.
buscar_ciudad(Texto, Ciudad) :-
    downcase_atom(Texto, Buscado),
    ciudades(Ciudades),
    member(Ciudad, Ciudades),
    downcase_atom(Ciudad, Buscado),
    !.

% [K1-V1, K2-V2, ...] -> [V1, V2, ...].
pares_a_valores([], []).
pares_a_valores([_-V|Pares], [V|Valores]) :-
    pares_a_valores(Pares, Valores).
