# Verificacion de la Interfaz Web

## Pasos para Probar

### 1. Iniciar el Servidor

```bash
rebar3 shell
```

Espera a que veas el prompt de Erlang `1>`.

### 2. Abrir la Interfaz Web

En tu navegador, abre:
```
http://localhost:8080
```

### 3. Verificaciones Automaticas

La interfaz debe mostrar:

#### Indicador de Conexion
- En la esquina superior derecha, debe decir **"En vivo"** con fondo verde
- Si el servidor se desconecta, debe cambiar a **"Reconectando..."** con fondo rojo

#### Totales del Edificio
- **Consumo Actual**: numero en kW que cambia cada 2 segundos
- **Consumo Acumulado**: numero en kWh que aumenta continuamente
- **Alarmas Activas**: numero de medidores en alerta o critico

#### Seccion de Alarmas
- Si no hay alarmas: muestra "Todo en orden" con fondo verde
- Si hay alarmas: lista cada medidor con su estado (ALERTA o CRITICO)

#### Tarjetas de Pisos
- Debe haber 2 pisos (configurable en sys.config)
- Cada piso muestra su consumo total
- Cada piso tiene 3 medidores (configurable)

#### Tarjetas de Medidores
- Cada medidor muestra:
  - Titulo: "Medidor 1", "Medidor 2", etc.
  - Estado: badge con color (verde=normal, ambar=alerta, rojo=critico)
  - Consumo actual en kW
  - Consumo acumulado en kWh
  - Umbral configurado
  - 2 botones: "Simular pico" y "Simular falla"

#### Actualizacion Automatica
- Todos los valores deben cambiar cada 2 segundos
- El timestamp debe actualizarse
- El JSON en la parte inferior debe reflejar los cambios

### 4. Pruebas Manuales

#### Prueba 1: Simular Pico
1. Hacer clic en "Simular pico" de cualquier medidor
2. El boton debe cambiar a "Enviando..." y luego "Pico activado"
3. En 2-4 segundos, el medidor debe cambiar a estado CRITICO (rojo)
4. Debe aparecer en la seccion de Alarmas
5. El contador de "Alarmas Activas" debe incrementarse
6. Despues de ~10 segundos, el pico termina y vuelve a normal

#### Prueba 2: Simular Falla
1. Hacer clic en "Simular falla" de otro medidor
2. El boton debe cambiar a "Enviando..." y luego "Falla activada"
3. El medidor puede desaparecer momentaneamente o mostrar valores en 0
4. En menos de 1 segundo, el supervisor lo reinicia
5. El medidor vuelve a aparecer con valores iniciales (0 kW, 0 kWh)
6. La pagina NO debe romperse ni mostrar errores
7. Los otros medidores siguen funcionando normalmente

#### Prueba 3: Desconexion
1. En la terminal donde corre `rebar3 shell`, presiona Ctrl+C dos veces
2. El indicador debe cambiar a "Reconectando..." en rojo
3. La interfaz sigue mostrando los ultimos datos conocidos
4. Reinicia con `rebar3 shell`
5. El indicador debe volver a "En vivo" en verde
6. Los datos deben actualizarse nuevamente

### 5. Usando el Script de Prueba

En otra terminal (con el servidor corriendo):

```bash
./test_api.sh
```

Esto ejecuta una serie de pruebas automaticas de la API.

### 6. Verificacion con curl

```bash
# Ver estado completo
curl http://localhost:8080/api/edificio | jq

# Provocar pico en Piso 1, Medidor 2
curl -X POST http://localhost:8080/api/demo/pico/1/2

# Provocar falla en Piso 2, Medidor 1
curl -X POST http://localhost:8080/api/demo/falla/2/1

# Ver solo alarmas
curl http://localhost:8080/api/edificio | jq '.alarmas'

# Ver solo medidores
curl http://localhost:8080/api/edificio | jq '.medidores'
```

## Criterios de Aceptacion

- [x] Al abrir http://localhost:8080 se carga la interfaz
- [x] Los numeros cambian solos cada 2 segundos
- [x] "Simular pico" provoca una alarma visible
- [x] "Simular falla" no rompe la pagina
- [x] El medidor con falla vuelve a reportar despues de reiniciarse
- [x] Estados se muestran con colores (verde/ambar/rojo)
- [x] Sin alarmas muestra "Todo en orden"
- [x] Indicador de conexion funciona correctamente
- [x] Botones tienen feedback visual

## Problemas Comunes

### El navegador muestra error 404
- Verifica que el servidor este corriendo
- Asegura que estas usando el puerto correcto (8080 por defecto)

### Los datos no se actualizan
- Abre la consola del navegador (F12)
- Busca errores en JavaScript
- Verifica que `/api/edificio` responda correctamente

### Los botones no funcionan
- Verifica en la consola del navegador si hay errores
- Asegura que los endpoints `/api/demo/pico` y `/api/demo/falla` respondan

### "Reconectando..." no cambia a "En vivo"
- Verifica que el servidor este corriendo
- Revisa los logs de Cowboy en la terminal de `rebar3 shell`

## Arquitectura del Frontend

```
index.html
  ├── Estructura HTML con IDs y clases
  ├── CSS inline para estilos
  └── <script src="app.js">

app.js
  ├── Obtener datos (fetch cada 2s)
  ├── Actualizar totales
  ├── Actualizar alarmas
  ├── Actualizar pisos y medidores
  ├── Event listeners para botones
  └── Manejo de errores/reconexion
```

## Textos en Espanol

Todos los textos estan en espanol sin acentos:
- "En vivo" / "Reconectando..."
- "Consumo Actual" / "Consumo Acumulado"
- "Alarmas Activas"
- "Todo en orden"
- "Simular pico" / "Simular falla"
- Estados: "normal", "alerta", "critico"

## Sin Frameworks

- JavaScript vanilla (ES6+)
- Sin React, Vue, Angular
- Sin jQuery
- Sin herramientas de build
- Sin node_modules
- Solo navegadores modernos (Chrome, Firefox, Edge, Safari)
