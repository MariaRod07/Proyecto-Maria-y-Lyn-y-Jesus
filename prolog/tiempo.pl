:- encoding(utf8).
/*  tiempo.pl - Procesamiento de tiempo (Módulo 1)

    Conversión entre el formato militar "HH:MM" del archivo y minutos enteros
    desde el inicio del día. Toda la aritmética de ventanas de conexión (TMC)
    y de tiempo total de viaje se realiza sobre enteros con is/2, nunca sobre
    cadenas.
*/

%!  hora_a_minutos(+Hora:string, -Minutos:integer) is semidet.
%
%   "07:30" -> 450. Falla (sin excepción) si la cadena no tiene el formato
%   HH:MM o la hora está fuera de rango; así la carga del archivo puede
%   rechazar líneas inválidas con un simple ->/; .
hora_a_minutos(Hora, Minutos) :-
    split_string(Hora, ":", " ", [HoraStr, MinStr]),
    number_string(H, HoraStr),
    number_string(M, MinStr),
    integer(H), integer(M),
    H >= 0, H < 24,
    M >= 0, M < 60,
    Minutos is H * 60 + M.

%!  minutos_a_hora(+Minutos:integer, -Hora:atom) is det.
%
%   Operación inversa: 450 -> '07:30', con relleno de ceros.
minutos_a_hora(Minutos, Hora) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    dos_digitos(H, HS),
    dos_digitos(M, MS),
    atomic_list_concat([HS, ':', MS], Hora).

%!  formato_duracion(+Minutos:integer, -Texto:atom) is det.
%
%   180 -> '180 min (3h 00min)'.
formato_duracion(Minutos, Texto) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    dos_digitos(M, MS),
    format(atom(Texto), '~d min (~dh ~wmin)', [Minutos, H, MS]).

dos_digitos(N, Atomo) :- N < 10, !, format(atom(Atomo), '0~d', [N]).
dos_digitos(N, Atomo) :- format(atom(Atomo), '~d', [N]).
