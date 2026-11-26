% s4a.pl - Escenario: caida de voltaje - red de la CFE
% Demuestra: causa = red (cae acometida y pisos sin motores)

:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(30005)),
    
    % En T=30000, todos los medidores tienen voltaje bajo
    assertz(lectura(acometida, v, 108, 30000)),
    assertz(lectura(acometida, kw, 25, 30000)),
    assertz(consulta(acometida, ok, 45, 30000)),
    
    assertz(lectura(p1_general, v, 109, 30000)),
    assertz(lectura(p1_general, kw, 10, 30000)),
    assertz(consulta(p1_general, ok, 50, 30000)),
    
    assertz(lectura(p2_general, v, 107, 30000)),
    assertz(lectura(p2_general, kw, 8, 30000)),
    assertz(consulta(p2_general, ok, 50, 30000)),
    
    assertz(lectura(p3_aulas, v, 108, 30000)),
    assertz(lectura(p3_aulas, kw, 7, 30000)),
    assertz(consulta(p3_aulas, ok, 50, 30000)),
    
    % p1_motores sin cambio de potencia, sin arranques
    assertz(lectura(p1_motores, v, 109, 30000)),
    assertz(lectura(p1_motores, kw, 0, 30000)),
    assertz(consulta(p1_motores, ok, 50, 30000)),
    
    assertz(lectura(p1_motores, v, 126, 29990)),
    assertz(lectura(p1_motores, kw, 0, 29990)),
    
    % Otros medidores normales
    assertz(lectura(p1_alumbrado, v, 109, 30000)),
    assertz(lectura(p1_alumbrado, kw, 2, 30000)),
    assertz(lectura(p2_compartido, v, 107, 30000)),
    assertz(lectura(p2_compartido, kw, 6, 30000)).
