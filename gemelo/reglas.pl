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
    consumo_piso/4,
    
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

% Stubs temporales (se implementaran en las siguientes fases)
ventana_actual(_, _) :- fail.
acumulado_ventana(_, _) :- fail.
proyeccion(_, _, _, _) :- fail.
alarma_demanda(_, _, _, _) :- fail.
diferir(_, _, _) :- fail.
salto_contador(_, _, _) :- fail.
consumo_medidor(_, _, _, _) :- fail.
consumo_piso(_, _, _, _) :- fail.
timeouts(_, _) :- fail.
lento(_, _) :- fail.
causante_bus(_, _, _) :- fail.
victima(_, _) :- fail.
lecturas_viejas_por_bus(_) :- fail.
alarmas_afectadas(_) :- fail.
aislar(_, _) :- fail.
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
