-module(medidor_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).
%% Callbacks supervisor
-export([init/1]).

%% Inicia el supervisor de medidores
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, Pisos} = application:get_env(energia, pisos),
    {ok, MedidoresPorPiso} = application:get_env(energia, medidores_por_piso),
    {ok, Umbral} = application:get_env(energia, umbral_kw),
    
    % Crear una especificacion child por cada medidor
    Hijos = [
        #{
            id => {medidor, Piso, Id},
            start => {medidor, start_link, [Piso, Id, Umbral]},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [medidor]
        }
        || Piso <- lists:seq(1, Pisos),
           Id <- lists:seq(1, MedidoresPorPiso)
    ],
    
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 10
    },
    
    {ok, {SupFlags, Hijos}}.
