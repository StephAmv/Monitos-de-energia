% s1a.pl - Escenario: pico brevisimo al inicio (NO debe rebasar)
% Demuestra: un pico alto pero breve no dispara alarma

:- use_module('../hechos').

cargar_datos :-
    % Ventana 43200-44100, ahora 43320 (120s dentro de la ventana)
    assertz(ahora(43320)),
    
    % Pico de 70 kW durante 30s (6 lecturas): 43200, 43205, 43210, 43215, 43220, 43225
    forall(
        between(0, 5, N),
        (Seg is 43200 + N * 5, assertz(lectura(acometida, kw, 70, Seg)))
    ),
    
    % Luego 25 kW desde 43230 hasta 43315 (18 lecturas)
    forall(
        between(0, 17, N),
        (Seg is 43230 + N * 5, assertz(lectura(acometida, kw, 25, Seg)))
    ),
    
    % Lecturas frescas de acometida
    assertz(lectura(acometida, v, 127, 43315)),
    assertz(consulta(acometida, ok, 45, 43315)),
    
    % p1_motores fresco
    assertz(lectura(p1_motores, v, 126, 43315)),
    assertz(lectura(p1_motores, kw, 0, 43315)),
    assertz(consulta(p1_motores, ok, 50, 43315)),
    
    % Otros medidores con lecturas normales
    assertz(lectura(p1_general, v, 126, 43315)),
    assertz(lectura(p1_general, kw, 2, 43315)),
    assertz(lectura(p1_alumbrado, v, 126, 43315)),
    assertz(lectura(p1_alumbrado, kw, 2, 43315)),
    assertz(lectura(p2_general, v, 127, 43315)),
    assertz(lectura(p2_general, kw, 8, 43315)),
    assertz(lectura(p2_compartido, v, 126, 43315)),
    assertz(lectura(p2_compartido, kw, 6, 43315)),
    assertz(lectura(p3_aulas, v, 127, 43315)),
    assertz(lectura(p3_aulas, kw, 7, 43315)).
