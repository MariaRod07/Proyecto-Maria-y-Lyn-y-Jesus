:- encoding(utf8).

:- dynamic vuelo/7.
:- dynamic tmc/1.
:- dynamic archivo_cargado/1.

tmc(45).

configurar_tmc(Minutos) :-
    integer(Minutos), Minutos >= 0,
    retractall(tmc(_)),
    assertz(tmc(Minutos)).

cargar_vuelos(Archivo) :-
    exists_file(Archivo),
    retractall(vuelo(_, _, _, _, _, _, _)),
    read_file_to_string(Archivo, Contenido, [encoding(utf8)]),
    split_string(Contenido, "\n", "\r", Lineas),
    cargar_lineas(Lineas, 1, 0, Total),
    retractall(archivo_cargado(_)),
    assertz(archivo_cargado(Archivo)),
    format("Cargados ~w vuelos desde ~w~n", [Total, Archivo]).

cargar_lineas([], _, Total, Total).
cargar_lineas([Linea|Resto], NumLinea, Acum, Total) :-
    (   linea_en_blanco(Linea)
    ->  Acum1 = Acum
    ;   parsear_linea(Linea, Hecho)
    ->  assertz(Hecho),
        Acum1 is Acum + 1
    ;   format("  Advertencia: línea ~w ignorada (formato inválido): ~s~n",
               [NumLinea, Linea]),
        Acum1 = Acum
    ),
    NumLinea1 is NumLinea + 1,
    cargar_lineas(Resto, NumLinea1, Acum1, Total).

linea_en_blanco(Linea) :-
    split_string(Linea, "", " \t", [""]).

parsear_linea(Linea, vuelo(Origen, Destino, Salida, Llegada, Costo, Codigo, Dias)) :-
    split_string(Linea, "|", " \t", [OrigenS, DestinoS, SalidaS, LlegadaS, CostoS, CodigoS, FrecS]),
    atom_string(Origen, OrigenS),
    atom_string(Destino, DestinoS),
    hora_a_minutos(SalidaS, Salida),
    hora_a_minutos(LlegadaS, Llegada),
    number_string(Costo, CostoS),
    integer(Costo),
    atom_string(Codigo, CodigoS),
    parsear_frecuencia(FrecS, Dias).

parsear_frecuencia(Texto, Dias) :-
    atom_string(Atomo, Texto),
    (   Atomo == 'Diario'
    ->  todos_los_dias(Dias)
    ;   split_string(Texto, "-", " ", Tokens),
        maplist(token_dia, Tokens, Dias)
    ).

todos_los_dias([lunes, martes, miercoles, jueves, viernes, sabado, domingo]).

token_dia(Token, Dia) :-
    atom_string(Abrev, Token),
    abreviatura(Abrev, Dia).

abreviatura('L',  lunes).
abreviatura('M',  martes).
abreviatura('Mi', miercoles).
abreviatura('J',  jueves).
abreviatura('V',  viernes).
abreviatura('S',  sabado).
abreviatura('D',  domingo).
