% servidor.pl - Servidor web del gemelo digital #8 Monitor de energia
% Autora: Stephanie Ariana Medrano Vargas (23212013)
% Uso: swipl servidor.pl [puerto]

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(hechos).
:- use_module(reglas).

:- initialization(main, main).

:- http_handler(root(.), inicio, []).
:- http_handler(root(api/escenarios), api_escenarios, []).
:- http_handler(root(api/escenario), api_cambiar_escenario, []).
:- http_handler(root(api/estado), api_estado, []).
:- http_handler(root(api/demanda), api_demanda, []).
:- http_handler(root(api/decide), api_decide, []).
:- http_handler(root(api/situaciones), api_situaciones, []).
:- http_handler(root(api/que_falta), api_que_falta, []).
:- http_handler(root(api/hipotesis), api_hipotesis, []).
:- http_handler(root(api/caida), api_caida, []).
:- http_handler(root(api/reparto), api_reparto, []).
:- http_handler(prefix(web), sirve_archivos, [prefix]).

main(Argv) :-
    (Argv = [A|_], atom_number(A, Puerto) -> true ; Puerto = 8080),
    servidor(Puerto),
    thread_get_message(_).

servidor(Puerto) :-
    cargar_escenario(s0_normal),
    http_server(http_dispatch, [port(Puerto)]),
    format("Gemelo digital en http://localhost:~w/~n", [Puerto]).

inicio(Peticion) :-
    http_reply_file('web/index.html', [], Peticion).

sirve_archivos(Peticion) :-
    http_reply_from_files('web/', [], Peticion).

api_escenarios(_Peticion) :-
    escenario_actual(Actual),
    findall(_{nombre: N, descripcion: D},
            descripcion_escenario(N, D),
            Escenarios),
    reply_json_dict(_{actual: Actual, escenarios: Escenarios}).

api_cambiar_escenario(Peticion) :-
    http_parameters(Peticion, [nombre(Nombre, [])]),
    cargar_escenario(Nombre),
    reply_json_dict(_{actual: Nombre, ok: true}).

api_estado(_Peticion) :-
    findall(_{medidor: M, piso: P, bus: B, turno: O, edad: Edad, estado: Est},
            (medidor(M, P, B, O),
             ( edad(M, E) -> Edad = E ; Edad = 999 ),
             ( fresca(M, kw, si) -> Est = fresco ;
               fresca(M, kw, no) -> Est = viejo ;
               Est = sin_dato )),
            Medidores),
    reply_json_dict(_{medidores: Medidores}).

api_demanda(_Peticion) :-
    ventana_actual(Inicio, Fin),
    segundo_del_dia_a_hora(Inicio, HIni),
    segundo_del_dia_a_hora(Fin, HFin),
    acumulado_ventana(Acum, Faltantes),
    alarma_demanda(Tipo, Margen, Certeza, _),
    limite(demanda, Limite),
    proyeccion([], Proy, _, _),
    ( diferir(Motor, Hasta, Falla) ->
        segundo_del_dia_a_hora(Hasta, HHasta),
        Rec = _{motor: Motor, hasta: HHasta, se_le_falla_a: Falla}
    ;   Rec = null ),
    reply_json_dict(_{inicio: HIni, fin: HFin, acumulado: Acum,
                       proyectado: Proy, limite: Limite, margen: Margen,
                       certeza: Certeza, alarma: Tipo, faltantes: Faltantes,
                       recomendacion: Rec}).

api_decide(Peticion) :-
    http_parameters(Peticion, [entidad(Entidad, [])]),
    atom_string(E, Entidad),
    decide(E, Decision, Explicacion),
    term_string(Decision, DecStr),
    term_string(Explicacion, ExplStr),
    reply_json_dict(_{entidad: E, decision: DecStr, explicacion: ExplStr}).

api_situaciones(_Peticion) :-
    findall(_{entidad: E, situacion: S},
            situacion(E, S, _),
            Situaciones),
    reply_json_dict(_{situaciones: Situaciones}).

api_que_falta(Peticion) :-
    http_parameters(Peticion, [entidad(Entidad, [])]),
    atom_string(E, Entidad),
    que_falta(E, Cambios),
    reply_json_dict(_{entidad: E, cambios: Cambios}).

api_hipotesis(Peticion) :-
    http_parameters(Peticion, [motor(Motor, []), retraso(RetrasoStr, [])]),
    atom_string(M, Motor),
    atom_number(RetrasoStr, Retraso),
    hipotesis(mover(M, Retraso), ventana, Decision, Explicacion),
    term_string(Decision, DecStr),
    term_string(Explicacion, ExplStr),
    reply_json_dict(_{motor: M, retraso: Retraso, decision: DecStr, explicacion: ExplStr}).

api_caida(Peticion) :-
    http_parameters(Peticion, [piso(Piso, [])]),
    atom_string(P, Piso),
    causa_caida(P, Causa, Evidencia, Descartada, DatoFalta),
    reply_json_dict(_{piso: P, causa: Causa, evidencia: Evidencia,
                       descartada: Descartada, dato_que_falta: DatoFalta}).

api_reparto(_Peticion) :-
    reparto_energia(Lab, Ofi, Regla, Certeza),
    reparto_demanda(LabD, OfiD, PctLab, PctOfi, VentanaSeg),
    factor_potencia(p2_compartido, VentanaSeg, Fp, Penaliza),
    findall(A-Q, se_le_falla_a(A, Q), Fallas),
    reply_json_dict(_{energia: _{lab: Lab, ofi: Ofi},
                       demanda: _{lab: LabD, ofi: OfiD, pct_lab: PctLab, pct_ofi: PctOfi},
                       regla: Regla, certeza: Certeza,
                       fp: Fp, penaliza: Penaliza,
                       se_le_falla_a: Fallas}).
