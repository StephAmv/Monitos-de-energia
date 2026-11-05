# Monitor de Energia de Edificio

## Informacion del Proyecto

- **Asignatura**: [COMPLETAR]
- **Alumno**: Stephanie Ariana Medrano Vargas - 23212013
- **Fecha**: [COMPLETAR]
- **Proyecto**: #8 - Monitor de Energia (tectijuana/erlang-proyectos)

## Descripcion

Sistema de monitoreo de consumo energetico para edificios implementado en Erlang/OTP 27. Permite supervisar en tiempo real el consumo de multiples medidores distribuidos por piso, clasificar su estado segun umbrales configurables, y simular condiciones de sobrecarga o falla para demostrar la recuperacion automatica del sistema.

El proyecto implementa patrones de supervision OTP con procesos aislados para cada medidor, un simulador que genera lecturas aleatorias, y una API REST con interfaz web para visualizacion y control.

## Como Funciona

### Procesos

El sistema esta compuesto por los siguientes procesos bajo supervision:

- **energia_sup**: Supervisor raiz (estrategia `one_for_one`)
- **medidor_sup**: Supervisor de medidores (estrategia `one_for_one`)
- **medidor**: Un proceso gen_server por cada medidor (6 por defecto: 2 pisos x 3 medidores)
  - Registrado como `medidor_p1_m1`, `medidor_p1_m2`, etc.
  - Estado: piso, id, kW actual, kWh acumulado, umbral, timestamp de ultima lectura
  - Recibe lecturas via `gen_server:cast({lectura, KW})`
  - Calcula kWh incrementales: `KW * (segundos / 3600)`
- **simulador**: Proceso gen_server que genera lecturas cada 2 segundos
  - Envia valores aleatorios alrededor de un consumo base por medidor
  - Permite simular picos de sobrecarga con `simulador:pico(Piso, Id)`

### Supervision

La jerarquia de supervision asegura que si un medidor falla:
- El supervisor lo reinicia automaticamente
- Los demas medidores no se ven afectados (estrategia `one_for_one`)
- El proceso vuelve con estado inicial (kW=0, kWh=0)

### Estados: Normal, Alerta, Critico

Cada medidor clasifica su consumo actual segun el umbral configurado:

- **normal**: KW < 80% del umbral (ej: < 8.0 kW si umbral es 10.0)
- **alerta**: KW >= 80% y < 100% del umbral (8.0-9.9 kW)
- **critico**: KW >= 100% del umbral (>= 10.0 kW)

La clasificacion se hace en la funcion pura `medidor:clasificar(KW, Umbral)`.

### Simulador

El simulador:
1. Lee configuracion: pisos, medidores por piso, intervalo, umbral
2. Cada `intervalo_ms` (2000 ms por defecto) envia lecturas a todos los medidores
3. Genera valores aleatorios con ruido: `Base + (rand:uniform() - 0.5) * 2.0`
4. Cada medidor tiene un consumo base distinto (40-70% del umbral)
5. Cuando se activa un pico via `simulador:pico(Piso, Id)`:
   - Durante 5 ciclos (~10 segundos) el medidor recibe valores sobre el umbral
   - Esto provoca estado critico y aparicion en alarmas

## Requisitos

- Erlang/OTP 27
- Rebar3

## Compilar, Probar y Ejecutar

### Compilar

```bash
rebar3 compile
```

### Ejecutar Pruebas

```bash
rebar3 eunit
```

El proyecto incluye 7 pruebas unitarias:
- `clasificar_normal_test`: Verifica clasificacion normal
- `clasificar_alerta_test`: Verifica clasificacion alerta
- `clasificar_critico_test`: Verifica clasificacion critico
- `calcular_kwh_test`: Verifica calculo de kWh (6 kW x 1800s = 3 kWh)
- `por_piso_test`: Verifica agregacion de consumo por piso
- `alarmas_test`: Verifica filtrado de alarmas
- `recuperacion_test`: Verifica que medidores se recuperan tras falla

### Ejecutar

```bash
rebar3 shell
```

La aplicacion arranca automaticamente y el servidor HTTP queda disponible en `http://localhost:8080`.

## Endpoints de la API

| Metodo | Endpoint                          | Descripcion                                      |
|--------|-----------------------------------|--------------------------------------------------|
| GET    | /api/edificio                     | Estado completo: totales, pisos, alarmas, medidores |
| POST   | /api/demo/pico/:piso/:medidor     | Simula pico de consumo en medidor especificado   |
| POST   | /api/demo/falla/:piso/:medidor    | Mata proceso del medidor (se recupera via supervisor) |
| GET    | /                                 | Interfaz web HTML                                |
| GET    | /static/app.js                    | JavaScript de la interfaz                        |

### Respuesta de /api/edificio

```json
{
  "total_kw": 28.5,
  "total_kwh": 45.3,
  "pisos": [
    {"piso": 1, "total_kw": 15.2, "total_kwh": 22.1},
    {"piso": 2, "total_kw": 13.3, "total_kwh": 23.2}
  ],
  "alarmas": [
    {"piso": 1, "id": 2, "kw": 10.5, "kwh": 8.2, "umbral": 10.0, "estado": "critico"}
  ],
  "medidores": [
    {"piso": 1, "id": 1, "kw": 4.7, "kwh": 7.3, "umbral": 10.0, "estado": "normal"},
    ...
  ]
}
```

## Estructura de Carpetas

```
monitor-energia/
├── AGENTS.md              # Reglas del proyecto
├── README.md              # Este archivo
├── rebar.config           # Configuracion de Rebar3
├── config/
│   ├── sys.config         # Configuracion de la aplicacion
│   └── test.config        # Configuracion para pruebas
├── src/
│   ├── energia.app.src    # Descriptor de aplicacion OTP
│   ├── energia_app.erl    # Callback de application
│   ├── energia_sup.erl    # Supervisor raiz
│   ├── medidor_sup.erl    # Supervisor de medidores
│   ├── medidor.erl        # Gen_server de medidor
│   ├── simulador.erl      # Gen_server simulador
│   ├── energia_datos.erl  # Funciones puras de agregacion
│   └── energia_http.erl   # Handler HTTP para Cowboy
├── priv/
│   └── static/
│       ├── index.html     # Interfaz web
│       └── app.js         # JavaScript de la interfaz
├── test/
│   └── energia_tests.erl  # Pruebas EUnit
└── docs/
    ├── manual-gist.md     # Manual de usuario
    └── investigacion.md   # Documento de investigacion
```

## Configuracion

El archivo `config/sys.config` permite configurar:

```erlang
[
  {energia, [
    {pisos, 2},                    % Numero de pisos
    {medidores_por_piso, 3},       % Medidores por piso
    {umbral_kw, 10.0},             % Umbral en kW
    {intervalo_ms, 2000},          % Intervalo de simulacion en ms
    {puerto, 8080}                 % Puerto HTTP
  ]}
].
```

## Evidencias

### Compilacion y Pruebas

[COMPLETAR: captura de `rebar3 compile` sin warnings]

[COMPLETAR: captura de `rebar3 eunit` con 7 tests, 0 failures]

### Ejecucion

[COMPLETAR: captura de `rebar3 shell` mostrando arranque exitoso]

### Interfaz Web

[COMPLETAR: captura de http://localhost:8080 mostrando dashboard completo]

[COMPLETAR: captura de seccion de totales con valores actualizandose]

[COMPLETAR: captura de tarjetas de medidores con estados normal/alerta/critico]

[COMPLETAR: captura de seccion de alarmas con medidores en estado critico]

### Simulacion de Pico

[COMPLETAR: captura de boton "Simular pico" siendo presionado]

[COMPLETAR: captura de medidor cambiando a estado critico tras simular pico]

[COMPLETAR: captura de alarma apareciendo en la lista]

### Simulacion de Falla

[COMPLETAR: captura de boton "Simular falla" siendo presionado]

[COMPLETAR: captura de medidor recuperandose automaticamente]

### Pruebas con curl

[COMPLETAR: captura de `curl http://localhost:8080/api/edificio | jq`]

[COMPLETAR: captura de `curl -X POST http://localhost:8080/api/demo/pico/1/2`]

## Declaracion de Uso de IA

| Aspecto           | Detalle                                          |
|-------------------|--------------------------------------------------|
| Agente de IA      | [COMPLETAR]                                      |
| Modelos usados    | [COMPLETAR]                                      |
| Que hizo la IA    | [COMPLETAR]                                      |
| Que hice yo       | [COMPLETAR]                                      |

## Referencias

- [Erlang/OTP Design Principles](https://www.erlang.org/doc/design_principles/des_princ)
- [Cowboy 2.12 User Guide](https://ninenines.eu/docs/en/cowboy/2.12/guide/)
- [Rebar3 Documentation](https://rebar3.org/docs/)
- [tectijuana/erlang-proyectos](https://github.com/tectijuana/erlang-proyectos)
