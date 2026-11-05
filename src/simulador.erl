-module(simulador).
-behaviour(gen_server).

%% API
-export([start_link/0, pico/2]).
%% Callbacks gen_server
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    pisos :: integer(),
    medidores_por_piso :: integer(),
    intervalo_ms :: integer(),
    umbral :: float(),
    picos = #{} :: map() % {Piso, Id} => CiclosRestantes
}).

%% API

%% Inicia el simulador
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Provoca un pico de consumo en un medidor especifico durante varios ciclos
-spec pico(integer(), integer()) -> ok.
pico(Piso, Id) ->
    gen_server:cast(?MODULE, {pico, Piso, Id}).

%% Callbacks

init([]) ->
    {ok, Pisos} = application:get_env(energia, pisos),
    {ok, MedidoresPorPiso} = application:get_env(energia, medidores_por_piso),
    {ok, IntervaloMs} = application:get_env(energia, intervalo_ms),
    {ok, Umbral} = application:get_env(energia, umbral_kw),
    
    % Programar primer tick
    erlang:send_after(IntervaloMs, self(), tick),
    
    {ok, #state{
        pisos = Pisos,
        medidores_por_piso = MedidoresPorPiso,
        intervalo_ms = IntervaloMs,
        umbral = Umbral,
        picos = #{}
    }}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({pico, Piso, Id}, State) ->
    #state{picos = Picos} = State,
    % El pico dura 5 ciclos
    NuevosPicos = maps:put({Piso, Id}, 5, Picos),
    {noreply, State#state{picos = NuevosPicos}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(tick, State) ->
    #state{pisos = Pisos, medidores_por_piso = MedidoresPorPiso, 
           intervalo_ms = IntervaloMs, umbral = Umbral, picos = Picos} = State,
    
    % Enviar lecturas a todos los medidores
    NuevosPicos = enviar_lecturas(Pisos, MedidoresPorPiso, Umbral, Picos),
    
    % Programar siguiente tick
    erlang:send_after(IntervaloMs, self(), tick),
    
    {noreply, State#state{picos = NuevosPicos}};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Funciones privadas

enviar_lecturas(Pisos, MedidoresPorPiso, Umbral, Picos) ->
    lists:foldl(
        fun(Piso, PicosAcc1) ->
            lists:foldl(
                fun(Id, PicosAcc2) ->
                    {KW, NuevosPicos} = generar_lectura(Piso, Id, Umbral, PicosAcc2),
                    Nombre = medidor:nombre(Piso, Id),
                    gen_server:cast(Nombre, {lectura, KW}),
                    NuevosPicos
                end,
                PicosAcc1,
                lists:seq(1, MedidoresPorPiso)
            )
        end,
        Picos,
        lists:seq(1, Pisos)
    ).

generar_lectura(Piso, Id, Umbral, Picos) ->
    Clave = {Piso, Id},
    case maps:get(Clave, Picos, 0) of
        0 ->
            % Lectura normal: base variable por medidor + ruido
            Base = consumo_base(Piso, Id, Umbral),
            Ruido = (rand:uniform() - 0.5) * 2.0, % +/- 1 kW
            {Base + Ruido, Picos};
        Ciclos when Ciclos > 1 ->
            % En pico: superar el umbral
            KW = Umbral * (1.05 + rand:uniform() * 0.1), % 105-115% del umbral
            {KW, maps:put(Clave, Ciclos - 1, Picos)};
        1 ->
            % Ultimo ciclo del pico
            KW = Umbral * (1.05 + rand:uniform() * 0.1),
            {KW, maps:remove(Clave, Picos)}
    end.

consumo_base(Piso, Id, Umbral) ->
    % Cada medidor tiene un consumo base distinto (40%-70% del umbral)
    Semilla = Piso * 100 + Id,
    Factor = 0.4 + (Semilla rem 30) / 100.0, % 0.4 a 0.7
    Umbral * Factor.
