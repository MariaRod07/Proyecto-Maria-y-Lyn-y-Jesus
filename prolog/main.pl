:- encoding(utf8).
/*  main.pl - Menú interactivo en consola (CLI) del motor LogiExpress

    Carga los módulos del sistema y expone el predicado principal iniciar/0
    (alias menu/0).

    Ejecución:
        swipl -q -g iniciar -t halt main.pl     (inicia el menú y sale al terminar)
        swipl main.pl        luego      ?- iniciar.
*/
:- set_prolog_flag(double_quotes, string).

:- ensure_loaded(tiempo).
:- ensure_loaded(carga).
:- ensure_loaded(consultas).
:- ensure_loaded(rutas).
:- ensure_loaded(optimizacion).

:- initialization(configurar_consola).
:- initialization(bienvenida).

%   En Windows la consola usa su propia página de códigos y SWI-Prolog la
%   respeta; en Linux/macOS se fuerza UTF-8 en la entrada y salida para que
%   los acentos se lean e impriman bien aunque la variable LANG no lo defina.
configurar_consola :-
    (   current_prolog_flag(windows, true)
    ->  true
    ;   set_stream(user_input,  encoding(utf8)),
        set_stream(user_output, encoding(utf8)),
        set_stream(user_error,  encoding(utf8))
    ).

%   Mensaje de ayuda solo cuando el archivo se consulta de forma interactiva
%   (con -g iniciar -t halt el menú arranca solo y el aviso sobra).
bienvenida :-
    (   current_prolog_flag(toplevel_goal, default)
    ->  format("~nLogiExpress (Prolog) cargado. Ejecute  ?- iniciar.  para abrir el menú.~n~n")
    ;   true
    ).

archivos_candidatos(['vuelos.txt', '../vuelos.txt']).

%!  iniciar is det.
%
%   Predicado principal: carga vuelos.txt si está disponible y entra al menú.
iniciar :-
    format("LogiExpress - Motor analítico de rutas aéreas (paradigma lógico)~n"),
    cargar_por_defecto,
    bucle_menu.

menu :- iniciar.

cargar_por_defecto :-
    archivos_candidatos(Candidatos),
    (   member(Archivo, Candidatos), exists_file(Archivo)
    ->  cargar_vuelos(Archivo)
    ;   format("No se encontró vuelos.txt; use la opción 1 para cargarlo.~n")
    ).

% ---------------------------------------------------------------------------
% Bucle principal
% ---------------------------------------------------------------------------

bucle_menu :-
    mostrar_menu,
    leer_linea('Seleccione una opción: ', Opcion),
    (   Opcion == end_of_file
    ->  format("~nFin de la entrada.~n")
    ;   Opcion == '0'
    ->  format("Hasta luego.~n")
    ;   Opcion == ''
    ->  bucle_menu
    ;   (   catch(ejecutar(Opcion), Error, (print_message(error, Error), true))
        ->  true
        ;   true          % la operación informó el motivo y fue cancelada
        ),
        bucle_menu
    ).

mostrar_menu :-
    (   archivo_cargado(Archivo) -> true ; Archivo = '(ninguno)' ),
    findall(x, vuelo(_, _, _, _, _, _, _), Vuelos),
    length(Vuelos, N),
    tmc(TMC),
    format("~n================== LogiExpress (Prolog) ==================~n"),
    format("Archivo: ~w | Vuelos: ~w | TMC: ~w min~n", [Archivo, N, TMC]),
    format("----------------------------------------------------------~n"),
    format("1. Cargar archivo de vuelos~n"),
    format("2. Configurar TMC (tiempo mínimo de conexión)~n"),
    format("3. Vuelos que salen de una ciudad~n"),
    format("4. Vuelos que llegan a una ciudad~n"),
    format("5. Vuelos que operan un día de la semana~n"),
    format("6. Buscar rutas válidas (origen, destino, día, K opcional)~n"),
    format("7. Ruta de costo mínimo y ruta de menor tiempo~n"),
    format("8. Reporte de rutas ordenadas por costo o por tiempo~n"),
    format("9. Listar ciudades~n"),
    format("0. Salir~n").

% ---------------------------------------------------------------------------
% Entrada de datos
% ---------------------------------------------------------------------------

%!  leer_linea(+Prompt, -Atomo) is det.
%
%   Lee una línea de user_input y la devuelve como átomo sin espacios
%   sobrantes; devuelve end_of_file si la entrada se agotó.
leer_linea(Prompt, Atomo) :-
    format("~w", [Prompt]),
    flush_output,
    read_line_to_string(user_input, Linea),
    (   Linea == end_of_file
    ->  Atomo = end_of_file
    ;   normalize_space(atom(Atomo), Linea)
    ).

%!  pedir_ciudad(+Prompt, -Ciudad) is semidet.
pedir_ciudad(Prompt, Ciudad) :-
    leer_linea(Prompt, Texto),
    (   buscar_ciudad(Texto, Ciudad)
    ->  true
    ;   format("Ciudad desconocida: '~w' (la opción 9 lista las ciudades).~n", [Texto]),
        fail
    ).

%!  pedir_dia(-Dia) is semidet.
pedir_dia(Dia) :-
    leer_linea('Día de la semana (Lunes..Domingo o L,M,Mi,J,V,S,D): ', Texto),
    (   normalizar_dia(Texto, Dia)
    ->  true
    ;   format("Día inválido: ~w~n", [Texto]),
        fail
    ).

%!  normalizar_dia(+Texto:atom, -Dia:atom) is semidet.
%
%   Acepta el nombre completo (con o sin acento, cualquier capitalización) o
%   la abreviatura usada en el archivo.
normalizar_dia(Texto, Dia) :-
    downcase_atom(Texto, Minusculas),
    atom_chars(Minusculas, Chars0),
    maplist(sin_acento, Chars0, Chars),
    atom_chars(Normalizado, Chars),
    (   nombre_dia(Normalizado, Dia)
    ->  true
    ;   abreviatura(Abrev, Dia), downcase_atom(Abrev, Normalizado)
    ).

sin_acento('á', a) :- !.
sin_acento('é', e) :- !.
sin_acento('í', i) :- !.
sin_acento('ó', o) :- !.
sin_acento('ú', u) :- !.
sin_acento(C, C).

nombre_dia(lunes,     lunes).
nombre_dia(martes,    martes).
nombre_dia(miercoles, miercoles).
nombre_dia(jueves,    jueves).
nombre_dia(viernes,   viernes).
nombre_dia(sabado,    sabado).
nombre_dia(domingo,   domingo).

%!  pedir_limite(-K) is semidet.
%
%   Enter = sin_limite; entero no negativo = máximo de escalas.
pedir_limite(K) :-
    leer_linea('Máximo de escalas K (Enter = sin límite): ', Texto),
    (   Texto == ''
    ->  K = sin_limite
    ;   atom_number(Texto, K), integer(K), K >= 0
    ->  true
    ;   format("Valor inválido para K: ~w~n", [Texto]),
        fail
    ).

%!  pedir_busqueda(-Origen, -Destino, -Dia, -K) is semidet.
pedir_busqueda(Origen, Destino, Dia, K) :-
    pedir_ciudad('Ciudad origen: ', Origen),
    pedir_ciudad('Ciudad destino: ', Destino),
    (   Origen == Destino
    ->  format("Origen y destino deben ser distintos.~n"), fail
    ;   true
    ),
    pedir_dia(Dia),
    pedir_limite(K).

% ---------------------------------------------------------------------------
% Opciones del menú
% ---------------------------------------------------------------------------

ejecutar('1') :- !,
    leer_linea('Ruta del archivo [vuelos.txt]: ', Texto),
    (   Texto == '' -> Archivo = 'vuelos.txt' ; Archivo = Texto ),
    (   cargar_vuelos(Archivo)
    ->  true
    ;   format("No existe el archivo: ~w~n", [Archivo])
    ).

ejecutar('2') :- !,
    tmc(Actual),
    format(atom(Prompt), 'Nuevo TMC en minutos [~w]: ', [Actual]),
    leer_linea(Prompt, Texto),
    (   atom_number(Texto, Nuevo), configurar_tmc(Nuevo)
    ->  format("TMC configurado en ~w min~n", [Nuevo])
    ;   format("Valor inválido; se mantiene el TMC actual.~n")
    ).

ejecutar('3') :- !,
    pedir_ciudad('Ciudad de salida: ', Ciudad),
    salidas_desde(Ciudad, Vuelos),
    format(atom(Titulo), 'Vuelos que salen de ~w', [Ciudad]),
    listar_vuelos(Titulo, Vuelos).

ejecutar('4') :- !,
    pedir_ciudad('Ciudad de llegada: ', Ciudad),
    llegadas_a(Ciudad, Vuelos),
    format(atom(Titulo), 'Vuelos que llegan a ~w', [Ciudad]),
    listar_vuelos(Titulo, Vuelos).

ejecutar('5') :- !,
    pedir_dia(Dia),
    vuelos_del_dia(Dia, Vuelos),
    format(atom(Titulo), 'Vuelos que operan el día ~w', [Dia]),
    listar_vuelos(Titulo, Vuelos).

ejecutar('6') :- !,
    pedir_busqueda(Origen, Destino, Dia, K),
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    length(Rutas, N),
    encabezado_busqueda(Origen, Destino, Dia, K),
    format("~w ruta(s) válida(s)~n", [N]),
    mostrar_rutas(Rutas, 1).

ejecutar('7') :- !,
    pedir_busqueda(Origen, Destino, Dia, K),
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    length(Rutas, N),
    encabezado_busqueda(Origen, Destino, Dia, K),
    format("~w ruta(s) evaluada(s)~n", [N]),
    (   Rutas == []
    ->  format("No existen rutas válidas.~n")
    ;   mas_barata(Rutas, _, Barata),
        format("-- Ruta de costo económico mínimo --~n"),
        mostrar_ruta(1, Barata),
        mas_rapida(Rutas, _, Rapida),
        format("-- Ruta de menor tiempo total de viaje --~n"),
        mostrar_ruta(1, Rapida)
    ).

ejecutar('8') :- !,
    pedir_busqueda(Origen, Destino, Dia, K),
    leer_linea('Ordenar por (c)osto o (t)iempo [c]: ', Criterio),
    todas_las_rutas(Origen, Destino, Dia, K, Rutas),
    downcase_atom(Criterio, CriterioMin),
    (   sub_atom(CriterioMin, 0, 1, _, t)
    ->  Titulo = 'tiempo total de viaje (mergesort)',
        ordenar_por_tiempo(Rutas, Pares)
    ;   Titulo = 'costo (quicksort)',
        ordenar_por_costo(Rutas, Pares)
    ),
    encabezado_busqueda(Origen, Destino, Dia, K),
    format("reporte ordenado por ~w~n", [Titulo]),
    (   Pares == []
    ->  format("No existen rutas válidas.~n")
    ;   pares_a_valores(Pares, Ordenadas),
        mostrar_rutas(Ordenadas, 1)
    ).

ejecutar('9') :- !,
    ciudades(Ciudades),
    length(Ciudades, N),
    atomic_list_concat(Ciudades, ', ', Lista),
    format("Ciudades (~w): ~w~n", [N, Lista]).

ejecutar(Opcion) :-
    format("Opción inválida: ~w~n", [Opcion]).

encabezado_busqueda(Origen, Destino, Dia, K) :-
    tmc(TMC),
    (   K == sin_limite -> KTexto = 'sin límite' ; KTexto = K ),
    format("~w -> ~w | ~w | TMC ~w min | K = ~w | ",
           [Origen, Destino, Dia, TMC, KTexto]).

% ---------------------------------------------------------------------------
% Presentación
% ---------------------------------------------------------------------------

listar_vuelos(Titulo, []) :- !,
    format("~w: ninguno.~n", [Titulo]).
listar_vuelos(Titulo, Vuelos) :-
    length(Vuelos, N),
    format("~w (~w):~n", [Titulo, N]),
    forall(member(V, Vuelos), mostrar_vuelo('  ', V)).

%!  mostrar_vuelo(+Sangria, +Vuelo)
%
%   ~t~N| rellena con espacios hasta la columna N (alineación en columnas).
mostrar_vuelo(Sangria, vuelo(O, D, S, L, C, Codigo, Dias)) :-
    minutos_a_hora(S, HS),
    minutos_a_hora(L, HL),
    formato_frecuencia(Dias, Frec),
    atom_length(Sangria, Desplazamiento),
    Col1 is Desplazamiento + 9,
    Col2 is Col1 + 29,
    Col3 is Col2 + 13,
    Col4 is Col3 + 10,
    format("~w~w~t~*|~w -> ~w~t~*|~w-~w~t~*|Bs ~w~t~*|[~w]~n",
           [Sangria, Codigo, Col1, O, D, Col2, HS, HL, Col3, C, Col4, Frec]).

formato_frecuencia(Dias, 'Diario') :-
    todos_los_dias(Dias), !.
formato_frecuencia(Dias, Frec) :-
    findall(Abrev, ( member(Dia, Dias), abreviatura(Abrev, Dia) ), Abrevs),
    atomic_list_concat(Abrevs, '-', Frec).

mostrar_rutas([], _).
mostrar_rutas([Ruta|Resto], N) :-
    mostrar_ruta(N, Ruta),
    N1 is N + 1,
    mostrar_rutas(Resto, N1).

mostrar_ruta(N, Ruta) :-
    escalas(Ruta, Escalas),
    costo_ruta(Ruta, Costo),
    tiempo_ruta(Ruta, Tiempo),
    formato_duracion(Tiempo, TiempoTexto),
    format("Ruta ~w: ~w escala(s) | Costo total Bs ~w | Tiempo total ~w~n",
           [N, Escalas, Costo, TiempoTexto]),
    forall(member(V, Ruta), mostrar_vuelo('    ', V)),
    esperas(Ruta, Esperas),
    (   Esperas == []
    ->  true
    ;   maplist(formato_duracion, Esperas, Textos),
        atomic_list_concat(Textos, ', ', Linea),
        format("    Esperas en escalas: ~w~n", [Linea])
    ).
