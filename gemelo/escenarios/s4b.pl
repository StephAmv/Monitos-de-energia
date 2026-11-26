% s4b.pl - Escenario: caida de voltaje - arranque de motores
% Demuestra: causa = arranque_motores (acometida normal, piso1 cae, potencia sube)

:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(30005)),
    
    % Evento de arranque del compresor
    assertz(evento(compresor, arranque, 29995)),
    
    % p1_motores: potencia sube de 0 a 11 kW
    assertz(lectura(p1_motores, v, 126, 29990)),
    assertz(lectura(p1_motores, kw, 0, 29990)),
    assertz(consulta(p1_motores, ok, 50, 29990)),
    
    assertz(lectura(p1_motores, v, 108, 29995)),
    assertz(lectura(p1_motores, kw, 11, 29995)),
    assertz(consulta(p1_motores, ok, 50, 29995)),
    
    % En T=30000, solo p1_general tiene voltaje bajo
    assertz(lectura(p1_general, v, 108, 30000)),
    assertz(lectura(p1_general, kw, 13, 30000)),
    assertz(consulta(p1_general, ok, 50, 30000)),
    
    % Acometida normal
    assertz(lectura(acometida, v, 124, 30000)),
    assertz(lectura(acometida, kw, 36, 30000)),
    assertz(consulta(acometida, ok, 45, 30000)),
    
    % Otros pisos normales
    assertz(lectura(p2_general, v, 125, 30000)),
    assertz(lectura(p2_general, kw, 8, 30000)),
    assertz(consulta(p2_general, ok, 50, 30000)),
    
    assertz(lectura(p3_aulas, v, 126, 30000)),
    assertz(lectura(p3_aulas, kw, 7, 30000)),
    assertz(consulta(p3_aulas, ok, 50, 30000)),
    
    assertz(lectura(p1_alumbrado, v, 108, 30000)),
    assertz(lectura(p1_alumbrado, kw, 2, 30000)),
    assertz(lectura(p2_compartido, v, 125, 30000)),
    assertz(lectura(p2_compartido, kw, 6, 30000)).
