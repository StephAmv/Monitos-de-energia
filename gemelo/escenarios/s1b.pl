% s1b.pl - Escenario: carga moderada sostenida al final con arranques (SI debe rebasar)
% Demuestra: proyeccion de alarma anticipada con motores

:- use_module('../hechos').

cargar_datos :-
    % Ventana 43200-44100, ahora 43860 (660s dentro de la ventana)
    assertz(ahora(43860)),
    
    % Acometida: 36 kW cada 5s desde 43200 hasta 43855 (132 lecturas)
    % EXCEPTO falta la lectura de 43500 (hay timeout)
    forall(
        (between(0, 131, N), Seg is 43200 + N * 5, Seg \= 43500),
        assertz(lectura(acometida, kw, 36, Seg))
    ),
    
    % Timeout en 43500
    assertz(consulta(acometida, timeout, 1000, 43500)),
    
    % Lecturas frescas de acometida
    assertz(lectura(acometida, v, 127, 43855)),
    assertz(consulta(acometida, ok, 45, 43855)),
    
    % p1_motores fresco (kw 0, sin motores encendidos)
    assertz(lectura(p1_motores, v, 126, 43855)),
    assertz(lectura(p1_motores, kw, 0, 43855)),
    assertz(consulta(p1_motores, ok, 50, 43855)),
    
    % Arranques previstos
    assertz(evento(bomba, arranque_previsto, 43890)),
    assertz(evento(compresor, arranque_previsto, 43920)),
    assertz(evento(extractor, arranque_previsto, 43950)),
    
    % Otros medidores normales
    assertz(lectura(p1_general, v, 126, 43855)),
    assertz(lectura(p1_general, kw, 4, 43855)),
    assertz(lectura(p1_alumbrado, v, 126, 43855)),
    assertz(lectura(p1_alumbrado, kw, 2, 43855)),
    assertz(lectura(p2_general, v, 127, 43855)),
    assertz(lectura(p2_general, kw, 15, 43855)),
    assertz(lectura(p2_compartido, v, 126, 43855)),
    assertz(lectura(p2_compartido, kw, 13, 43855)),
    assertz(lectura(p3_aulas, v, 127, 43855)),
    assertz(lectura(p3_aulas, kw, 15, 43855)).
