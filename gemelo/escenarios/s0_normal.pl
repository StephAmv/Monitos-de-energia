% s0_normal.pl - Escenario: todo en orden
% Demuestra: condiciones normales, sin alarmas

:- use_module('../hechos').

cargar_datos :-
    % Tiempo actual
    assertz(ahora(45000)),
    
    % Lecturas frescas de todos los medidores (segundo 44995)
    assertz(lectura(acometida, v, 127, 44995)),
    assertz(lectura(acometida, kw, 25, 44995)),
    assertz(lectura(p1_general, v, 126.5, 44995)),
    assertz(lectura(p1_general, kw, 10, 44995)),
    assertz(lectura(p1_motores, v, 126, 44995)),
    assertz(lectura(p1_motores, kw, 0, 44995)),
    assertz(lectura(p1_alumbrado, v, 126, 44995)),
    assertz(lectura(p1_alumbrado, kw, 2, 44995)),
    assertz(lectura(p2_general, v, 127, 44995)),
    assertz(lectura(p2_general, kw, 8, 44995)),
    assertz(lectura(p2_compartido, v, 126.5, 44995)),
    assertz(lectura(p2_compartido, kw, 6, 44995)),
    assertz(lectura(p3_aulas, v, 127, 44995)),
    assertz(lectura(p3_aulas, kw, 7, 44995)),
    
    % Consultas exitosas con tiempos normales
    assertz(consulta(acometida, ok, 40, 44995)),
    assertz(consulta(p1_general, ok, 50, 44995)),
    assertz(consulta(p1_motores, ok, 45, 44995)),
    assertz(consulta(p1_alumbrado, ok, 55, 44995)),
    assertz(consulta(p2_general, ok, 35, 44995)),
    assertz(consulta(p2_compartido, ok, 40, 44995)),
    assertz(consulta(p3_aulas, ok, 60, 44995)),
    
    % Lecturas de kw de acometida cada 5s desde el inicio de la ventana (44100) hasta 44995
    % Inicio de ventana: 45000 - (45000 mod 900) = 44100
    forall(
        between(0, 179, N),
        (Seg is 44100 + N * 5, assertz(lectura(acometida, kw, 25, Seg)))
    ).
