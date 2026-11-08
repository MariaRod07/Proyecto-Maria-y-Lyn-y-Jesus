:- encoding(utf8).

hora_a_minutos(Hora, Minutos) :-
    split_string(Hora, ":", " ", [HoraStr, MinStr]),
    number_string(H, HoraStr),
    number_string(M, MinStr),
    integer(H), integer(M),
    H >= 0, H < 24,
    M >= 0, M < 60,
    Minutos is H * 60 + M.

minutos_a_hora(Minutos, Hora) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    dos_digitos(H, HS),
    dos_digitos(M, MS),
    atomic_list_concat([HS, ':', MS], Hora).

formato_duracion(Minutos, Texto) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    dos_digitos(M, MS),
    format(atom(Texto), '~d min (~dh ~wmin)', [Minutos, H, MS]).

dos_digitos(N, Atomo) :- N < 10, !, format(atom(Atomo), '0~d', [N]).
dos_digitos(N, Atomo) :- format(atom(Atomo), '~d', [N]).
