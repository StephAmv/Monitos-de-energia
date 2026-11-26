% hechos.pl - Gemelo digital #8 Monitor de energia
% Autora: Stephanie Ariana Medrano Vargas (23212013)
% Materia: Programacion Logica y Funcional

:- module(hechos, [
    medidor/4,
    cuelga_de/2,
    area/2,
    piso_tiene_motores/1,
    motor/4,
    equipo_base/2,
    carga_declarada/2,
    horario/3,
    limite/2,
    rango/3,
    cargar_escenario/1,
    descripcion_escenario/2,
    ahora/1,
    lectura/4,
    consulta/4,
    evento/3,
    escenario_actual/1
]).

:- use_module(library(lists)).

% Predicados dinamicos
:- dynamic ahora/1.
:- dynamic lectura/4.
:- dynamic consulta/4.
:- dynamic evento/3.
:- dynamic escenario_actual/1.

% Medidores: medidor(Nombre, Lugar, Bus, Orden)
medidor(acometida,     acometida, bus_a, 1).
medidor(p1_general,    piso1,     bus_a, 2).
medidor(p1_motores,    piso1,     bus_a, 3).
medidor(p1_alumbrado,  piso1,     bus_a, 4).
medidor(p2_general,    piso2,     bus_b, 1).
medidor(p2_compartido, piso2,     bus_b, 2).
medidor(p3_aulas,      piso3,     bus_b, 3).

% Topologia electrica: cuelga_de(Medidor, MedidorGeneral)
cuelga_de(p1_general, acometida).
cuelga_de(p2_general, acometida).
cuelga_de(p3_aulas, acometida).
cuelga_de(p1_motores, p1_general).
cuelga_de(p1_alumbrado, p1_general).
cuelga_de(p2_compartido, p2_general).

% Areas
area(taller, p1_motores).
area(taller, p1_alumbrado).
area(laboratorio, p2_compartido).
area(oficinas, p2_compartido).
area(aulas, p3_aulas).

% Motores y equipos
piso_tiene_motores(piso1).
motor(bomba, p1_motores, 7.5, 1).
motor(extractor, p1_motores, 3.7, 2).
motor(compresor, p1_motores, 11.0, 3).
equipo_base(laboratorio, 1.5).
carga_declarada(laboratorio, 0.3).
carga_declarada(oficinas, 0.7).

% Horarios: horario(Area, Desde, Hasta) en segundos del dia
horario(oficinas, 28800, 64800).      % 08:00 - 18:00
horario(laboratorio, 28800, 72000).   % 08:00 - 20:00
horario(aulas, 25200, 79200).         % 07:00 - 22:00

% Limites
limite(demanda, 40.0).
limite(ventana_s, 900).
limite(ciclo_s, 5).
limite(ms_timeout, 1000).
limite(ms_lento, 500).
limite(vieja_s, 15).
limite(voltaje_bajo, 114.0).
limite(max_contador, 99999.9).
limite(fp_minimo, 0.90).
limite(tolerancia_nocturna, 1.2).

% Rangos: rango(Variable, Minimo, Maximo)
rango(v, 0, 260).
rango(kw, 0, 200).
rango(kvar, 0, 200).
rango(kwh, 0, 99999.9).
rango(hz, 55, 65).
rango(a, 0, 500).

% cargar_escenario(+Nombre): carga un archivo de escenario
cargar_escenario(Nombre) :-
    member(Nombre, [s0_normal, s1a, s1b, s2, s3, s4a, s4b, s4c, s5]),
    retractall(ahora(_)),
    retractall(lectura(_, _, _, _)),
    retractall(consulta(_, _, _, _)),
    retractall(evento(_, _, _)),
    retractall(escenario_actual(_)),
    atom_concat('escenarios/', Nombre, Path1),
    atom_concat(Path1, '.pl', Path),
    consult(Path),
    cargar_datos,
    assertz(escenario_actual(Nombre)).

% descripcion_escenario(Nombre, Texto): descripcion de cada escenario
descripcion_escenario(s0_normal, 'Todo en orden, sin alarmas').
descripcion_escenario(s1a, 'Pico brevísimo al inicio (no debe rebasar)').
descripcion_escenario(s1b, 'Carga moderada sostenida al final con arranques (sí debe rebasar)').
descripcion_escenario(s2, 'Contador que vuelve a cero').
descripcion_escenario(s3, 'Medidor lento y sus víctimas').
descripcion_escenario(s4a, 'Caída de voltaje - red de la CFE').
descripcion_escenario(s4b, 'Caída de voltaje - arranque de motores').
descripcion_escenario(s4c, 'Caída de voltaje - no se puede decir').
descripcion_escenario(s5, 'Reparto del medidor compartido').
