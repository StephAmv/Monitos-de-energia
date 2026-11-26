# #8 Monitor de energía — Gemelo digital (Prolog)

**Autora:** Stephanie Ariana Medrano Vargas (23212013)  
**Materia:** Programación Lógica y Funcional  
**Fecha:** Noviembre 25, 2026

## Qué es

Gemelo digital de un edificio de 3 pisos con 7 medidores de energía en 2 buses RS-485. Razona sobre:
- Proyección de demanda máxima y alarmas anticipadas
- Contadores que reinician o se desbordan
- Medidores lentos que retrasan a sus víctimas
- Caídas de voltaje (red vs motores propios)
- Reparto de consumo entre áreas con medidor compartido

**Diferencia del simulador Erlang:** El Erlang simula procesos concurrentes (un `gen_server` por medidor) y tolerancia a fallas. El Prolog razona sobre hechos ya observados: deduce, explica y distingue "no sé" de "no". El Erlang genera las lecturas; el Prolog decide qué significan.

## Requisitos

- SWI-Prolog 9.x

## Cómo correr

```bash
# Pruebas
swipl -g run_tests -t halt tests/reglas_tests.pl

# Servidor (puerto 8080)
swipl servidor.pl

# Servidor en otro puerto
swipl servidor.pl 9000

# Probar la API
./probar_api.sh
```

## Situaciones y predicados

| Escenario | Decisión | Predicado | Prueba |
|---|---|---|---|
| s0_normal | Ninguna alarma | `alarma_demanda/4` | base |
| s1a | Pico breve, no rebasa | `proyeccion/4` | situacion1 |
| s1b | Alarma anticipada, diferir compresor | `diferir/3` | situacion1 |
| s2 | Contador reiniciado, consumo entre valores | `consumo_medidor/4` | situacion2 |
| s3 | p1_general lento, víctimas: motores y alumbrado | `causante_bus/3`, `victima/2` | situacion3 |
| s4a/b/c | Caída de voltaje: red, motores, o no sé | `causa_caida/5` | situacion4 |
| s5 | Reparto laboratorio/oficinas | `reparto_energia/4`, `reparto_demanda/5` | situacion5 |

## Las 5 preguntas

| Pregunta | Consulta |
|---|---|
| ¿Qué hago con la ventana ahora? | `decide(ventana, D, E)` |
| ¿Por qué no me avisa del medidor de motores? | `decide(p1_motores, D, E)` |
| ¿Cuáles lecturas están viejas por culpa del bus? | `findall(M, situacion(M, lectura_atrasada, _), L)` |
| ¿Qué tendría que cambiar para que no haya alarma? | `que_falta(ventana, C)` |
| ¿Qué pasaría si el compresor arranca 10 min después? | `hipotesis(mover(compresor, 600), ventana, D, E)` |

## Arquitectura

- **Todo en Prolog**: hechos, reglas, explicación y servidor web
- **Ninguna decisión fuera de Prolog**: la interfaz solo consulta y muestra
- **El "ahora" es un hecho**: no hay `get_time` ni `random`
- **Tres resultados**: `si`, `no`, `no_se` (nunca `no_se` → `no`)
- **Bibliotecas estándar**: plunit, lists, aggregate, apply, http

Ver [SUPUESTOS.md](SUPUESTOS.md) para valores y decisiones.

## Respuestas a las preguntas guía

1. **¿Qué hechos necesitas para describir un medidor y su lugar en el bus en un instante?**  
   `medidor/4` (nombre, lugar, bus, turno), `lectura/4` (medidor, variable, valor, segundo), `consulta/4` (medidor, resultado, ms, segundo), `ahora/1`.

2. **¿Dónde queda escrito cuál gana cuando dos reglas chocan?**  
   En `motor/4` (prioridad), `diferir/3` (prueba de menor a mayor prioridad) y `decide/3` (orden de cláusulas).

3. **¿Cómo distingue "no hay alarma" de "no tengo lectura fresca para saberlo"?**  
   `fresca/3` retorna `si | no | no_se`; `alarma_demanda/4` retorna `ninguna | anticipada | vigente | no_puedo_decir` con `Certeza = firme | estimacion | no_se`.

4. **¿Qué parte de la explicación le sirve al administrador y qué parte es ruido?**  
   Sirve: qué motor diferir, hasta cuándo, a quién falla. Ruido: valores intermedios de cálculo. La API traduce a texto.

5. **¿Qué parte del simulador Erlang podría alimentar a este gemelo?**  
   Cada lectura de un proceso `medidor` → `assertz(lectura(...))`. Cada timeout → `assertz(consulta(..., timeout, ...))`. Los hechos dinámicos del gemelo vienen de los mensajes del Erlang.

## Erlang vs Prolog

En **Erlang** resolví la concurrencia y la tolerancia a fallas: un `gen_server` por medidor bajo supervisores `one_for_one`, un simulador, recuperación tras falla y la API en Cowboy, porque son procesos vivos que fallan y se reinician.

En **Prolog** resolví el razonamiento: proyectar la ventana, distinguir causante de víctima, diagnosticar la caída, repartir con una política explícita y decir "no sé", porque son relaciones entre hechos que se consultan en cualquier dirección y se explican.

Lo que el Erlang podría aportar al gemelo: las lecturas y los timeouts de cada proceso `medidor` se pueden exportar como hechos `lectura/4` y `consulta/4`.
