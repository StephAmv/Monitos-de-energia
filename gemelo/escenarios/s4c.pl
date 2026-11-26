% s4c.pl - Escenario: caida de voltaje - no se puede decir
% Demuestra: causa = no_se_puede_decir (faltan datos criticos)

:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(30005)),
    
    % p1_general tiene voltaje bajo
    assertz(lectura(p1_general, v, 108, 30000)),
    assertz(lectura(p1_general, kw, 10, 30000)),
    assertz(consulta(p1_general, ok, 50, 30000)),
    
    % acometida y p1_motores con timeout; ultimas lecturas viejas (29975, edad 30s)
    assertz(consulta(acometida, timeout, 1000, 29995)),
    assertz(consulta(acometida, timeout, 1000, 30000)),
    assertz(lectura(acometida, v, 127, 29975)),
    assertz(lectura(acometida, kw, 25, 29975)),
    
    assertz(consulta(p1_motores, timeout, 1000, 29995)),
    assertz(consulta(p1_motores, timeout, 1000, 30000)),
    assertz(lectura(p1_motores, v, 126, 29975)),
    assertz(lectura(p1_motores, kw, 0, 29975)),
    
    % p2_general normal
    assertz(lectura(p2_general, v, 125, 30000)),
    assertz(lectura(p2_general, kw, 8, 30000)),
    assertz(consulta(p2_general, ok, 50, 30000)),
    
    % Otros medidores
    assertz(lectura(p1_alumbrado, v, 108, 30000)),
    assertz(lectura(p1_alumbrado, kw, 2, 30000)),
    assertz(lectura(p2_compartido, v, 125, 30000)),
    assertz(lectura(p2_compartido, kw, 6, 30000)),
    assertz(lectura(p3_aulas, v, 125, 30000)),
    assertz(lectura(p3_aulas, kw, 7, 30000)).
