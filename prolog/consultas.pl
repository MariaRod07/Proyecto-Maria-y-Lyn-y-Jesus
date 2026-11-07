:- encoding(utf8).
/*  consultas.pl - Consultas básicas de partidas y llegadas (Módulo 1)

    Cada predicado ilustra un meta-predicado de recopilación distinto:
    findall/3 (todas las soluciones, sin ordenar, [] si no hay ninguna),
    setof/3 (ordenado y sin duplicados; falla si no hay soluciones) y
    bagof/3 (como setof pero sin ordenar ni eliminar duplicados).
*/

%!  salidas_desde(+Ciudad:atom, -Vuelos:list) is det.
%
%   Todos los vuelos que salen de Ciudad, ordenados por hora de salida.
%   findall/3 ejecuta la consulta por backtracking y recopila cada solución
%   en una lista de pares Salida-Vuelo; keysort/2 (ordenamiento estable por
%   clave) los ordena y pares_a_valores/2 descarta las claves.
salidas_desde(Ciudad, Vuelos) :-
    findall(S-vuelo(Ciudad, D, S, L, C, V, F),
            vuelo(Ciudad, D, S, L, C, V, F),
            Pares),
    keysort(Pares, Ordenados),
    pares_a_valores(Ordenados, Vuelos).

%!  llegadas_a(+Ciudad:atom, -Vuelos:list) is det.
%
%   Todos los vuelos que llegan a Ciudad, ordenados por hora de llegada.
%   setof/3 ordena por el orden estándar de términos: al usar como plantilla
%   el par Llegada-Vuelo, la lista queda ordenada por hora de llegada. Como
%   setof/3 falla cuando no hay soluciones, el ->/; devuelve [].
llegadas_a(Ciudad, Vuelos) :-
    (   setof(L-vuelo(O, Ciudad, S, L, C, V, F),
              vuelo(O, Ciudad, S, L, C, V, F),
              Pares)
    ->  pares_a_valores(Pares, Vuelos)
    ;   Vuelos = []
    ).

%!  vuelos_del_dia(+Dia:atom, -Vuelos:list) is det.
%
%   Vuelos que operan en un día dado. bagof/3 recopila las soluciones de una
%   conjunción (hecho + comprobación de pertenencia con memberchk/2).
vuelos_del_dia(Dia, Vuelos) :-
    (   bagof(vuelo(O, D, S, L, C, V, Dias),
              ( vuelo(O, D, S, L, C, V, Dias), memberchk(Dia, Dias) ),
              Vuelos)
    ->  true
    ;   Vuelos = []
    ).

%!  ciudades(-Ciudades:list) is det.
%
%   Todas las ciudades (orígenes y destinos) sin repetidos y en orden
%   alfabético. El operador ^ declara como existenciales las variables del
%   objetivo que no forman parte de la plantilla; sin él, setof/3 generaría
%   una lista distinta por cada combinación de esas variables.
ciudades(Ciudades) :-
    (   setof(C,
              D^S^L^Co^V^F^( vuelo(C, D, S, L, Co, V, F)
                           ; vuelo(D, C, S, L, Co, V, F) ),
              Ciudades)
    ->  true
    ;   Ciudades = []
    ).

%!  buscar_ciudad(+Texto:atom, -Ciudad:atom) is semidet.
%
%   Localiza una ciudad ignorando mayúsculas/minúsculas, para que el usuario
%   pueda escribir "pto ordaz" en el menú.
buscar_ciudad(Texto, Ciudad) :-
    downcase_atom(Texto, Buscado),
    ciudades(Ciudades),
    member(Ciudad, Ciudades),
    downcase_atom(Ciudad, Buscado),
    !.

%!  pares_a_valores(+Pares:list, -Valores:list) is det.
%
%   [K1-V1, K2-V2, ...] -> [V1, V2, ...]. Recursión estructural sobre la
%   lista con el patrón [Cabeza|Cola].
pares_a_valores([], []).
pares_a_valores([_-V|Pares], [V|Valores]) :-
    pares_a_valores(Pares, Valores).
