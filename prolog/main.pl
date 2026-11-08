:- set_prolog_flag(double_quotes, string).

:- ensure_loaded(tiempo).
:- ensure_loaded(carga).
:- ensure_loaded(consultas).
:- ensure_loaded(rutas).
:- ensure_loaded(optimizacion).

:- initialization(configurar_consola).
:- initialization(bienvenida).

configurar_consola :-
    (   current_prolog_flag(windows, true)
    ->  true
    ;   set_stream(user_input,  encoding(utf8)),
        set_stream(user_output, encoding(utf8)),
        set_stream(user_error,  encoding(utf8))
    ).

bienvenida :-
    (   current_prolog_flag(toplevel_goal, default)
    ->  format("~nLogiExpress (Prolog) cargado. Ejecute  ?- iniciar.  para abrir el menú.~n~n")
    ;   true
    ).

archivos_candidatos(['vuelos.txt', '../vuelos.txt']).

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
        ;   true
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

leer_linea(Prompt, Atomo) :-
    format("~w", [Prompt]),
    flush_output,
    read_line_to_string(user_input, Linea),
    (   Linea == end_of_file
    ->  Atomo = end_of_file
    ;   normalize_space(atom(Atomo), Linea)
    ).

pedir_ciudad(Prompt, Ciudad) :-
    leer_linea(Prompt, Texto),
    (   buscar_ciudad(Texto, Ciudad)
    ->  true
    ;   format("Ciudad desconocida: '~w' (la opción 9 lista las ciudades).~n", [Texto]),
        fail
    ).

pedir_dia(Dia) :-
    leer_linea('Día de la semana (Lunes..Domingo o L,M,Mi,J,V,S,D): ', Texto),
    (   normalizar_dia(Texto, Dia)
    ->  true
    ;   format("Día inválido: ~w~n", [Texto]),
        fail
    ).

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
nombre_dia(viernes
