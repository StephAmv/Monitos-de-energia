% reglas_tests.pl - Pruebas del gemelo digital #8 Monitor de energia
% Autora: Stephanie Ariana Medrano Vargas (23212013)
% Materia: Programacion Logica y Funcional

:- use_module('../hechos').
:- use_module('../reglas').
:- use_module(library(plunit)).

% ============================================================================
% Fase 1: Pruebas de carga de escenarios
% ============================================================================

:- begin_tests(carga_escenarios).

test(carga_s0_normal, [setup(cargar_escenario(s0_normal))]) :-
    ahora(T),
    assertion(T == 45000),
    medidor(acometida, _, _, _),
    medidor(p1_general, _, _, _),
    medidor(p1_motores, _, _, _),
    medidor(p1_alumbrado, _, _, _),
    medidor(p2_general, _, _, _),
    medidor(p2_compartido, _, _, _),
    medidor(p3_aulas, _, _, _),
    lectura(acometida, kw, _, _).

test(carga_s1a, [setup(cargar_escenario(s1a))]) :-
    ahora(T),
    assertion(T == 43320),
    lectura(acometida, kw, _, _).

test(carga_s1b, [setup(cargar_escenario(s1b))]) :-
    ahora(T),
    assertion(T == 43860),
    evento(bomba, arranque_previsto, _),
    evento(compresor, arranque_previsto, _),
    evento(extractor, arranque_previsto, _).

test(carga_s2, [setup(cargar_escenario(s2))]) :-
    ahora(T),
    assertion(T == 36300),
    evento(p1_alumbrado, reinicio, _).

test(carga_s3, [setup(cargar_escenario(s3))]) :-
    ahora(T),
    assertion(T == 50700),
    consulta(p1_general, ok, Ms1, _),
    assertion(Ms1 >= 500).

test(carga_s4a, [setup(cargar_escenario(s4a))]) :-
    ahora(T),
    assertion(T == 30005),
    lectura(acometida, v, V, _),
    assertion(V < 114).

test(carga_s4b, [setup(cargar_escenario(s4b))]) :-
    ahora(T),
    assertion(T == 30005),
    evento(compresor, arranque, _).

test(carga_s4c, [setup(cargar_escenario(s4c))]) :-
    ahora(T),
    assertion(T == 30005),
    consulta(acometida, timeout, _, _).

test(carga_s5, [setup(cargar_escenario(s5))]) :-
    ahora(T),
    assertion(T == 86000),
    lectura(p2_compartido, kw, 9.0, 57600).

:- end_tests(carga_escenarios).

% ============================================================================
% Fase 2: Pruebas de predicados base
% ============================================================================

:- begin_tests(base).

test(ultima_lectura_s0, [setup(cargar_escenario(s0_normal))]) :-
    ultima_lectura(acometida, kw, V, S),
    assertion(V == 25),
    assertion(S == 44995).

test(edad_s0, [setup(cargar_escenario(s0_normal))]) :-
    edad(acometida, E),
    assertion(E == 5).  % ahora(45000) - ultima(44995) = 5

test(fresca_s0, [setup(cargar_escenario(s0_normal))]) :-
    fresca(acometida, kw, Estado),
    assertion(Estado == si).  % edad 5 < 15

test(valor_conocido_s0, [setup(cargar_escenario(s0_normal))]) :-
    valor(acometida, kw, R),
    R = conocido(V),
    assertion(V == 25).

test(fresca_s3_vieja, [setup(cargar_escenario(s3))]) :-
    fresca(p1_alumbrado, kw, Estado),
    assertion(Estado == no).  % edad 40 > 15

test(valor_desconocido_vieja_s3, [setup(cargar_escenario(s3))]) :-
    valor(p1_alumbrado, kw, R),
    assertion(R = desconocido(vieja)).

test(valor_sin_lectura, [setup(cargar_escenario(s0_normal))]) :-
    valor(acometida, kwh, R),
    assertion(R = desconocido(sin_dato)).

test(segundo_a_hora) :-
    segundo_del_dia_a_hora(0, H1),
    assertion(H1 == '00:00'),
    segundo_del_dia_a_hora(3661, H2),
    assertion(H2 == '01:01'),
    segundo_del_dia_a_hora(43200, H3),
    assertion(H3 == '12:00'),
    segundo_del_dia_a_hora(86399, H4),
    assertion(H4 == '23:59').

:- end_tests(base).
