# Reglas del Proyecto Energia

## Estilo y Nomenclatura
- Comentarios y nombres en espanol sin acentos ni enie
- Mensajes de consola sin acentos
- Codigo simple y legible (proyecto escolar de una persona)

## Arquitectura OTP
- Todo proceso con estado va bajo un supervisor
- No usar spawn sueltos
- Logica en funciones puras
- Efectos (mensajes, HTTP) en los procesos
- Funciones puras son probables con EUnit

## Dependencias
- Unica dependencia externa: cowboy 2.x
- JSON usando el modulo `json` de OTP 27 (nativo)

## Especificaciones de Tipo
- Agregar -spec en todas las funciones exportadas
- Un comentario de una linea por funcion exportada

## Configuracion
- Valores configurables en config/sys.config
- Usar application:get_env para leer configuracion
- No valores fijos en el codigo

## Validacion
- Ejecutar `rebar3 compile` sin warnings
- Ejecutar `rebar3 eunit` con todas las pruebas en verde
- Arreglar cualquier fallo antes de terminar
- Reportar el resultado final
