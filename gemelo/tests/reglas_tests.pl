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
