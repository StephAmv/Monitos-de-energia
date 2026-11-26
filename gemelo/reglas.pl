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

% Implementacion pendiente
