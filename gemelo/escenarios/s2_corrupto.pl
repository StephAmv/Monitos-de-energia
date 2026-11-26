% s2_corrupto.pl - Test de dato corrupto
:- use_module('../hechos').

cargar_datos :-
    assertz(ahora(2000)),
    assertz(lectura(test_med2, kwh, 1520.4, 1000)),
    assertz(lectura(test_med2, kwh, 800.0, 2000)).
