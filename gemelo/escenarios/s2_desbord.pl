% s2_desbord.pl - Test de desbordamiento
:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(2000)),
    assertz(lectura(test_med, kwh, 99999.5, 1000)),
    assertz(lectura(test_med, kwh, 0.3, 2000)).
