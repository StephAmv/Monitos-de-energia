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

% Stubs temporales (se implementaran en las siguientes fases)
ultima_lectura(_, _, _, _) :- fail.
edad(_, _) :- fail.
fresca(_, _, _) :- fail.
valor(_, _, _) :- fail.
segundo_del_dia_a_hora(_, _) :- fail.
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
