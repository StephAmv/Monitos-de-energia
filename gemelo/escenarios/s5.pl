% s5.pl - Escenario: reparto del medidor compartido (un dia completo)
% Demuestra: reparto de energia y demanda entre laboratorio y oficinas

:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(86000)),
    
    % p2_compartido tiene una lectura por ventana de 15 min (96 lecturas)
    % Cada lectura es el promedio de esa ventana
    
    % 00:00-07:45 (0-27900, 31 ventanas) -> kw 1.6, kvar 1.0
    forall(
        between(0, 30, N),
        (Seg is N * 900, 
         assertz(lectura(p2_compartido, kw, 1.6, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % 08:00-08:45 (28800-31500, 4 ventanas) -> kw 4.0, kvar 1.0
    forall(
        between(32, 35, N),
        (Seg is N * 900,
         assertz(lectura(p2_compartido, kw, 4.0, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % 09:00-15:45 (32400-56700, 27 ventanas) -> kw 6.0, kvar 1.0
    forall(
        between(36, 62, N),
        (Seg is N * 900,
         assertz(lectura(p2_compartido, kw, 6.0, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % 16:00 (57600, ventana maxima) -> kw 9.0, kvar 5.0
    assertz(lectura(p2_compartido, kw, 9.0, 57600)),
    assertz(lectura(p2_compartido, kvar, 5.0, 57600)),
    assertz(lectura(p2_compartido, v, 126, 57600)),
    
    % 16:15-17:45 (58500-63900, 7 ventanas) -> kw 6.0, kvar 1.0
    forall(
        between(65, 71, N),
        (Seg is N * 900,
         assertz(lectura(p2_compartido, kw, 6.0, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % 18:00-19:45 (64800-70800, 8 ventanas) -> kw 3.5, kvar 1.0
    forall(
        between(72, 79, N),
        (Seg is N * 900,
         assertz(lectura(p2_compartido, kw, 3.5, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % 20:00-23:45 (72000-85500, 16 ventanas) -> kw 1.6, kvar 1.0
    forall(
        between(80, 95, N),
        (Seg is N * 900,
         assertz(lectura(p2_compartido, kw, 1.6, Seg)),
         assertz(lectura(p2_compartido, kvar, 1.0, Seg)),
         assertz(lectura(p2_compartido, v, 126, Seg)))
    ),
    
    % Otros medidores con lecturas normales
    assertz(lectura(acometida, v, 127, 86000)),
    assertz(lectura(acometida, kw, 25, 86000)),
    assertz(lectura(p1_general, v, 126, 86000)),
    assertz(lectura(p1_general, kw, 10, 86000)),
    assertz(lectura(p1_motores, v, 126, 86000)),
    assertz(lectura(p1_motores, kw, 0, 86000)),
    assertz(lectura(p1_alumbrado, v, 126, 86000)),
    assertz(lectura(p1_alumbrado, kw, 2, 86000)),
    assertz(lectura(p2_general, v, 127, 86000)),
    assertz(lectura(p2_general, kw, 8, 86000)),
    assertz(lectura(p3_aulas, v, 127, 86000)),
    assertz(lectura(p3_aulas, kw, 7, 86000)).
