% s2.pl - Escenario: contador que vuelve a cero
% Demuestra: deteccion de reinicio, desbordamiento y dato corrupto

:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(36300)),
    
    % p1_general: lecturas normales de kwh
    assertz(lectura(p1_general, kwh, 5000.0, 36000)),
    assertz(lectura(p1_general, kwh, 5002.0, 36300)),
    assertz(lectura(p1_general, v, 126, 36000)),
    assertz(lectura(p1_general, v, 126, 36300)),
    assertz(consulta(p1_general, ok, 50, 36000)),
    assertz(consulta(p1_general, ok, 50, 36300)),
    
    % p1_motores: lecturas normales de kwh
    assertz(lectura(p1_motores, kwh, 800.0, 36000)),
    assertz(lectura(p1_motores, kwh, 801.4, 36300)),
    assertz(lectura(p1_motores, v, 126, 36000)),
    assertz(lectura(p1_motores, v, 126, 36300)),
    assertz(consulta(p1_motores, ok, 50, 36000)),
    assertz(consulta(p1_motores, ok, 50, 36300)),
    
    % p1_alumbrado: contador reinicia
    assertz(lectura(p1_alumbrado, kwh, 1520.4, 36000)),
    assertz(lectura(p1_alumbrado, v, 126, 36000)),
    assertz(consulta(p1_alumbrado, ok, 50, 36000)),
    
    % Timeouts de 36005 a 36060 (cada 5s)
    forall(
        between(0, 11, N),
        (Seg is 36005 + N * 5, assertz(consulta(p1_alumbrado, timeout, 1000, Seg)))
    ),
    
    % Evento de reinicio
    assertz(evento(p1_alumbrado, reinicio, 36030)),
    
    % Despues del reinicio: kwh bajo
    assertz(lectura(p1_alumbrado, kwh, 0.05, 36065)),
    assertz(lectura(p1_alumbrado, v, 126, 36065)),
    assertz(consulta(p1_alumbrado, ok, 50, 36065)),
    
    assertz(lectura(p1_alumbrado, kwh, 0.1, 36300)),
    assertz(lectura(p1_alumbrado, v, 126, 36300)),
    assertz(consulta(p1_alumbrado, ok, 50, 36300)),
    
    % Otros medidores normales
    assertz(lectura(acometida, v, 127, 36300)),
    assertz(lectura(acometida, kw, 25, 36300)),
    assertz(lectura(p2_general, v, 127, 36300)),
    assertz(lectura(p2_general, kw, 8, 36300)),
    assertz(lectura(p2_compartido, v, 126, 36300)),
    assertz(lectura(p2_compartido, kw, 6, 36300)),
    assertz(lectura(p3_aulas, v, 127, 36300)),
    assertz(lectura(p3_aulas, kw, 7, 36300)).
