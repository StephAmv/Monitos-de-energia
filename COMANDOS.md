# Comandos Utiles

## Desarrollo

```bash
# Compilar
rebar3 compile

# Ejecutar pruebas
rebar3 eunit

# Iniciar shell interactivo
rebar3 shell

# Limpiar
rebar3 clean
```

## Durante rebar3 shell

```erlang
% Ver estado del edificio
energia_datos:edificio_completo().

% Ver estado de un medidor especifico
medidor:estado(1, 1).

% Provocar un pico de consumo en piso 1, medidor 2
simulador:pico(1, 2).

% Matar un medidor para probar recuperacion
exit(whereis(medidor:nombre(1, 1)), kill).

% Verificar que se recupero
whereis(medidor:nombre(1, 1)).
```

## Probar API REST

```bash
# Estado del edificio
curl http://localhost:8080/api/edificio | jq

# Provocar pico
curl -X POST http://localhost:8080/api/demo/pico/1/2

# Provocar falla
curl -X POST http://localhost:8080/api/demo/falla/1/1

# Ver interfaz web
open http://localhost:8080
# o
xdg-open http://localhost:8080
```

## Configuracion

Editar `config/sys.config` para cambiar:
- Numero de pisos
- Medidores por piso
- Umbral de consumo
- Intervalo de simulacion
- Puerto HTTP
