-module(energia_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).
%% Callbacks supervisor
-export([init/1]).

%% Inicia el supervisor raiz
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 10
    },
    
    % Hijos: medidor_sup y simulador
    ChildSpecs = [
        #{
            id => medidor_sup,
            start => {medidor_sup, start_link, []},
            restart => permanent,
            shutdown => infinity,
            type => supervisor,
            modules => [medidor_sup]
        },
        #{
            id => simulador,
            start => {simulador, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [simulador]
        }
    ],
    
    {ok, {SupFlags, ChildSpecs}}.
