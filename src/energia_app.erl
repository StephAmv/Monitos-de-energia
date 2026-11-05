-module(energia_app).
-behaviour(application).

%% Callbacks application
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Iniciar Cowboy
    {ok, Puerto} = application:get_env(energia, puerto),
    
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/edificio", energia_http, edificio},
            {"/api/demo/pico/:piso/:medidor", energia_http, pico},
            {"/api/demo/falla/:piso/:medidor", energia_http, falla},
            {"/", cowboy_static, {priv_file, energia, "static/index.html"}},
            {"/static/[...]", cowboy_static, {priv_dir, energia, "static"}}
        ]}
    ]),
    
    {ok, _} = cowboy:start_clear(
        http_listener,
        [{port, Puerto}],
        #{env => #{dispatch => Dispatch}}
    ),
    
    energia_sup:start_link().

stop(_State) ->
    ok.
