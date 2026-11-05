-module(energia_datos).

%% API - funciones puras
-export([por_piso/1, alarmas/1, edificio_completo/0]).

%% Agrupa estados de medidores por piso, sumando kW y kWh
-spec por_piso([map()]) -> map().
por_piso(Estados) ->
    Agrupado = lists:foldl(
        fun(#{piso := Piso, kw := KW, kwh := KWh}, Acc) ->
            #{total_kw := KWAnt, total_kwh := KWhAnt} = maps:get(Piso, Acc, #{total_kw => 0.0, total_kwh => 0.0}),
            maps:put(Piso, #{total_kw => KWAnt + KW, total_kwh => KWhAnt + KWh}, Acc)
        end,
        #{},
        Estados
    ),
    % Convertir a lista de mapas con el numero de piso
    lists:map(
        fun({Piso, #{total_kw := KW, total_kwh := KWh}}) ->
            #{piso => Piso, total_kw => KW, total_kwh => KWh}
        end,
        lists:sort(maps:to_list(Agrupado))
    ).

%% Filtra medidores en estado alerta o critico
-spec alarmas([map()]) -> [map()].
alarmas(Estados) ->
    lists:filter(
        fun(#{estado := Estado}) ->
            Estado == alerta orelse Estado == critico
        end,
        Estados
    ).

%% Obtiene todos los estados de medidores y calcula totales
-spec edificio_completo() -> map().
edificio_completo() ->
    {ok, Pisos} = application:get_env(energia, pisos),
    {ok, MedidoresPorPiso} = application:get_env(energia, medidores_por_piso),
    
    % Obtener estado de todos los medidores
    Estados = obtener_todos_estados(Pisos, MedidoresPorPiso),
    
    % Calcular totales
    {TotalKW, TotalKWh} = lists:foldl(
        fun(#{kw := KW, kwh := KWh}, {AccKW, AccKWh}) ->
            {AccKW + KW, AccKWh + KWh}
        end,
        {0.0, 0.0},
        Estados
    ),
    
    #{
        total_kw => TotalKW,
        total_kwh => TotalKWh,
        pisos => por_piso(Estados),
        alarmas => alarmas(Estados),
        medidores => Estados
    }.

%% Funciones privadas

obtener_todos_estados(Pisos, MedidoresPorPiso) ->
    lists:flatten([
        [medidor:estado(Piso, Id) || Id <- lists:seq(1, MedidoresPorPiso)]
        || Piso <- lists:seq(1, Pisos)
    ]).
