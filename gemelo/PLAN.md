# PLAN.md — Gemelo digital #8 Monitor de energía (SWI-Prolog)

> **Para el agente (OpenCode).** Este documento es la especificación completa del gemelo.
> Lo escribió la alumna, Stephanie Ariana Medrano Vargas (23212013), con todas sus
> decisiones ya tomadas: los supuestos están fijados y **cada regla ya está redactada en
> español por ella** (eso cumple el "pide al estudiante que la diga en español" de
> `CONTEXTO_AGENTES.md`).
>
> **Modo de trabajo autorizado por la alumna:**
> - **No hagas preguntas.** Implementa todo, fase por fase, sin detenerte entre fases.
> - Si algo es ambiguo, elige la opción más simple que cumpla `CONTEXTO_AGENTES.md`,
>   anótala en `SUPUESTOS.md`, sección "Decisiones tomadas durante la implementación", y sigue.
> - Mantén el orden "prueba primero, regla después" dentro de cada fase.
> - Al terminar cada fase: ejecuta las pruebas, corrige hasta que todo esté en verde y haz
>   `git add -A && git commit -m "gemelo: fase N - <tema>"`.
> - Nunca afirmes que algo pasa si no lo ejecutaste.
> - Lee también `CONTEXTO_AGENTES.md` y `PROBLEMA.md` (en esta carpeta). Si chocan con
>   este plan, manda `CONTEXTO_AGENTES.md` en lo de **arquitectura**. En **valores y
>   reglas** manda este plan.

---

## 1. Reglas de arquitectura (obligatorias)

- Todo en **SWI-Prolog**: hechos, reglas, explicación y servidor web (`library(http/thread_httpd)`, `http_dispatch`, `http_json`, `http_parameters`, `http_files`). El JSON va solo bajo `/api/`.
- **Ninguna decisión del dominio fuera de Prolog.** `web/app.js` solo hace `fetch` y pinta. Los colores salen de campos de estado que manda Prolog, nunca de comparar números en JS.
- Prohibido usar `get_time`, `random` o la fecha del sistema en las reglas. El instante actual es el hecho `ahora/1`.
- Solo bibliotecas estándar: `plunit`, `lists`, `aggregate`, `apply`, `clpfd`, `http`, `solution_sequences`, `yall`.
- No se modifica nada fuera de `gemelo/` (el código Erlang de `../src` no se toca).
- Nombres de predicados y comentarios en **español sin acentos ni eñe**. El texto que ve el usuario en el JSON y en la web sí lleva acentos.
- Un comentario de una línea con modos (`+ - ?`) antes de cada predicado exportado.
- Toda condición tiene **tres resultados**: `si`, `no` o `no_se`. `no_se` nunca se convierte en `no`.
- Código simple: es un proyecto escolar individual, sin sobrediseño.
- Para comparar flotantes en las pruebas usa una tolerancia de 0.01.

## 2. Estructura de archivos

```
gemelo/
├── PLAN.md  CONTEXTO_AGENTES.md  PROBLEMA.md  PROBLEMA_ORIGINAL.md
├── AGENTS.md              (fase 0)
├── SUPUESTOS.md           (fase 0)
├── README.md              (fase 9)
├── hechos.pl              edificio estático + dynamic + cargar_escenario/1
├── escenarios/            s0_normal.pl s1a.pl s1b.pl s2.pl s3.pl s4a.pl s4b.pl s4c.pl s5.pl
├── reglas.pl              todas las reglas (module reglas)
├── servidor.pl            HTTP <-> consultas
├── probar_api.sh
├── tests/reglas_tests.pl
├── web/                   index.html app.js estilos.css
├── design/                export de Google Stitch (si existe)
└── docs/                  manual-gist.md uso-ia.md guion-demo.md
```

Comandos de verificación:
```bash
swipl -g run_tests -t halt tests/reglas_tests.pl
swipl servidor.pl          # puerto 8080; también: swipl servidor.pl 9000
```

## 3. Supuestos (fijos, decididos por la alumna)

| Concepto | Valor | Origen |
|---|---|---|
| Límite de demanda del edificio | 40 kW (promedio de la ventana) | supuesto |
| Ventana de demanda | fija, 900 s, alineada a :00/:15/:30/:45 | 15 min = original; fija = supuesto |
| Medidor que mide la demanda del edificio | `acometida` | supuesto |
| Motores | bomba 7.5 kW, compresor 11 kW, extractor 3.7 kW | supuesto |
| Prioridad (1 = más importante) | bomba 1 (agua del edificio), extractor 2 (seguridad del taller), compresor 3 (puede esperar) | supuesto |
| Ciclo de consulta | 5 s | original |
| Timeout | 1000 ms | supuesto |
| Medidor lento | ≥ 2 de sus últimas 3 consultas con resultado `ok` y > 500 ms (los timeouts NO cuentan para "lento") | supuesto |
| Lectura vieja | edad > 15 s respecto a `ahora/1` | supuesto |
| Voltaje bajo | < 114 V (≈ 90 % de 127 V) | 127 V = original; 90 % = supuesto |
| Máximo del contador | 99999.9 kWh | supuesto |
| Margen para desbordamiento | el anterior estaba a menos del 1 % del máximo (≥ 98999.9) | supuesto |
| Lectura hueca en la ventana | se rellena con el último valor conocido y la certeza baja a `estimacion` | supuesto |
| Horario oficinas | 08:00–18:00 (28800–64800 s) | supuesto |
| Horario laboratorio | uso 08:00–20:00 (28800–72000 s) + base 24 h | supuesto |
| Horario aulas | 07:00–22:00 (25200–79200 s) | supuesto |
| Equipos 24 h del laboratorio | 1.5 kW (refrigerador y servidor) | supuesto |
| Tolerancia nocturna | base × 1.2 = 1.8 kW | supuesto |
| Carga declarada (parte variable en horario de oficinas) | laboratorio 0.3 / oficinas 0.7 (oficinas = clima y computadoras; los equipos fijos del lab ya van en la base) | supuesto |
| Penalización por FP < 0.90 | se reparte igual que el cargo por demanda | 0.90 = original; reparto = supuesto |
| Cifras del original | 127 V / 220 V a 60 Hz, ventana de 15 min, FP 0.90, RS-485 a 9600 baud con respuestas de decenas de ms, consulta cada 5 s, horizonte de 24 h, 30 medidores en 3 buses (aquí se reduce a 7 en 2) | original |

## 4. Hechos del edificio (`hechos.pl`)

Usa **exactamente** el vocabulario de `CONTEXTO_AGENTES.md`. Se pueden añadir predicados, pero no renombrar los existentes.

```prolog
medidor(acometida,     acometida, bus_a, 1).
medidor(p1_general,    piso1,     bus_a, 2).
medidor(p1_motores,    piso1,     bus_a, 3).
medidor(p1_alumbrado,  piso1,     bus_a, 4).
medidor(p2_general,    piso2,     bus_b, 1).
medidor(p2_compartido, piso2,     bus_b, 2).
medidor(p3_aulas,      piso3,     bus_b, 3).

cuelga_de(p1_general, acometida).   cuelga_de(p2_general, acometida).
cuelga_de(p3_aulas, acometida).     cuelga_de(p1_motores, p1_general).
cuelga_de(p1_alumbrado, p1_general). cuelga_de(p2_compartido, p2_general).

area(taller, p1_motores). area(taller, p1_alumbrado).
area(laboratorio, p2_compartido). area(oficinas, p2_compartido).
area(aulas, p3_aulas).

piso_tiene_motores(piso1).
motor(bomba, p1_motores, 7.5, 1).
motor(extractor, p1_motores, 3.7, 2).
motor(compresor, p1_motores, 11.0, 3).
equipo_base(laboratorio, 1.5).
carga_declarada(laboratorio, 0.3).
carga_declarada(oficinas, 0.7).
horario(oficinas, 28800, 64800).
horario(laboratorio, 28800, 72000).
horario(aulas, 25200, 79200).

limite(demanda, 40.0).        limite(ventana_s, 900).
limite(ciclo_s, 5).           limite(ms_timeout, 1000).
limite(ms_lento, 500).        limite(vieja_s, 15).
limite(voltaje_bajo, 114.0).  limite(max_contador, 99999.9).
limite(fp_minimo, 0.90).      limite(tolerancia_nocturna, 1.2).
```

Incluye también `rango/3` razonables (v 0–260, kw 0–200, kvar 0–200, kwh 0–99999.9, hz 55–65, a 0–500).

Dinámicos: `:- dynamic ahora/1, lectura/4, consulta/4, evento/3, escenario_actual/1.`

`cargar_escenario(+Nombre)`: hace `retractall` de lo dinámico, carga `escenarios/Nombre.pl` (los escenarios son archivos de hechos que se agregan con `assertz`; elige la forma más simple y robusta) y guarda `escenario_actual(Nombre)`. Valida el nombre contra la lista blanca: `s0_normal, s1a, s1b, s2, s3, s4a, s4b, s4c, s5`.

`descripcion_escenario(Nombre, Texto)`: una frase por escenario.

## 5. Escenarios (datos exactos; genera las lecturas repetitivas con un predicado auxiliar dentro del archivo)

**Convención:** una lectura en el segundo T representa el intervalo [T, T+5). Pon un comentario al inicio de cada archivo diciendo qué demuestra.

### s0_normal — todo en orden
`ahora(45000)`. Los 7 medidores tienen lectura fresca (segundo 44995) de `v` entre 126 y 127 y `kw`: acometida 25, p1_general 10, p1_motores 0, p1_alumbrado 2, p2_general 8, p2_compartido 6, p3_aulas 7. Las consultas son `ok` con 30–60 ms. La acometida tiene lecturas `kw` de 25 cada 5 s desde el inicio de la ventana (44100) hasta 44995. No hay arranques previstos.
**Esperado:** `decide(ventana, ...)` → alarma `ninguna`, certeza `firme`.

### s1a — pico brevísimo al inicio (NO debe rebasar)
Ventana 43200–44100, `ahora(43320)`. Acometida `kw` = 70 en 43200, 43205 … 43225 (6 lecturas = 30 s) y 25 en 43230 … 43315 (18 lecturas). p1_motores `kw` 0 y fresca. Sin arranques previstos.
**Esperado:** acumulado = 70·30 + 25·90 = **4350 kW·s**; restante = 780 s · 25 = 19500; proyectado = 23850/900 = **26.5 kW**; alarma `ninguna`; margen **13.5**; certeza `firme`.

### s1b — carga moderada sostenida al final con arranques (SÍ debe rebasar)
Ventana 43200–44100, `ahora(43860)` (660 s dentro). Acometida `kw` = 36 cada 5 s de 43200 a 43855, **excepto que falta la lectura de 43500** (hay `consulta(acometida, timeout, 1000, 43500)`). p1_motores `kw` 0, fresca (43855). Arranques previstos: `evento(bomba, arranque_previsto, 43890)`, `evento(compresor, arranque_previsto, 43920)`, `evento(extractor, arranque_previsto, 43950)`.
**Esperado:**
- acumulado = 36·660 = **23760** (el hueco se rellena con 36) → `lecturas_faltantes = [43500]`, certeza `estimacion`
- base restante = 36·240 = 8640
- motores: bomba 7.5·210 = 1575, compresor 11·180 = 1980, extractor 3.7·150 = 555 → 4110
- proyectado = 36510/900 = **40.57 kW** → alarma `anticipada`, margen **−0.57**
- No es `vigente` porque 23760/900 = 26.4 < 40.
- Diferir (se prueba de menor a mayor prioridad, empezando por el compresor): sin el compresor, 34530/900 = **38.37** < 40 → recomendación **compresor hasta 44100 (12:15)**; se le falla al **taller**.
- `que_falta(ventana)`: bajar 510 kW·s, que en los 240 s restantes son **2.13 kW** menos; o diferir cualquiera de estos (los tres bastan): extractor → 39.95, compresor → 38.37, bomba → 38.82.
- `hipotesis(mover(compresor, 600), ventana)`: el compresor arranca en 44520, fuera de la ventana → proyectado 38.37, alarma `ninguna`.

### s2 — contador que vuelve a cero
`ahora(36300)`. Lecturas `kwh`:
- p1_general: 5000.0 @36000 y 5002.0 @36300
- p1_motores: 800.0 @36000 y 801.4 @36300
- p1_alumbrado: 1520.4 @36000; timeouts cada 5 s de 36005 a 36060; `evento(p1_alumbrado, reinicio, 36030)`; 0.05 @36065; 0.1 @36300

Consultas `ok` para el resto.
**Esperado:**
- `salto_contador(p1_alumbrado, reinicio, Ev)`
- `consumo_medidor(p1_alumbrado, 36000, 36300, entre(0.1, 0.6))`: el mínimo es lo que midió después del reinicio; el máximo es general − motores = 2.0 − 1.4 = 0.6
- `consumo_piso(piso1, 36000, 36300, se_sabe(2.0), Sustento)` con sustento en p1_general
- Casos inline en las pruebas (assert/retract): anterior 99999.5 y nuevo 0.3 → `desbordamiento`, consumo 0.7; anterior 1520.4 y nuevo 800.0 sin evento → `dato_corrupto`, que se reporta como `no_se_puede_saber`, nunca como negativo; si también falta p1_general → piso `no_se_puede_saber`.

### s3 — medidor lento y sus víctimas
Ventana 50400–51300, `ahora(50700)`. Ciclos del bus_a en 50685, 50690 y 50695:
- acometida: ok 40 ms en los tres; `kw` 30 fresca (50695), y `kw` 30 cada 5 s desde 50400
- p1_general: ok 750, 820 y 900 ms; lecturas frescas
- p1_motores: timeout, ok 950 ms, timeout; su última `lectura` tiene segundo **50680** (edad 20 > 15 → vieja)
- p1_alumbrado: timeout en los tres; última lectura @50660

bus_b normal (ok, 30–50 ms, lecturas frescas).
**Esperado:**
- timeouts: alumbrado 3, motores 2, general 0
- `lento(p1_general, si)` (3 de 3 > 500); `lento(p1_motores, no)` (solo 1 ok > 500)
- `causante_bus(bus_a, p1_general, _)`: es el primer lento según el orden del bus, aunque tenga 0 timeouts
- víctimas: p1_motores y p1_alumbrado (van después y tienen timeout o lectura vieja). acometida NO es víctima (va antes)
- `aislar(p1_general, PorQueNoElOtro)`, donde la explicación dice que p1_alumbrado tiene más timeouts pero es víctima de su turno
- Alarma de demanda = `no_puedo_decir`. **Regla:** la acometida dice cuánta potencia hay, pero no si los motores ya arrancaron. Sin lectura fresca de p1_motores no sé si sumar sus arranques o si ya están incluidos. Como el margen (40 − 30 = 10) es menor que la potencia de motores que podría esconderse (22.2), la alarma no se puede decidir. La explicación nombra a p1_motores como lectura vieja por culpa de p1_general.

### s4a / s4b / s4c — caída de voltaje (instante T = 30000)
- **s4a (red):** en T, `v`: acometida 108, p1_general 109, p2_general 107, p3_aulas 108. p1_motores `kw` sin cambio y sin arranques. Todo fresco. `ahora(30005)`.
  → causa `red`; descartada `arranque_motores` (cayeron pisos sin motores y la acometida).
- **s4b (motores):** `evento(compresor, arranque, 29995)`; p1_motores `kw` 0 @29990 → 11 @29995; en T, `v`: p1_general 108, acometida 124, p2_general 125, p3_aulas 126. `ahora(30005)`.
  → causa `arranque_motores`; descartada `red` (la acometida no cayó); la potencia subió antes de la caída; acción: escalonar arranques.
- **s4c (no se puede decir):** en T, p1_general `v` 108; acometida y p1_motores con `consulta(..., timeout, 1000, 29995/30000)`, y sus últimas lecturas son de 29975 (viejas). p2_general 125. `ahora(30005)`.
  → `no_se_puede_decir`; dato que falta: el voltaje de la acometida y la potencia de p1_motores en T.
- Prueba extra inline: solo p3_aulas en 100 V, con acometida y p2/p1 normales → `medidor_local`.

### s5 — reparto del medidor compartido (un día)
`ahora(86000)`. p2_compartido tiene **una lectura por ventana de 15 min** (96 lecturas, en el segundo de inicio de cada ventana); cada lectura es el promedio de esa ventana (supuesto simplificador). `kw`:
- 00:00–07:45 → 1.6
- 08:00–08:45 → 4.0
- 09:00–15:45 → 6.0
- **16:00 → 9.0** (ventana máxima; `kvar` 5.0)
- 16:15–17:45 → 6.0
- 18:00–19:45 → 3.5
- 20:00–23:45 → 1.6

`kvar` = 1.0 en las demás. La energía de cada lectura es kw · 0.25 kWh. Las reglas de frescura no aplican aquí: es análisis del día completo.
**Esperado:**
- Fuera del horario de oficinas, todo es del laboratorio: noche (48 lecturas · 1.6 · 0.25) = 19.2, más 18:00–20:00 (8 · 3.5 · 0.25) = 7.0.
- En horario de oficinas (40 lecturas, 58.75 kWh): base del lab 40 · 1.5 · 0.25 = 15.0; variable 43.75 → lab 30 % = 13.125, oficinas 70 % = 30.625.
- `reparto_energia` → **lab 54.33 kWh, oficinas 30.63 kWh**, certeza `estimacion`.
- `reparto_demanda` (ventana de las 16:00, 9 kW) → lab 1.5 + 0.3 · 7.5 = **3.75 kW (41.7 %)**, oficinas **5.25 kW (58.3 %)**. El lab consume más energía, pero las oficinas pesan más en la demanda.
- `consumo_nocturno(laboratorio)` → `esperado` (1.6 ≤ 1.8). Prueba inline: 2.5 a las 03:00 → `anomalia`.
- `factor_potencia(p2_compartido)` en la ventana de las 16:00 → 9/√(81+25) = **0.874** → penaliza; la penalización se reparte 41.7 % / 58.3 %.
- `se_le_falla_a`: si la base real del lab es menor, se le falla al **laboratorio** (paga de más); si las oficinas dejan equipos encendidos de noche, se le falla al **laboratorio** también, porque paga ese consumo; si la carga declarada de las oficinas está inflada, se le falla a las **oficinas** en la demanda.

## 6. Reglas (`reglas.pl`) — escritas por la alumna en español

Implementa cada bloque con **su prueba primero**. La `Explicacion` siempre es una **lista ordenada de términos** (por ejemplo `[acumulado(23760), restante_s(240), arranque(compresor, 43920, 11.0), promedio_proyectado(40.57), limite(40.0)]`). El servidor la traduce a texto.

### 6.0 Base
> "Una lectura sirve si es la más reciente de ese medidor y variable, y su edad (ahora menos su segundo) no pasa de 15 s. Si la última lectura es más vieja, o si la última consulta después de ella fue timeout, el valor es desconocido, no cero."

- `ultima_lectura(+M, +Var, -Valor, -Seg)`
- `edad(+M, -Segundos)`
- `fresca(+M, +Var, -Estado)` con Estado = `si | no | no_se` (`no_se` si no hay ninguna lectura)
- `valor(+M, +Var, -R)` con R = `conocido(V) | desconocido(vieja) | desconocido(timeout) | desconocido(sin_dato)`
- `segundo_del_dia_a_hora(+S, -Texto)` para mostrar "12:15" (solo formato)

### 6.1 Situación 1 — pico futuro
> "La ventana empieza en el múltiplo de 900 s anterior a ahora. Lo acumulado es la suma de kW de la acometida por 5 s de cada lectura de la ventana; las lecturas que faltan se rellenan con el último valor y la certeza baja a estimación. Lo que falta es la potencia actual por el tiempo restante, más cada motor con arranque previsto dentro de la ventana que no esté ya encendido, por el tiempo que le quedaría encendido. El promedio proyectado es (acumulado + esperado) / 900. Si lo acumulado por sí solo ya pasa el límite, la alarma es vigente; si solo la proyección lo pasa, es anticipada; si no, ninguna. Si el margen es menor que la potencia de motores que podría estar escondida por una lectura vieja de p1_motores, la alarma es no_puedo_decir. Para recomendar qué arranque diferir pruebo los motores de menor a mayor prioridad, y el primero que deja la proyección bajo el límite es la recomendación, hasta el inicio de la siguiente ventana; se le falla al área del motor."

- `ventana_actual(-Inicio, -Fin)`
- `acumulado_ventana(-KwS, -Faltantes)`
- `proyeccion(+Excluidos, -Promedio, -Certeza, -Explicacion)`: `Excluidos` es una lista de motores diferidos (la misma regla sirve para diferir, que_falta e hipótesis)
- `alarma_demanda(-Tipo, -Margen, -Certeza, -Explicacion)` con Tipo = `anticipada | vigente | ninguna | no_puedo_decir`
- `diferir(-Motor, -Hasta, -SeLeFallaA)` (falla si no hace falta diferir)

### 6.2 Situación 2 — contador
> "Si un kWh nuevo es menor que el anterior: con evento de reinicio entre los dos es reinicio; si el anterior estaba a menos del 1 % del máximo es desbordamiento; si no, es dato corrupto. Nunca acepto consumo negativo ni un consumo enorme en silencio. En un reinicio, el consumo del intervalo está entre lo medido después del reinicio y lo que dice el general aguas arriba menos sus otros hijos. En un desbordamiento es (máximo − anterior) + nuevo. El consumo del piso se toma de su medidor general si está disponible (se_sabe); si no, de la suma de sus hijos (se_sabe, entre, o no_se_puede_saber si algún hijo no se sabe)."

- `salto_contador(+M, -Tipo, -Evidencia)` con Tipo = `reinicio | desbordamiento | dato_corrupto`
- `consumo_medidor(+M, +Desde, +Hasta, -R)` con R = `se_sabe(K) | entre(Min, Max) | no_se_puede_saber`
- `consumo_piso(+Piso, +Desde, +Hasta, -R, -Sustento)`

### 6.3 Situación 3 — medidor lento
> "Un medidor es lento si al menos 2 de sus últimas 3 consultas fueron ok y tardaron más de 500 ms; los timeouts no cuentan, porque un timeout puede ser culpa de otro. El causante de un bus es el primer medidor lento según el orden de consulta. Víctima es todo medidor que va después del causante en el mismo bus y tiene timeouts o lecturas viejas. Se aísla al causante aunque otro tenga más timeouts. Toda alarma que use una lectura de una víctima pasa a no_puedo_decir y se dice cuál."

- `timeouts(+M, -N)` (en las últimas 3 consultas)
- `lento(+M, -Estado)` (`si | no | no_se`)
- `causante_bus(+Bus, -M, -Explicacion)`
- `victima(?M, -Causante)`
- `lecturas_viejas_por_bus(-Lista)`
- `alarmas_afectadas(-Lista)`
- `aislar(-M, -PorQueNoElOtro)`

### 6.4 Situación 4 — red o motores
> "Hay caída si el voltaje es menor a 114 V. Si cae la acometida y también un piso sin motores, la causa es la red de la CFE: reportar y proteger equipos; se descarta a los motores. Si la acometida está normal, cae solo el piso con motores y la potencia de p1_motores subió antes o en el mismo instante de la caída con un evento de arranque, la causa son nuestros motores: escalonar arranques; se descarta la red. Si cae un solo medidor y su general aguas arriba no, es un problema local del medidor. Si la acometida o p1_motores no tienen dato fresco en ese instante, la respuesta es no_se_puede_decir y digo qué dato la cambiaría. Nunca invento una causa."

- `caida_voltaje(?M, -Seg)`
- `causa_caida(+Piso, -Causa, -Evidencia, -Descartada, -DatoQueFalta)` con Causa = `red | arranque_motores | medidor_local | no_se_puede_decir | sin_caida`

### 6.5 Situación 5 — reparto
> "Es una política, no una medición, así que la certeza siempre es estimación. Fuera del horario de oficinas, todo el consumo del medidor compartido es del laboratorio. Dentro del horario, primero va la base del laboratorio (1.5 kW) y el resto se reparte 30 % laboratorio / 70 % oficinas según la carga declarada; en el desempate gana la base del laboratorio. El consumo nocturno es esperado si no pasa la base por 1.2; si la pasa, es anomalía. El cargo por demanda se reparte con la misma regla, pero aplicada solo a la ventana de mayor potencia, y por eso quien más energía consume no siempre es quien más pesa en la demanda. La penalización por factor de potencia menor a 0.90 se reparte igual que la demanda."

- `reparto_lectura(+Seg, +Kw, -Lab, -Ofi)`
- `reparto_energia(-Lab, -Ofi, -Regla, -Certeza)`
- `ventana_maxima(+M, -Seg, -Kw)`
- `reparto_demanda(-Lab, -Ofi, -PctLab, -PctOfi, -VentanaSeg)`
- `consumo_nocturno(+Area, -Estado, -Explicacion)` con Estado = `esperado | anomalia | no_se`
- `factor_potencia(+M, +Seg, -Fp, -Penaliza)`
- `se_le_falla_a(-Area, -SiPasaQue)`

### 6.6 Contrato (sin duplicar lógica; todo llama a lo anterior)
- `decide(+Entidad, -Decision, -Explicacion)`:
  - `ventana` → `alarma(Tipo, Margen, Certeza)` (+ recomendación de diferir si aplica)
  - medidor → `estado(fresco | viejo | timeout, ...)` o `aislar` si es causante; para p1_motores en s3 explica que es víctima de p1_general
  - `piso1..piso3` → causa de caída si la hay; si no, consumo y estado
  - `bus_a | bus_b` → causante o `sin_problema`
  - `laboratorio | oficinas` → su parte del reparto con certeza `estimacion`
- `situacion(?Entidad, ?Situacion, -Evidencia)`, consultable en cualquier dirección. Situacion ∈ `rebase_proyectado, rebase_vigente, contador_reiniciado, contador_desbordado, dato_corrupto, medidor_lento, lectura_atrasada, caida_por_arranque, caida_de_red, consumo_nocturno_esperado, consumo_nocturno_anomalo`.
- `que_falta(+Entidad, -Cambios)`: lo que tendría que cambiar para que la decisión cambie (para `ventana`: kW a reducir y qué motores bastan; para un medidor viejo: una lectura fresca; para `no_se_puede_decir`: el dato que falta).
- `hipotesis(+Cambio, +Entidad, -Decision, -Explicacion)` con Cambio = `mover(Motor, Segundos) | quitar(Motor)`. Aplícalo temporalmente con `setup_call_cleanup` para que no quede basura en la base de hechos.

## 7. Pruebas (`tests/reglas_tests.pl`)

Un bloque `begin_tests` por fase, y cada prueba carga su escenario en `setup`. Como mínimo, todos los "Esperado" de la sección 5, más:

- `base`: en s0 todo es fresco; en s3 p1_alumbrado da `desconocido(...)`.
- `s1`: s1a ninguna/26.5/firme; s1b anticipada/40.57/estimacion/faltantes [43500]; diferir compresor hasta 44100 → taller.
- `s2`: reinicio, entre(0.1, 0.6), piso se_sabe(2.0), desbordamiento 0.7, dato_corrupto → no_se_puede_saber, nunca negativo.
- `s3`: causante p1_general, víctimas [p1_motores, p1_alumbrado], p1_alumbrado con más timeouts, alarma no_puedo_decir.
- `s4`: red, arranque_motores, no_se_puede_decir y medidor_local, cada una con su descartada.
- `s5`: 54.33/30.63, demanda 3.75/5.25, nocturno esperado, 2.5 → anomalía, FP 0.874 penaliza.
- `cinco_preguntas` (tabla "Por qué no basta un script" de PROBLEMA.md, **las mismas reglas**):
  1. ¿Qué hago con la ventana ahora? → `decide(ventana, D, E)` en s1b
  2. ¿Por qué no me avisa del medidor de motores? → `decide(p1_motores, D, E)` en s3
  3. ¿Cuáles lecturas están viejas por culpa del bus? → `findall(M, situacion(M, lectura_atrasada, _), L)` en s3
  4. ¿Qué tendría que cambiar para que no haya alarma? → `que_falta(ventana, C)` en s1b
  5. ¿Qué pasaría si el compresor arranca diez minutos después? → `hipotesis(mover(compresor, 600), ventana, D, E)` en s1b → ninguna
- `situacion_libre`: `situacion(E, S, _)` con E y S libres devuelve resultados en s3.

## 8. Servidor (`servidor.pl`)

Usa el estilo de la demo del profe (si existe `_referencia_logicDemo/servidor.pl`, úsalo como referencia): solo traduce HTTP ↔ consultas.
- `:- initialization(main, main).` El puerto sale de argv (8080 por defecto) y escucha en todas las interfaces (`http_server(http_dispatch, [port(Puerto), ip(any)])` o el equivalente que funcione en SWI 9). Al iniciar carga `s0_normal`.
- Traduce cada término de explicación a una frase en español con acentos (`explicacion_texto/2`) y devuelve en el JSON tanto `explicacion` (lista de frases) como `estado` (átomo para el color).
- Endpoints (GET, `reply_json_dict`):

| Ruta | Devuelve |
|---|---|
| `/api/escenarios` | lista `{nombre, descripcion}` + actual |
| `/api/escenario?nombre=s3` | cambia de escenario (lista blanca), devuelve el actual |
| `/api/estado` | los 7 medidores: piso, bus, turno, edad_s, ultimo_ms, v, kw (número o "no sé"), estado (`fresco/viejo/timeout`), rol (`causante/victima/normal`); y los pisos con su estado |
| `/api/demanda` | inicio y fin (hora), acumulado, proyectado, límite, margen, certeza, alarma, faltantes, recomendación `{motor, hasta, se_le_falla_a}`, explicación |
| `/api/decide?entidad=ventana` | decision, estado, explicacion |
| `/api/situaciones` | todas las `situacion/3` |
| `/api/que_falta?entidad=ventana` | cambios |
| `/api/hipotesis?motor=compresor&retraso=600` | decisión nueva + explicación |
| `/api/caida?piso=piso1` | causa, evidencia, descartada, dato_que_falta |
| `/api/reparto` | energía (lab/ofi), demanda (lab/ofi/%), fp, penaliza, regla, certeza, se_le_falla_a, nocturno |

- `/` sirve `web/index.html`; `/web/...` sirve los estáticos.
- Si la entidad o el escenario no existen → 404 con `{"error": "..."}`. Atrapa excepciones y no tumbes el servidor.
- `probar_api.sh`: `curl -s` a cada endpoint con varios escenarios. Arranca el servidor en segundo plano, ejecuta el script, muestra la salida real y apágalo.

## 9. Interfaz (`web/`)

- **Si `design/` tiene el export de Google Stitch** (HTML o `DESIGN.md`), respeta sus colores, tipografía y layout. **Si no lo tiene**, constrúyela con la especificación de abajo y anota en `SUPUESTOS.md` que el diseño de Stitch queda pendiente.
- Sin dependencias externas: nada de CDN, Tailwind remoto ni fuentes de Google (igual que el proyecto Erlang). Si el export de Stitch usa Tailwind CDN, conviértelo a CSS propio en `estilos.css`.
- Mobile first, en español, con 4 vistas y navegación inferior en celular (pestañas arriba en escritorio):
  1. **Panel:** selector de escenario; tarjeta "Ventana de demanda" con barra de tiempo, acumulado, proyectado contra límite, alarma, certeza, recomendación y "¿Por qué?" (lista numerada); botón "¿Qué falta para que cambie?"; formulario "¿Qué pasaría si…?" con un selector de motor y los minutos de retraso.
  2. **Medidores:** dos columnas (Bus A y Bus B) en orden de turno: nombre, piso, turno, ms, edad, V y kW, más un chip de causante o víctima; el árbol de la topología arriba.
  3. **Alarmas:** lista de situaciones y tarjeta "Caída de voltaje" (causa, evidencia, descartada y dato que la cambiaría) con un selector de piso.
  4. **Reparto piso 2:** barras de energía contra barras de demanda (lab/oficinas), la regla en una frase, la etiqueta "Estimación", el FP con su umbral y "Si la regla se equivoca…".
- Colores según el `estado` que manda Prolog: verde = normal/ninguna, ámbar = anticipada/estimación, rojo = vigente/falla, **gris = no sé** (debe verse distinto del verde).
- `app.js`: solo `fetch` y pintar; refresca `/api/estado` cada 5 s.
- **Verificación obligatoria:** `grep -nE "40|0\.9|114|500|900|1\.5|0\.3|0\.7" web/app.js` no debe mostrar ninguna regla ni umbral del dominio. Reporta la salida.

## 10. Documentación

1. **`AGENTS.md`** (fase 0): resumen de la sección 1 y de los comandos de verificación.
2. **`SUPUESTOS.md`** (fase 0): la tabla de la sección 3, separada en "Supuestos de la alumna" y "Cifras del problema original", más la sección "Decisiones tomadas durante la implementación".
3. **`README.md`** (fase 9):
   - Encabezado: "#8 Monitor de energía — Gemelo digital (Prolog)", materia Programación Lógica y Funcional, Stephanie Ariana Medrano Vargas - 23212013, fecha [COMPLETAR].
   - Qué es y en qué se diferencia del simulador Erlang.
   - Requisitos (SWI-Prolog 9.x) y cómo correr.
   - Tabla de situaciones (escenario | decisión | predicado | prueba).
   - Tabla de las 5 preguntas con la consulta exacta.
   - Arquitectura.
   - Enlace a SUPUESTOS.md.
   - Respuesta corta a las 5 preguntas guía de PROBLEMA.md.
   - **Párrafo "Erlang vs Prolog":** en Erlang resolví la concurrencia y la tolerancia a fallas: un `gen_server` por medidor bajo supervisores `one_for_one`, un simulador, recuperación tras falla y la API en Cowboy, porque son procesos vivos que fallan y se reinician. En Prolog resolví el razonamiento: proyectar la ventana, distinguir causante de víctima, diagnosticar la caída, repartir con una política explícita y decir "no sé", porque son relaciones entre hechos que se consultan en cualquier dirección y se explican. Lo que el Erlang podría aportar al gemelo: las lecturas y los timeouts de cada proceso `medidor` se pueden exportar como hechos `lectura/4` y `consulta/4`.
4. **`docs/manual-gist.md`**: manual para el administrador con la misma estructura que `../docs/manual-gist.md`: para qué sirve, requisitos, instalación (local y en VM: `sudo apt install -y swi-prolog`, clonar, `cd gemelo`, pruebas, `swipl servidor.pl`, abrir el puerto 8080), uso de cada vista con marcadores `[CAPTURA: ...]`, cómo leer "no sé" y "estimación", un ejemplo por escenario y solución de problemas (puerto ocupado, `swipl` no encontrado, no carga desde fuera de la VM).
5. **`docs/uso-ia.md`**: declaración de uso de IA. Usé OpenCode como asistente siguiendo CONTEXTO_AGENTES.md y este PLAN.md. Yo fijé los supuestos y redacté cada regla en español antes de implementarla. Las pruebas se escribieron antes que las reglas. Revisé el resultado y puedo explicar cada regla.
6. **`docs/guion-demo.md`**: guion de 8 a 10 min:
   - arrancar (en la VM)
   - pruebas en verde
   - s1a contra s1b
   - "¿qué pasaría si…?" con el compresor en vivo
   - s3 (causante contra víctimas)
   - s4a, s4b y s4c
   - s5 (energía contra demanda)
   - cierre con el párrafo Erlang vs Prolog

   Al final, 8 preguntas probables del profe con su respuesta corta, por ejemplo: ¿por qué Prolog?, ¿por qué el causante no es el que más timeouts tiene?, ¿por qué el pico de 70 kW no dispara?, ¿qué es "no sé" y en qué se diferencia de "no"?, ¿dónde está la prioridad entre motores?, ¿por qué la interfaz no decide nada?, ¿qué cifras son supuestos?, ¿cómo cambiarías la regla de reparto?
7. En el `README.md` de la raíz del repo (`../README.md`), agrega al final la sección "Gemelo digital (Prolog)" con un enlace a `gemelo/README.md`. Es el único cambio permitido fuera de `gemelo/`.

## 11. Fases (ejecútalas todas seguidas, sin preguntar)

| Fase | Qué |
|---|---|
| 0 | `AGENTS.md`, `SUPUESTOS.md`, esqueleto de archivos con encabezado (proyecto y autora) |
| 1 | `hechos.pl` + los 9 escenarios + prueba de carga (los 7 medidores y un solo `ahora/1` por escenario) |
| 2 | Base (6.0) |
| 3 | Situación 1 |
| 4 | Situación 2 |
| 5 | Situación 3 |
| 6 | Situación 4 |
| 7 | Situación 5 |
| 8 | Contrato (6.6) + `cinco_preguntas` + `situacion_libre` |
| 9 | Servidor + `probar_api.sh` + web + grep de verificación + documentación |
| 10 | Verificación final (abajo) |

**Verificación final (fase 10):** ejecuta y muestra la salida real de:
```bash
swipl -g run_tests -t halt tests/reglas_tests.pl
grep -rnE "get_time|random" hechos.pl reglas.pl escenarios/
grep -nE "40|0\.9|114|500|900|1\.5|0\.3|0\.7" web/app.js
./probar_api.sh
```
Después, el último commit y un **resumen final** con: el número de pruebas que pasan, la lista de archivos, las decisiones que tomaste (las de SUPUESTOS.md) y los pasos que le quedan a la alumna (Stitch si faltó, capturas, Gist y VM).
