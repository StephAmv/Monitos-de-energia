# AGENTS.md — Gemelo digital #8 Monitor de energía

**Proyecto:** #8 Monitor de energía — Gemelo digital con programación lógica  
**Autora:** Stephanie Ariana Medrano Vargas (23212013)  
**Materia:** Programación Lógica y Funcional  

## Reglas de arquitectura

- **Todo en SWI-Prolog**: hechos, reglas, explicación y servidor web
- **Ninguna decisión del dominio fuera de Prolog**: la interfaz solo consulta y muestra
- **El "ahora" es un hecho**: prohibido `get_time`, `random` o fecha del sistema en las reglas
- **Solo bibliotecas estándar**: `plunit`, `lists`, `aggregate`, `apply`, `clpfd`, `http`, `solution_sequences`, `yall`
- **Código en español sin acentos ni eñe**: nombres de predicados y comentarios (el texto al usuario sí lleva acentos)
- **Tres resultados**: toda condición devuelve `si`, `no` o `no_se` (nunca convertir `no_se` en `no`)

## Comandos de verificación

```bash
# Pruebas
swipl -g run_tests -t halt tests/reglas_tests.pl

# Servidor (puerto 8080 por defecto)
swipl servidor.pl

# Servidor en otro puerto
swipl servidor.pl 9000

# Verificar que no hay valores del dominio en JavaScript
grep -nE "40|0\.9|114|500|900|1\.5|0\.3|0\.7" web/app.js

# Verificar que no hay get_time ni random en las reglas
grep -rnE "get_time|random" hechos.pl reglas.pl escenarios/

# Probar la API
./probar_api.sh
```

## Estructura

- `hechos.pl` — edificio estático + predicados dinámicos + `cargar_escenario/1`
- `escenarios/` — 9 archivos con datos de prueba
- `reglas.pl` — todas las reglas (módulo `reglas`)
- `servidor.pl` — servidor HTTP que expone `/api/*` y sirve `/web/*`
- `tests/reglas_tests.pl` — pruebas plunit
- `web/` — interfaz (HTML, JS, CSS)

## Contacto

Ver `CONTEXTO_AGENTES.md` y `PROBLEMA.md` para el contexto completo.
