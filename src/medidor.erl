-module(medidor).
-behaviour(gen_server).

%% API
-export([start_link/3, estado/2, nombre/2]).
%% Funciones puras exportadas para testing
-export([clasificar/2, calcular_kwh/3]).
%% Callbacks gen_server
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    piso :: integer(),
    id :: integer(),
    kw = 0.0 :: float(),
    kwh = 0.0 :: float(),
    umbral :: float(),
    ultima_lectura :: integer() % erlang:system_time(second)
}).

%% API

%% Inicia un medidor registrado como medidor_pN_mM
-spec start_link(integer(), integer(), float()) -> {ok, pid()} | {error, term()}.
start_link(Piso, Id, Umbral) ->
    Nombre = nombre(Piso, Id),
    gen_server:start_link({local, Nombre}, ?MODULE, {Piso, Id, Umbral}, []).

%% Devuelve el estado actual del medidor
-spec estado(integer(), integer()) -> map().
estado(Piso, Id) ->
    gen_server:call(nombre(Piso, Id), estado).

%% Calcula el nombre registrado de un medidor
-spec nombre(integer(), integer()) -> atom().
nombre(Piso, Id) ->
    list_to_atom("medidor_p" ++ integer_to_list(Piso) ++ "_m" ++ integer_to_list(Id)).

%% Clasifica el consumo segun el umbral
-spec clasificar(float(), float()) -> normal | alerta | critico.
clasificar(KW, Umbral) ->
    Porcentaje = (KW / Umbral) * 100,
    if
        Porcentaje >= 100 -> critico;
        Porcentaje >= 80 -> alerta;
        true -> normal
    end.

%% Calcula kWh incrementales: KW * (segundos / 3600)
-spec calcular_kwh(float(), integer(), integer()) -> float().
calcular_kwh(KW, TiempoAnterior, TiempoActual) ->
    Segundos = TiempoActual - TiempoAnterior,
    KW * (Segundos / 3600.0).

%% Callbacks

init({Piso, Id, Umbral}) ->
    {ok, #state{
        piso = Piso,
        id = Id,
        umbral = Umbral,
        ultima_lectura = erlang:system_time(second)
    }}.

handle_call(estado, _From, State) ->
    #state{piso = Piso, id = Id, kw = KW, kwh = KWh, umbral = Umbral} = State,
    Mapa = #{
        piso => Piso,
        id => Id,
        kw => KW,
        kwh => KWh,
        umbral => Umbral,
        estado => clasificar(KW, Umbral)
    },
    {reply, Mapa, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({lectura, KW}, State) ->
    #state{ultima_lectura = UltimaLectura, kwh = KWhAcumulado} = State,
    Ahora = erlang:system_time(second),
    Incremento = calcular_kwh(KW, UltimaLectura, Ahora),
    NuevoState = State#state{
        kw = KW,
        kwh = KWhAcumulado + Incremento,
        ultima_lectura = Ahora
    },
    {noreply, NuevoState};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
