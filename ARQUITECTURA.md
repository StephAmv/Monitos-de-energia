# Arquitectura del Sistema

## Arbol de Supervision

```
energia_sup (one_for_one)
│
├─── medidor_sup (one_for_one)
│    ├─── medidor (gen_server) - Piso 1, Medidor 1
│    ├─── medidor (gen_server) - Piso 1, Medidor 2
│    ├─── medidor (gen_server) - Piso 1, Medidor 3
│    ├─── medidor (gen_server) - Piso 2, Medidor 1
│    ├─── medidor (gen_server) - Piso 2, Medidor 2
│    └─── medidor (gen_server) - Piso 2, Medidor 3
│
└─── simulador (gen_server)
```

## Modulos

### Procesos (gen_server)

1. **medidor** (`src/medidor.erl`)
   - Estado: piso, id, kW actual, kWh acumulado, umbral
   - Registrado como: `medidor_p1_m1`, `medidor_p1_m2`, etc.
   - Recibe lecturas via `gen_server:cast`
   - Acumula consumo en kWh
   - Funciones puras: `clasificar/2`, `calcular_kwh/3`

2. **simulador** (`src/simulador.erl`)
   - Genera lecturas aleatorias cada `intervalo_ms`
   - Cada medidor tiene consumo base distinto
   - Funcion `pico/2` para simular sobrecarga

### Supervisores

3. **medidor_sup** (`src/medidor_sup.erl`)
   - Estrategia: `one_for_one`
   - Crea un hijo por cada medidor configurado
   - Reinicia medidores individuales si fallan

4. **energia_sup** (`src/energia_sup.erl`)
   - Supervisor raiz
   - Estrategia: `one_for_one`
   - Hijos: medidor_sup y simulador

### Logica de Negocio (funciones puras)

5. **energia_datos** (`src/energia_datos.erl`)
   - `por_piso/1`: Agrupa y suma kW/kWh por piso
   - `alarmas/1`: Filtra medidores en alerta/critico
   - `edificio_completo/0`: Obtiene estado completo

### Aplicacion y HTTP

6. **energia_app** (`src/energia_app.erl`)
   - Callback de application
   - Inicia Cowboy con rutas
   - Inicia arbol de supervision

7. **energia_http** (`src/energia_http.erl`)
   - Handler de Cowboy
   - Rutas:
     - `GET /api/edificio`
     - `POST /api/demo/pico/:piso/:medidor`
     - `POST /api/demo/falla/:piso/:medidor`
     - `GET /` y `/static/[...]`

## Flujo de Datos

```
simulador (cada 2 seg)
    |
    | gen_server:cast({lectura, KW})
    v
medidor (acumula kWh)
    |
    | medidor:estado/2
    v
energia_datos (agrega por piso)
    |
    | edificio_completo/0
    v
energia_http (JSON)
    |
    v
Cliente HTTP / Navegador
```

## Clasificacion de Estados

- **normal**: KW < 80% del umbral
- **alerta**: KW >= 80% y < 100% del umbral
- **critico**: KW >= 100% del umbral

## Calculo de kWh

```
kWh_incremento = KW * (segundos_transcurridos / 3600)
kWh_acumulado = kWh_anterior + kWh_incremento
```

## Recuperacion de Fallos

- Si un medidor falla (exit, crash), el supervisor lo reinicia
- Estado inicial: kW=0, kWh=0 (se pierde estado anterior)
- Otros medidores NO se afectan (estrategia one_for_one)
- En produccion se usaria persistencia (Mnesia, ETS con dets, etc.)
