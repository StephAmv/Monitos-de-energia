# Investigacion - Monitor de Energia con Erlang/OTP

## Problema

Los sistemas de monitoreo de energia en edificios requieren alta disponibilidad y capacidad para manejar multiples medidores simultaneamente sin que la falla de uno afecte a los demas. Los enfoques tradicionales con hilos o procesos pesados presentan problemas de escalabilidad y recuperacion ante fallos. Se necesita un sistema que pueda:

- Monitorear multiples medidores concurrentemente
- Clasificar consumo en tiempo real (normal/alerta/critico)
- Recuperarse automaticamente de fallos
- Calcular consumo acumulado (kWh) sin perder precision
- Proveer una API para visualizacion

## Conceptos

### kW vs kWh

- **kW (kilovatio)**: Unidad de potencia instantanea. Mide la cantidad de energia que un dispositivo consume en un momento dado. Ejemplo: un aire acondicionado de 2 kW.

- **kWh (kilovatio-hora)**: Unidad de energia acumulada. Mide el consumo total durante un periodo. Se calcula multiplicando la potencia por el tiempo. Formula: `kWh = kW * horas`. Ejemplo: un dispositivo de 2 kW funcionando 3 horas consume 6 kWh.

En este proyecto:
- `kW` es el consumo instantaneo actual del medidor
- `kWh` es el consumo acumulado desde que el medidor inicio
- Se calcula incrementalmente: `kWh_nuevo = kWh_anterior + (kW * segundos / 3600)`

### Umbral

Limite de consumo configurado por medidor. Se usa para clasificar el estado:
- Si consumo < 80% del umbral: estado normal
- Si consumo >= 80% y < 100%: estado alerta
- Si consumo >= 100%: estado critico

Ejemplo: Umbral de 10.0 kW → Alerta a partir de 8.0 kW, Critico desde 10.0 kW.

## Por que Erlang/OTP

### Procesos Ligeros

Erlang permite crear millones de procesos ligeros (no hilos del OS) con overhead minimo (~300 bytes cada uno). Cada medidor corre en su propio proceso, permitiendo escalabilidad: 6 medidores, 60, o 6000 sin cambiar el diseño.

### Aislamiento

Los procesos no comparten memoria. Un error en un medidor (division por cero, lectura invalida) no afecta a otros. El estado de cada medidor esta encapsulado en su proceso.

### Supervision

Los supervisores (behavior `supervisor`) monitoran procesos hijos y los reinician automaticamente si fallan. Estrategia `one_for_one`: si un medidor falla, solo ese medidor se reinicia, los demas continuan normales.

### "Let it Crash"

Filosofia de Erlang: no defenderse de todos los errores posibles, sino dejar que el proceso falle y que el supervisor lo reinicie en estado limpio. Simplifica el codigo (menos try-catch) y garantiza recuperacion automatica.

## Arquitectura

### Arbol de Supervision

```
energia_sup (one_for_one)
|
+-- medidor_sup (one_for_one)
|   |
|   +-- medidor (gen_server) - Piso 1, Medidor 1
|   +-- medidor (gen_server) - Piso 1, Medidor 2
|   +-- medidor (gen_server) - Piso 1, Medidor 3
|   +-- medidor (gen_server) - Piso 2, Medidor 1
|   +-- medidor (gen_server) - Piso 2, Medidor 2
|   +-- medidor (gen_server) - Piso 2, Medidor 3
|
+-- simulador (gen_server)
```

- **energia_sup**: Raiz. Si medidor_sup falla, se reinicia completo. Si simulador falla, solo el se reinicia.
- **medidor_sup**: Crea y supervisa todos los medidores. Si uno falla, reinicia solo ese.
- **medidor**: Proceso individual. Mantiene estado (kW, kWh, umbral). Registrado con nombre global.
- **simulador**: Genera lecturas aleatorias periodicamente. Envia `gen_server:cast` a cada medidor.

### Modulos

- `energia_app.erl`: Application callback. Inicia Cowboy y el arbol de supervision.
- `energia_sup.erl`: Supervisor raiz. Define hijos: medidor_sup y simulador.
- `medidor_sup.erl`: Supervisor dinamico. Crea un hijo por cada medidor configurado.
- `medidor.erl`: Gen_server. API: `estado/2`, `nombre/2`. Funciones puras: `clasificar/2`, `calcular_kwh/3`.
- `simulador.erl`: Gen_server. API: `pico/2`. Usa `erlang:send_after` para ticks periodicos.
- `energia_datos.erl`: Funciones puras de agregacion: `por_piso/1`, `alarmas/1`, `edificio_completo/0`.
- `energia_http.erl`: Handler de Cowboy. Rutas: `/api/edificio`, `/api/demo/pico/:piso/:medidor`, `/api/demo/falla/:piso/:medidor`.

## Decisiones de Diseno

### Un Proceso por Medidor

Alternativa: Un proceso con lista de medidores. Rechazada porque:
- Un error afectaria todos los medidores
- No aprovechar concurrencia de Erlang
- Dificil reiniciar medidores individuales

Ventaja del diseño actual: Aislamiento total, supervision granular.

### Calculo al Consultar sin ETS

Los totales por piso y alarmas se calculan en cada peticion GET consultando todos los medidores. No se usa ETS ni proceso agregador. Razon:
- Simplicidad del codigo
- 6 medidores = overhead despreciable
- Estado siempre consistente (no hay cache desactualizado)

Desventaja: No escala a miles de medidores. Para produccion, usar ETS o proceso agregador que actualice totales incrementalmente.

### Simulador con Consumo Base Variable

Cada medidor tiene consumo base distinto calculado por: `Factor = 0.4 + (Semilla rem 30) / 100.0` donde `Semilla = Piso * 100 + Id`. Esto genera valores entre 40% y 70% del umbral. Razon: Simular medidores con cargas distintas (iluminacion vs equipos pesados).

### Pico de 5 Ciclos

Cuando se activa `simulador:pico(Piso, Id)`, el pico dura 5 ciclos (5 * 2 segundos = 10 segundos). Razon: Tiempo suficiente para observar en interfaz, pero no tan largo que aburra al usuario.

## Limitaciones y Trabajo Futuro

### Limitaciones

1. **Sin historico**: Los datos de kWh se pierden si un medidor falla. No hay persistencia.
2. **Sin distribucion**: Todo corre en un nodo. No se aprovecha capacidad de Erlang para sistemas distribuidos.
3. **Sin autenticacion**: La API es publica. Cualquiera puede ver datos o provocar fallos.
4. **Datos simulados**: No hay conexion con medidores reales. Solo para demostracion.
5. **Calculo lineal**: Se asume consumo constante entre lecturas. En realidad, el consumo varia.
6. **Sin graficas**: La interfaz web no incluye graficos historicos de tendencias.

### Trabajo Futuro

1. **Persistencia con Mnesia**: Base de datos distribuida de Erlang. Almacenar kWh acumulado, historico de lecturas, eventos de alarmas.

2. **Cluster de nodos**: Distribuir medidores entre multiples nodos. Si un nodo falla, los medidores se migran a otro nodo automaticamente.

3. **Autenticacion**: Agregar tokens JWT o autenticacion basica. Solo usuarios autorizados pueden ver datos o ejecutar comandos.

4. **Integracion con hardware real**: Usar protocolos como Modbus, MQTT, o APIs de medidores IoT para obtener lecturas reales.

5. **Graficas historicas**: Agregar Chart.js o similar para mostrar tendencias de consumo por hora/dia/mes.

6. **Notificaciones**: Enviar emails o webhooks cuando un medidor entra en estado critico.

7. **Prediccion**: Usar machine learning para predecir consumo futuro y alertar antes de exceder umbral.

8. **Optimizacion**: Usar ETS para cachear totales. Agregar indices. Implementar proceso agregador que calcule totales solo cuando cambian.

## Referencias

1. **Erlang/OTP Design Principles**  
   https://www.erlang.org/doc/design_principles/des_princ  
   Documentacion oficial de patrones de diseño OTP: supervisores, gen_server, aplicaciones.

2. **Cowboy User Guide**  
   https://ninenines.eu/docs/en/cowboy/2.12/guide/  
   Servidor HTTP usado en el proyecto. Explica routing, handlers, y manejo de requests.

3. **Armstrong, J. (2003). Making reliable distributed systems in the presence of software errors. PhD thesis, Royal Institute of Technology, Stockholm.**  
   Tesis doctoral de Joe Armstrong (creador de Erlang) sobre diseño de sistemas tolerantes a fallos.

4. **Erlang/OTP json module**  
   https://www.erlang.org/doc/apps/stdlib/json  
   Modulo nativo de OTP 27 para encoding/decoding JSON usado en la API.

5. **Supervisor Behaviour**  
   https://www.erlang.org/doc/man/supervisor  
   Documentacion del behavior supervisor: estrategias (one_for_one, rest_for_one, etc.), configuracion.

6. **Gen_server Behaviour**  
   https://www.erlang.org/doc/man/gen_server  
   Documentacion del behavior gen_server: callbacks (init, handle_call, handle_cast), estado, timeouts.

7. **Learn You Some Erlang for Great Good!**  
   https://learnyousomeerlang.com/  
   Tutorial completo de Erlang con capitulos sobre OTP, supervisores, y diseño de aplicaciones.
