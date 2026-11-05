-module(energia_tests).
-include_lib("eunit/include/eunit.hrl").

%% Pruebas de clasificar/2
clasificar_normal_test() ->
    Umbral = 10.0,
    ?assertEqual(normal, medidor:clasificar(7.0, Umbral)).

clasificar_alerta_test() ->
    Umbral = 10.0,
    ?assertEqual(alerta, medidor:clasificar(8.0, Umbral)),
    ?assertEqual(alerta, medidor:clasificar(9.9, Umbral)).

clasificar_critico_test() ->
    Umbral = 10.0,
    ?assertEqual(critico, medidor:clasificar(10.0, Umbral)),
    ?assertEqual(critico, medidor:clasificar(12.0, Umbral)).

%% Prueba de calculo de kWh
calcular_kwh_test() ->
    % 6 kW durante 1800 segundos (30 minutos) = 3 kWh
    T1 = 1000,
    T2 = 1000 + 1800,
    KWh = medidor:calcular_kwh(6.0, T1, T2),
    ?assertEqual(3.0, KWh).

%% Prueba de agregacion por_piso/1
por_piso_test() ->
    Estados = [
        #{piso => 1, id => 1, kw => 5.0, kwh => 10.0, umbral => 10.0, estado => normal},
        #{piso => 1, id => 2, kw => 3.0, kwh => 8.0, umbral => 10.0, estado => normal},
        #{piso => 2, id => 1, kw => 7.0, kwh => 15.0, umbral => 10.0, estado => normal}
    ],
    Resultado = energia_datos:por_piso(Estados),
    ?assertEqual(2, length(Resultado)),
    
    [Piso1, Piso2] = Resultado,
    ?assertEqual(1, maps:get(piso, Piso1)),
    ?assertEqual(8.0, maps:get(total_kw, Piso1)),
    ?assertEqual(18.0, maps:get(total_kwh, Piso1)),
    
    ?assertEqual(2, maps:get(piso, Piso2)),
    ?assertEqual(7.0, maps:get(total_kw, Piso2)),
    ?assertEqual(15.0, maps:get(total_kwh, Piso2)).

%% Prueba de filtrado de alarmas/1
alarmas_test() ->
    Estados = [
        #{piso => 1, id => 1, kw => 5.0, kwh => 10.0, umbral => 10.0, estado => normal},
        #{piso => 1, id => 2, kw => 8.5, kwh => 8.0, umbral => 10.0, estado => alerta},
        #{piso => 2, id => 1, kw => 11.0, kwh => 15.0, umbral => 10.0, estado => critico}
    ],
    Alarmas = energia_datos:alarmas(Estados),
    ?assertEqual(2, length(Alarmas)),
    
    % Verificar que solo tiene alerta y critico
    Estados2 = lists:map(fun(A) -> maps:get(estado, A) end, Alarmas),
    ?assert(lists:member(alerta, Estados2)),
    ?assert(lists:member(critico, Estados2)),
    ?assertNot(lists:member(normal, Estados2)).

%% Prueba de recuperacion de supervisor
recuperacion_test_() ->
    {setup,
     fun setup_test_app/0,
     fun cleanup_test_app/1,
     fun(_) ->
         [
             {"Medidor se recupera tras fallo", fun test_recuperacion/0}
         ]
     end}.

setup_test_app() ->
    % Configurar las variables de entorno antes de iniciar la app
    application:load(energia),
    application:set_env(energia, pisos, 2),
    application:set_env(energia, medidores_por_piso, 3),
    application:set_env(energia, umbral_kw, 10.0),
    application:set_env(energia, intervalo_ms, 2000),
    application:set_env(energia, puerto, 8080),
    application:ensure_all_started(energia),
    ok.

cleanup_test_app(_) ->
    application:stop(energia),
    ok.

test_recuperacion() ->
    % Obtener PIDs de dos medidores
    Pid1_antes = whereis(medidor:nombre(1, 1)),
    Pid2_antes = whereis(medidor:nombre(1, 2)),
    
    ?assert(is_pid(Pid1_antes)),
    ?assert(is_pid(Pid2_antes)),
    
    % Matar el primer medidor
    exit(Pid1_antes, kill),
    
    % Esperar a que se recupere
    timer:sleep(100),
    
    % Verificar que el medidor 1 tiene un nuevo PID
    Pid1_despues = whereis(medidor:nombre(1, 1)),
    ?assert(is_pid(Pid1_despues)),
    ?assertNot(Pid1_antes == Pid1_despues),
    
    % Verificar que el medidor 2 conserva su PID (one_for_one)
    Pid2_despues = whereis(medidor:nombre(1, 2)),
    ?assertEqual(Pid2_antes, Pid2_despues).
