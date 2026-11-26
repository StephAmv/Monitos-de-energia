% reglas.pl - Gemelo digital #8 Monitor de energia
% Autora: Stephanie Ariana Medrano Vargas (23212013)
% Materia: Programacion Logica y Funcional

:- module(reglas, [
    % Base (6.0)
    ultima_lectura/4,
    edad/2,
    fresca/3,
    valor/3,
    segundo_del_dia_a_hora/2,
    
    % Situacion 1 (6.1)
    ventana_actual/2,
    acumulado_ventana/2,
    proyeccion/4,
    alarma_demanda/4,
    diferir/3,
    
    % Situacion 2 (6.2)
    salto_contador/3,
    consumo_medidor/4,
    consumo_piso/5,
    
    % Situacion 3 (6.3)
    timeouts/2,
    lento/2,
    causante_bus/3,
    victima/2,
    lecturas_viejas_por_bus/1,
    alarmas_afectadas/1,
    aislar/2,
    
    % Situacion 4 (6.4)
    caida_voltaje/2,
    causa_caida/5,
    
    % Situacion 5 (6.5)
    reparto_lectura/4,
    reparto_energia/4,
    ventana_maxima/3,
    reparto_demanda/5,
    consumo_nocturno/3,
    factor_potencia/4,
    se_le_falla_a/2,
    
    % Contrato (6.6)
    decide/3,
    situacion/3,
    que_falta/2,
    hipotesis/4
]).

:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(hechos).

% ============================================================================
% Fase 2: Base - predicados fundamentales
% ============================================================================

% ultima_lectura(+Medidor, +Variable, -Valor, -Segundo): ultima lectura disponible
ultima_lectura(M, Var, Valor, Seg) :-
    findall(S-V, lectura(M, Var, V, S), Pares),
    Pares \= [],
    sort(Pares, Ordenados),
    reverse(Ordenados, [Seg-Valor|_]).

% edad(+Medidor, -Segundos): edad de la ultima consulta del medidor
edad(M, Edad) :-
    ahora(Ahora),
    findall(S, (lectura(M, _, _, S) ; consulta(M, _, _, S)), Segundos),
    Segundos \= [],
    max_list(Segundos, UltimoSeg),
    Edad is Ahora - UltimoSeg.

% fresca(+Medidor, +Variable, -Estado): si | no | no_se
fresca(M, Var, Estado) :-
    limite(vieja_s, MaxEdad),
    ( \+ lectura(M, Var, _, _) ->
        Estado = no_se
    ; ultima_lectura(M, Var, _, SegLectura),
      ahora(Ahora),
      Edad is Ahora - SegLectura,
      ( Edad =< MaxEdad ->
          % Verificar si hay timeout despues de la lectura
          ( (findall(S, consulta(M, timeout, _, S), Timeouts),
             member(ST, Timeouts),
             ST > SegLectura) ->
              Estado = no
          ;   Estado = si
          )
      ;   Estado = no
      )
    ).

% valor(+Medidor, +Variable, -Resultado): conocido(V) | desconocido(Razon)
valor(M, Var, R) :-
    fresca(M, Var, Estado),
    ( Estado == si ->
        ultima_lectura(M, Var, V, _),
        R = conocido(V)
    ; Estado == no ->
        R = desconocido(vieja)
    ; Estado == no_se ->
        R = desconocido(sin_dato)
    ).

% segundo_del_dia_a_hora(+Segundo, -Texto): formato "HH:MM"
segundo_del_dia_a_hora(S, Texto) :-
    H is S // 3600,
    M is (S mod 3600) // 60,
    format(atom(Texto), '~|~`0t~d~2+:~|~`0t~d~2+', [H, M]).

% ============================================================================
% Fase 3: Situacion 1 - Pico futuro
% ============================================================================

% ventana_actual(-Inicio, -Fin): ventana de demanda actual
ventana_actual(Inicio, Fin) :-
    ahora(Ahora),
    limite(ventana_s, Duracion),
    Inicio is (Ahora // Duracion) * Duracion,
    Fin is Inicio + Duracion.

% acumulado_ventana(-KwS, -Faltantes): acumulado en kW·s y segundos faltantes
acumulado_ventana(KwS, Faltantes) :-
    ventana_actual(Inicio, Fin),
    ahora(Ahora),
    limite(ciclo_s, Ciclo),
    findall(Seg, (between(0, 1000, N), Seg is Inicio + N * Ciclo, Seg < Ahora), Segundos),
    acumular_lecturas(Segundos, 0, 0, [], KwS, Faltantes).

% acumular_lecturas(+Segundos, +Acum, +UltimoValor, +Faltantes, -Total, -ListaFaltantes)
acumular_lecturas([], Acum, _, Faltantes, Acum, Faltantes).
acumular_lecturas([S|Ss], Acum, UltimoV, Falt, Total, TotalFalt) :-
    limite(ciclo_s, Ciclo),
    ( lectura(acometida, kw, V, S) ->
        NuevoAcum is Acum + V * Ciclo,
        acumular_lecturas(Ss, NuevoAcum, V, Falt, Total, TotalFalt)
    ; UltimoV > 0 ->
        % Rellena con el ultimo valor conocido
        NuevoAcum is Acum + UltimoV * Ciclo,
        acumular_lecturas(Ss, NuevoAcum, UltimoV, [S|Falt], Total, TotalFalt)
    ;   % Sin valor previo, usa 0
        acumular_lecturas(Ss, Acum, 0, [S|Falt], Total, TotalFalt)
    ).

% proyeccion(+Excluidos, -Promedio, -Certeza, -Explicacion)
proyeccion(Excluidos, Promedio, Certeza, Explicacion) :-
    acumulado_ventana(Acumulado, Faltantes),
    ventana_actual(Inicio, Fin),
    ahora(Ahora),
    Restante is Fin - Ahora,
    
    % Potencia base actual
    valor(acometida, kw, R),
    ( R = conocido(KwActual) ->
        KwBase = KwActual
    ;   KwBase = 0
    ),
    
    % Contribucion de la base
    EsperadoBase is KwBase * Restante,
    
    % Contribucion de los motores previstos
    findall(
        Contrib,
        (   motor(Motor, _, Potencia, _),
            \+ member(Motor, Excluidos),
            evento(Motor, arranque_previsto, TArranque),
            TArranque >= Ahora,
            TArranque < Fin,
            TiempoMotor is Fin - TArranque,
            Contrib is Potencia * TiempoMotor
        ),
        Contribuciones
    ),
    sumlist(Contribuciones, EsperadoMotores),
    
    Esperado is EsperadoBase + EsperadoMotores,
    Total is Acumulado + Esperado,
    limite(ventana_s, Duracion),
    Promedio is Total / Duracion,
    
    ( Faltantes == [] ->
        Certeza = firme
    ;   Certeza = estimacion
    ),
    
    Explicacion = [
        acumulado(Acumulado),
        restante_s(Restante),
        kw_actual(KwBase),
        esperado_motores(EsperadoMotores),
        promedio_proyectado(Promedio),
        lecturas_faltantes(Faltantes)
    ].

% alarma_demanda(-Tipo, -Margen, -Certeza, -Explicacion)
alarma_demanda(Tipo, Margen, Certeza, Explicacion) :-
    acumulado_ventana(Acumulado, Faltantes),
    limite(ventana_s, Duracion),
    PromedioAcumulado is Acumulado / Duracion,
    limite(demanda, Limite),
    proyeccion([], Proyectado, _, ExplProy),
    
    % Verificar si necesitamos lecturas de motores
    valor(p1_motores, kw, RMotores),
    findall(Pot, motor(_, _, Pot, _), Potencias),
    sumlist(Potencias, TotalMotores),
    
    ( RMotores = desconocido(_),
      Proyectado - Limite < TotalMotores,
      Proyectado - Limite > -TotalMotores ->
        % No podemos decidir porque los motores podrian cambiar el resultado
        Tipo = no_puedo_decir,
        Margen is Limite - Proyectado,
        Certeza = no_se,
        Explicacion = [margen_insuficiente(Margen), potencia_motores_desconocida(TotalMotores) | ExplProy]
    ; PromedioAcumulado >= Limite ->
        Tipo = vigente,
        Margen is Limite - Proyectado,
        ( Faltantes == [] -> Certeza = firme ; Certeza = estimacion ),
        Explicacion = [tipo(vigente), limite(Limite) | ExplProy]
    ; Proyectado >= Limite ->
        Tipo = anticipada,
        Margen is Limite - Proyectado,
        ( Faltantes == [] -> Certeza = firme ; Certeza = estimacion ),
        Explicacion = [tipo(anticipada), limite(Limite) | ExplProy]
    ;   Tipo = ninguna,
        Margen is Limite - Proyectado,
        ( Faltantes == [] -> Certeza = firme ; Certeza = estimacion ),
        Explicacion = [tipo(ninguna), limite(Limite) | ExplProy]
    ).

% diferir(-Motor, -Hasta, -SeLeFallaA)
diferir(Motor, Hasta, Area) :-
    alarma_demanda(Tipo, _, _, _),
    member(Tipo, [anticipada, vigente]),
    ventana_actual(_, Fin),
    Hasta = Fin,
    
    % Probar motores por prioridad (mayor prioridad = menor numero)
    findall(Pr-M, motor(M, _, _, Pr), Pares),
    sort(Pares, Ordenados),
    reverse(Ordenados, [_-Motor|_]),
    
    % Verificar que sin este motor no rebasa
    proyeccion([Motor], Proy, _, _),
    limite(demanda, Limite),
    Proy < Limite,
    
    % Area del motor
    motor(Motor, Medidor, _, _),
    area(Area, Medidor).

% ============================================================================
% Fase 4: Situacion 2 - Contador
% ============================================================================

% salto_contador(+Medidor, -Tipo, -Evidencia)
salto_contador(M, Tipo, Evidencia) :-
    findall(S-K, lectura(M, kwh, K, S), Lecturas),
    Lecturas \= [],
    sort(Lecturas, Ordenadas),
    % Buscar el ultimo salto hacia abajo
    encontrar_salto(Ordenadas, S1, K1, S2, K2),
    limite(max_contador, Max),
    Margen is Max * 0.01,
    ( evento(M, reinicio, TE), TE > S1, TE < S2 ->
        Tipo = reinicio,
        Evidencia = [anterior(K1, S1), nuevo(K2, S2), evento_reinicio(TE)]
    ; K1 >= (Max - Margen) ->
        Tipo = desbordamiento,
        Evidencia = [anterior(K1, S1), nuevo(K2, S2), cerca_maximo(Max)]
    ;   Tipo = dato_corrupto,
        Evidencia = [anterior(K1, S1), nuevo(K2, S2), sin_explicacion]
    ).

% encontrar_salto(+Lecturas, -S1, -K1, -S2, -K2): encuentra el ultimo salto hacia abajo
encontrar_salto([S1-K1, S2-K2|_], S1, K1, S2, K2) :-
    K2 < K1, !.
encontrar_salto([_|Rest], S1, K1, S2, K2) :-
    encontrar_salto(Rest, S1, K1, S2, K2).

% consumo_medidor(+Medidor, +Desde, +Hasta, -Resultado)
consumo_medidor(M, Desde, Hasta, R) :-
    ( \+ lectura(M, kwh, _, _) ->
        R = no_se_puede_saber
    ; salto_contador(M, Tipo, Ev) ->
        ( Tipo == reinicio ->
            % Consumo entre lo medido despues del reinicio y lo que dice el general
            member(evento_reinicio(TReinicio), Ev),
            findall(S-K, (lectura(M, kwh, K, S), S >= Desde, S =< Hasta, S > TReinicio), LecturasDespues),
            ( LecturasDespues = [] ->
                R = no_se_puede_saber
            ;   sort(LecturasDespues, Ordenadas),
                reverse(Ordenadas, [_-KFin|_]),
                ConsumoMin is KFin,
                % Buscar consumo del general
                ( cuelga_de(M, General),
                  consumo_medidor(General, Desde, Hasta, RGen),
                  RGen = se_sabe(CGen),
                  findall(CM, (cuelga_de(Otro, General), Otro \= M,
                               consumo_medidor(Otro, Desde, Hasta, se_sabe(CM))), COtros),
                  sumlist(COtros, SumaOtros),
                  ConsumoMax is CGen - SumaOtros ->
                    R = entre(ConsumoMin, ConsumoMax)
                ;   R = se_sabe(ConsumoMin)
                )
            )
        ; Tipo == desbordamiento ->
            limite(max_contador, Max),
            findall(S-K, (lectura(M, kwh, K, S), S >= Desde, S =< Hasta), Lecturas),
            sort(Lecturas, Ordenadas),
            reverse(Ordenadas, [_-KFin|_]),
            Ordenadas = [_-KIni|_],
            Consumo is (Max - KIni) + KFin,
            R = se_sabe(Consumo)
        ;   % dato_corrupto
            R = no_se_puede_saber
        )
    ;   % Sin salto, calculo normal
        findall(S-K, (lectura(M, kwh, K, S), S >= Desde, S =< Hasta), Lecturas),
        ( Lecturas = [] ->
            R = no_se_puede_saber
        ;   sort(Lecturas, Ordenadas),
            reverse(Ordenadas, [_-KFin|_]),
            Ordenadas = [_-KIni|_],
            ( KFin >= KIni ->
                Consumo is KFin - KIni,
                R = se_sabe(Consumo)
            ;   R = no_se_puede_saber
            )
        )
    ).

% consumo_piso(+Piso, +Desde, +Hasta, -Resultado, -Sustento)
consumo_piso(Piso, Desde, Hasta, R, Sustento) :-
    % Buscar el medidor general del piso
    ( medidor(General, Piso, _, _),
      atom_concat(_, '_general', General),
      consumo_medidor(General, Desde, Hasta, RGen),
      RGen = se_sabe(C) ->
        R = se_sabe(C),
        Sustento = [medidor_general(General, C)]
    ;   % Sumar los consumos de los medidores que cuelgan
        findall(C, (cuelga_de(M, _), medidor(M, Piso, _, _),
                    consumo_medidor(M, Desde, Hasta, se_sabe(C))), Consumos),
        ( Consumos = [] ->
            R = no_se_puede_saber,
            Sustento = [sin_datos]
        ; member(no_se_puede_saber, Consumos) ->
            R = no_se_puede_saber,
            Sustento = [medidor_sin_dato]
        ;   sumlist(Consumos, Total),
            R = se_sabe(Total),
            Sustento = [suma_medidores(Consumos)]
        )
    ).

% ============================================================================
% Fase 5: Situacion 3 - Medidor lento
% ============================================================================

% timeouts(+Medidor, -N): cuenta timeouts en las ultimas 3 consultas
timeouts(M, N) :-
    findall(S, consulta(M, _, _, S), Segundos),
    sort(Segundos, Ordenados),
    reverse(Ordenados, Ultimos),
    ( length(Ultimos, Len), Len >= 3 ->
        Ultimos = [S1, S2, S3|_],
        findall(1, (member(S, [S1, S2, S3]), consulta(M, timeout, _, S)), Ts),
        length(Ts, N)
    ;   N = 0
    ).

% lento(+Medidor, -Estado): si | no | no_se
lento(M, Estado) :-
    limite(ms_lento, Umbral),
    findall(S-Ms-R, consulta(M, R, Ms, S), Consultas),
    sort(Consultas, Ordenadas),
    reverse(Ordenadas, Ultimas),
    ( length(Ultimas, Len), Len >= 3 ->
        Ultimas = [_-Ms1-R1, _-Ms2-R2, _-Ms3-R3|_],
        findall(1, (member(Ms-R, [Ms1-R1, Ms2-R2, Ms3-R3]), R == ok, Ms > Umbral), Lentos),
        length(Lentos, NLentos),
        ( NLentos >= 2 ->
            Estado = si
        ;   Estado = no
        )
    ;   Estado = no_se
    ).

% causante_bus(+Bus, -Medidor, -Explicacion)
causante_bus(Bus, Causante, Explicacion) :-
    findall(Orden-M, medidor(M, _, Bus, Orden), Medidores),
    sort(Medidores, Ordenados),
    encontrar_causante(Ordenados, Causante),
    Explicacion = [bus(Bus), primer_lento(Causante)].

% encontrar_causante(+MedidoresPorOrden, -Causante)
encontrar_causante([_-M|Ms], Causante) :-
    lento(M, si), !,
    Causante = M.
encontrar_causante([_|Ms], Causante) :-
    encontrar_causante(Ms, Causante).

% victima(?Medidor, -Causante)
victima(M, Causante) :-
    medidor(M, _, Bus, OrdenM),
    causante_bus(Bus, Causante, _),
    M \= Causante,
    medidor(Causante, _, Bus, OrdenC),
    OrdenM > OrdenC,
    ( timeouts(M, N), N > 0 ; fresca(M, _, no) ).

% lecturas_viejas_por_bus(-Lista)
lecturas_viejas_por_bus(Lista) :-
    findall(M, (medidor(M, _, _, _), fresca(M, kw, no)), Lista).

% alarmas_afectadas(-Lista)
alarmas_afectadas(Lista) :-
    findall(alarma(M), (victima(M, _), fresca(M, kw, no)), Lista).

% aislar(-Medidor, -Explicacion)
aislar(M, Explicacion) :-
    causante_bus(_, M, _),
    findall(V, victima(V, M), Victimas),
    Explicacion = [causante(M), victimas(Victimas)].

% Stubs temporales (se implementaran en las siguientes fases)
caida_voltaje(_, _) :- fail.
causa_caida(_, _, _, _, _) :- fail.
reparto_lectura(_, _, _, _) :- fail.
reparto_energia(_, _, _, _) :- fail.
ventana_maxima(_, _, _) :- fail.
reparto_demanda(_, _, _, _, _) :- fail.
consumo_nocturno(_, _, _) :- fail.
factor_potencia(_, _, _, _) :- fail.
se_le_falla_a(_, _) :- fail.
decide(_, _, _) :- fail.
situacion(_, _, _) :- fail.
que_falta(_, _) :- fail.
hipotesis(_, _, _, _) :- fail.
