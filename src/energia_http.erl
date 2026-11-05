-module(energia_http).

%% Callbacks cowboy
-export([init/2]).

%% Maneja todas las peticiones HTTP
-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
init(Req, edificio) ->
    manejar_edificio(Req);

init(Req, pico) ->
    manejar_pico(Req);

init(Req, falla) ->
    manejar_falla(Req);

init(Req, Estado) ->
    {ok, Req, Estado}.

%% Funciones privadas

manejar_edificio(Req) ->
    Datos = energia_datos:edificio_completo(),
    Json = json:encode(Datos),
    Req2 = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>},
        Json,
        Req
    ),
    {ok, Req2, edificio}.

manejar_pico(Req) ->
    Piso = cowboy_req:binding(piso, Req),
    Medidor = cowboy_req:binding(medidor, Req),
    
    try
        PisoInt = binary_to_integer(Piso),
        MedidorInt = binary_to_integer(Medidor),
        
        % Verificar que el medidor existe
        case verificar_medidor(PisoInt, MedidorInt) of
            true ->
                simulador:pico(PisoInt, MedidorInt),
                Req2 = cowboy_req:reply(202,
                    #{<<"content-type">> => <<"application/json">>},
                    json:encode(#{ok => true}),
                    Req
                ),
                {ok, Req2, pico};
            false ->
                responder_error(Req, pico)
        end
    catch
        _:_ ->
            responder_error(Req, pico)
    end.

manejar_falla(Req) ->
    Piso = cowboy_req:binding(piso, Req),
    Medidor = cowboy_req:binding(medidor, Req),
    
    try
        PisoInt = binary_to_integer(Piso),
        MedidorInt = binary_to_integer(Medidor),
        
        % Verificar que el medidor existe
        case verificar_medidor(PisoInt, MedidorInt) of
            true ->
                Nombre = medidor:nombre(PisoInt, MedidorInt),
                Pid = whereis(Nombre),
                exit(Pid, kill),
                Req2 = cowboy_req:reply(202,
                    #{<<"content-type">> => <<"application/json">>},
                    json:encode(#{ok => true}),
                    Req
                ),
                {ok, Req2, falla};
            false ->
                responder_error(Req, falla)
        end
    catch
        _:_ ->
            responder_error(Req, falla)
    end.

responder_error(Req, Estado) ->
    Req2 = cowboy_req:reply(404,
        #{<<"content-type">> => <<"application/json">>},
        json:encode(#{error => <<"no encontrado">>}),
        Req
    ),
    {ok, Req2, Estado}.

verificar_medidor(Piso, Medidor) ->
    {ok, Pisos} = application:get_env(energia, pisos),
    {ok, MedidoresPorPiso} = application:get_env(energia, medidores_por_piso),
    Piso >= 1 andalso Piso =< Pisos andalso Medidor >= 1 andalso Medidor =< MedidoresPorPiso.
