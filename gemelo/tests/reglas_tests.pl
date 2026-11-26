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

% ============================================================================
% Fase 3: Pruebas de Situacion 1 - Pico futuro
% ============================================================================

:- begin_tests(situacion1).

test(ventana_s1a, [setup(cargar_escenario(s1a))]) :-
    ventana_actual(Inicio, Fin),
    assertion(Inicio == 43200),
    assertion(Fin == 44100).

test(acumulado_s1a, [setup(cargar_escenario(s1a))]) :-
    acumulado_ventana(KwS, Faltantes),
    Esperado is 70 * 30 + 25 * 90,
    assertion(abs(KwS - Esperado) < 0.1),
    assertion(Faltantes == []).

test(proyeccion_s1a_ninguna, [setup(cargar_escenario(s1a))]) :-
    proyeccion([], Promedio, Certeza, _),
    assertion(abs(Promedio - 26.5) < 0.1),
    assertion(Certeza == firme).

test(alarma_s1a_ninguna, [setup(cargar_escenario(s1a))]) :-
    alarma_demanda(Tipo, Margen, Certeza, _),
    assertion(Tipo == ninguna),
    assertion(abs(Margen - 13.5) < 0.1),
    assertion(Certeza == firme).

test(acumulado_s1b_con_faltante, [setup(cargar_escenario(s1b))]) :-
    acumulado_ventana(KwS, Faltantes),
    Esperado is 36 * 660,
    assertion(abs(KwS - Esperado) < 0.1),
    assertion(Faltantes == [43500]).

test(alarma_s1b_anticipada, [setup(cargar_escenario(s1b))]) :-
    alarma_demanda(Tipo, Margen, Certeza, Expl),
    assertion(Tipo == anticipada),
    assertion(Margen < 0),  % Margen negativo = rebasamos
    assertion(abs(Margen - (-0.57)) < 0.1),
    assertion(Certeza == estimacion),
    member(lecturas_faltantes([43500]), Expl).

test(diferir_s1b_compresor, [setup(cargar_escenario(s1b))]) :-
    diferir(Motor, Hasta, Area),
    assertion(Motor == compresor),
    assertion(Hasta == 44100),
    assertion(Area == taller).

test(proyeccion_sin_compresor_s1b, [setup(cargar_escenario(s1b))]) :-
    proyeccion([compresor], Promedio, _, _),
    assertion(abs(Promedio - 38.37) < 0.1).

:- end_tests(situacion1).

% ============================================================================
% Fase 4: Pruebas de Situacion 2 - Contador
% ============================================================================

:- begin_tests(situacion2).

test(salto_reinicio_s2, [setup(cargar_escenario(s2))]) :-
    salto_contador(p1_alumbrado, Tipo, _),
    assertion(Tipo == reinicio).

test(consumo_medidor_reinicio_s2, [setup(cargar_escenario(s2))]) :-
    consumo_medidor(p1_alumbrado, 36000, 36300, R),
    R = entre(Min, Max),
    assertion(abs(Min - 0.1) < 0.01),
    assertion(abs(Max - 0.6) < 0.01).

test(consumo_piso_s2, [setup(cargar_escenario(s2))]) :-
    consumo_piso(piso1, 36000, 36300, R, _),
    R = se_sabe(C),
    assertion(abs(C - 2.0) < 0.01).

test(desbordamiento, [setup(cargar_escenario(s2_desbord))]) :-
    salto_contador(test_med, Tipo, _),
    assertion(Tipo == desbordamiento),
    consumo_medidor(test_med, 1000, 2000, R),
    R = se_sabe(C),
    assertion(abs(C - 0.7) < 0.01).

test(dato_corrupto, [setup(cargar_escenario(s2_corrupto))]) :-
    salto_contador(test_med2, Tipo, _),
    assertion(Tipo == dato_corrupto),
    consumo_medidor(test_med2, 1000, 2000, R),
    assertion(R = no_se_puede_saber).

:- end_tests(situacion2).

% ============================================================================
% Fase 5: Pruebas de Situacion 3 - Medidor lento
% ============================================================================

:- begin_tests(situacion3).

test(timeouts_s3, [setup(cargar_escenario(s3))]) :-
    timeouts(p1_alumbrado, N1),
    assertion(N1 == 3),
    timeouts(p1_motores, N2),
    assertion(N2 == 2),
    timeouts(p1_general, N3),
    assertion(N3 == 0).

test(lento_s3, [setup(cargar_escenario(s3))]) :-
    lento(p1_general, E1),
    assertion(E1 == si),
    lento(p1_motores, E2),
    assertion(E2 == no).

test(causante_s3, [setup(cargar_escenario(s3))]) :-
    causante_bus(bus_a, M, _),
    assertion(M == p1_general).

test(victimas_s3, [setup(cargar_escenario(s3))]) :-
    findall(M, victima(M, p1_general), Vs),
    sort(Vs, Ordenadas),
    assertion(Ordenadas == [p1_alumbrado, p1_motores]).

test(alarma_no_puedo_decir_s3, [setup(cargar_escenario(s3))]) :-
    alarma_demanda(Tipo, _, Certeza, _),
    assertion(Tipo == no_puedo_decir),
    assertion(Certeza == no_se).

:- end_tests(situacion3).
