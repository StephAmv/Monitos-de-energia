% s3.pl - Escenario: medidor lento y sus victimas
% Demuestra: deteccion de causante vs victimas segun orden del bus

:- use_module('../hechos').

cargar_datos :-
    % Ventana 50400-51300, ahora 50700 (300s dentro)
    assertz(ahora(50700)),
    
    % Lecturas de acometida cada 5s desde 50400 (kw = 30)
    forall(
        between(0, 59, N),
        (Seg is 50400 + N * 5, assertz(lectura(acometida, kw, 30, Seg)))
    ),
    
    % Ciclos del bus_a en 50685, 50690 y 50695
    % acometida: ok 40ms en los tres
    assertz(consulta(acometida, ok, 40, 50685)),
    assertz(lectura(acometida, v, 127, 50685)),
    
    assertz(consulta(acometida, ok, 40, 50690)),
    assertz(lectura(acometida, v, 127, 50690)),
    
    assertz(consulta(acometida, ok, 40, 50695)),
    assertz(lectura(acometida, v, 127, 50695)),
    
    % p1_general: ok pero lento (750, 820, 900 ms > 500)
    assertz(consulta(p1_general, ok, 750, 50685)),
    assertz(lectura(p1_general, v, 126, 50685)),
    assertz(lectura(p1_general, kw, 3, 50685)),
    
    assertz(consulta(p1_general, ok, 820, 50690)),
    assertz(lectura(p1_general, v, 126, 50690)),
    assertz(lectura(p1_general, kw, 3, 50690)),
    
    assertz(consulta(p1_general, ok, 900, 50695)),
    assertz(lectura(p1_general, v, 126, 50695)),
    assertz(lectura(p1_general, kw, 3, 50695)),
    
    % p1_motores: timeout, ok 950ms, timeout; ultima lectura vieja (50680, edad 20s)
    assertz(consulta(p1_motores, timeout, 1000, 50685)),
    assertz(consulta(p1_motores, ok, 950, 50690)),
    assertz(lectura(p1_motores, v, 126, 50690)),
    assertz(lectura(p1_motores, kw, 0, 50690)),
    assertz(consulta(p1_motores, timeout, 1000, 50695)),
    assertz(lectura(p1_motores, v, 126, 50680)),
    assertz(lectura(p1_motores, kw, 0, 50680)),
    
    % p1_alumbrado: timeout en los tres; ultima lectura @50660 (edad 40s)
    assertz(consulta(p1_alumbrado, timeout, 1000, 50685)),
    assertz(consulta(p1_alumbrado, timeout, 1000, 50690)),
    assertz(consulta(p1_alumbrado, timeout, 1000, 50695)),
    assertz(lectura(p1_alumbrado, v, 126, 50660)),
    assertz(lectura(p1_alumbrado, kw, 2, 50660)),
    
    % bus_b normal (ok, 30-50ms, lecturas frescas)
    assertz(consulta(p2_general, ok, 30, 50695)),
    assertz(lectura(p2_general, v, 127, 50695)),
    assertz(lectura(p2_general, kw, 8, 50695)),
    
    assertz(consulta(p2_compartido, ok, 40, 50695)),
    assertz(lectura(p2_compartido, v, 126, 50695)),
    assertz(lectura(p2_compartido, kw, 6, 50695)),
    
    assertz(consulta(p3_aulas, ok, 50, 50695)),
    assertz(lectura(p3_aulas, v, 127, 50695)),
    assertz(lectura(p3_aulas, kw, 7, 50695)).
