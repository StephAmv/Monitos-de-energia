# Frontend - Interfaz Web del Monitor de Energia

## Archivos

### `priv/static/index.html` (264 lineas)
- Estructura HTML semantica
- CSS inline con diseno moderno
- Grid layouts responsivos
- Sin frameworks CSS (solo CSS vanilla)
- IDs y clases especificas para JavaScript

### `priv/static/app.js` (439 lineas)
- JavaScript vanilla (ES6+)
- Sin dependencias externas
- Sin build tools ni transpilacion
- Patron IIFE para encapsulacion
- Manejo robusto de errores

## Caracteristicas Implementadas

### 1. Actualizacion Automatica
- Fetch a `/api/edificio` cada 2 segundos
- Actualizacion incremental del DOM
- Preservacion del scroll y estado del usuario

### 2. Indicador de Conexion
- **"En vivo"** (verde): Conectado y recibiendo datos
- **"Reconectando..."** (rojo): Sin conexion, reintentando
- Cambio automatico segun el estado del fetch

### 3. Panel de Totales
- Consumo actual del edificio (kW)
- Consumo acumulado (kWh)
- Numero de alarmas activas
- Actualizacion en tiempo real

### 4. Seccion de Alarmas
- Lista de medidores en estado critico o alerta
- Colores distintivos (rojo/ambar)
- Mensaje "Todo en orden" cuando no hay alarmas
- Fondo verde cuando sistema OK, ambar cuando hay alarmas

### 5. Tarjetas de Pisos
- Una tarjeta por piso
- Totales del piso (kW y kWh)
- Grid de medidores dentro de cada piso
- Diseno responsivo

### 6. Tarjetas de Medidores
- Estado visual con codigo de colores:
  - **Verde**: Normal (< 80% del umbral)
  - **Ambar**: Alerta (80-99% del umbral)
  - **Rojo**: Critico (>= 100% del umbral)
- Datos mostrados:
  - Consumo actual (kW)
  - Consumo acumulado (kWh)
  - Umbral configurado (kW)
- Borde izquierdo coloreado segun estado
- Fondo sutilmente coloreado en alerta/critico

### 7. Botones Interactivos

#### Boton "Simular pico"
- POST a `/api/demo/pico/:piso/:medidor`
- Feedback visual: "Enviando..." → "Pico activado"
- Deshabilitado durante la operacion
- Vuelve a habilitarse despues de 2 segundos
- Efecto visible: medidor sube sobre el umbral

#### Boton "Simular falla"
- POST a `/api/demo/falla/:piso/:medidor`
- Feedback visual: "Enviando..." → "Falla activada"
- Mata el proceso del medidor en el backend
- El supervisor lo reinicia automaticamente
- La interfaz NO se rompe
- El medidor reaparece con valores iniciales

### 8. Manejo de Errores
- Catch de errores en fetch
- Reintentos automaticos
- No muestra mensajes molestos al usuario
- Logs en consola para debugging
- Estado de "Reconectando..." informativo

### 9. JSON de Debug
- Seccion colapsable con el JSON completo
- Actualizado en cada fetch
- Util para desarrollo y troubleshooting
- Pretty-print con indentacion

## Flujo de Datos

```
                     ┌──────────────┐
                     │   Navegador  │
                     └──────┬───────┘
                            │
                    Cada 2 segundos
                            │
                            ▼
                   ┌─────────────────┐
                   │  fetch('/api/   │
                   │   edificio')    │
                   └────────┬────────┘
                            │
                    ┌───────┴────────┐
                    │                │
                 ✓ OK            ✗ Error
                    │                │
                    ▼                ▼
          ┌──────────────┐  ┌──────────────┐
          │ Actualizar   │  │ Marcar como  │
          │ interfaz     │  │ desconectado │
          └──────────────┘  └──────────────┘
                    │
                    ├─► Totales
                    ├─► Alarmas
                    ├─► Pisos
                    ├─► Medidores
                    ├─► Timestamp
                    └─► JSON debug
```

## Eventos de Usuario

```
Usuario hace clic en "Simular pico"
         │
         ▼
  POST /api/demo/pico/:piso/:medidor
         │
         ├─► Boton: "Enviando..."
         │
         ▼
  ┌──────────────┐
  │ Respuesta OK │
  └──────┬───────┘
         │
         ├─► Boton: "Pico activado"
         │
         ▼
  Esperar 2 segundos
         │
         ▼
  Boton: "Simular pico" (habilitado)
         │
         ▼
  En siguiente fetch (2s):
    - Medidor cambia a CRITICO
    - Aparece en alarmas
    - Contador de alarmas +1
```

## Codigo de Colores

### Estados de Medidores
- **#388e3c** (verde): Normal
- **#f57c00** (ambar): Alerta
- **#d32f2f** (rojo): Critico

### Estados de Conexion
- **#4caf50** (verde): Conectado
- **#f44336** (rojo): Desconectado

### Alarmas
- **#d4edda** (verde claro): Sin alarmas
- **#fff3cd** (ambar claro): Con alarmas

## Responsive Design

- Grid de medidores: `auto-fill` con minimo 280px
- Grid de totales: `auto-fit` con minimo 200px
- Ancho maximo del body: 1200px
- Padding adaptativo
- Funciona en moviles, tablets y desktop

## Compatibilidad

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Requiere:
- ES6+ (arrow functions, template literals, etc.)
- Fetch API
- async/await
- DOM moderno

## Textos

Todos en espanol sin acentos:
- "En vivo"
- "Reconectando..."
- "Consumo Actual"
- "Consumo Acumulado"
- "Alarmas Activas"
- "Todo en orden"
- "Simular pico"
- "Simular falla"
- "Enviando..."
- "Pico activado"
- "Falla activada"

Estados:
- "normal" (verde)
- "alerta" (ambar)
- "critico" (rojo)

## Performance

- Actualizacion incremental (no recarga toda la pagina)
- Reutilizacion de elementos DOM cuando es posible
- Throttling implicito (solo 1 fetch cada 2 segundos)
- Sin memory leaks (event listeners correctamente manejados)
- Tamanio del bundle:
  - index.html: ~7 KB
  - app.js: ~16 KB
  - **Total: ~23 KB sin comprimir**

## Seguridad

- Sin innerHTML con datos no sanitizados (usando textContent)
- Sin eval()
- Sin inline event handlers
- CORS manejado por el servidor (Cowboy)
- Sin almacenamiento de datos sensibles en localStorage

## Testing Manual

Ver [VERIFICACION.md](VERIFICACION.md) para instrucciones completas.

Checklist rapido:
- [ ] Abrir http://localhost:8080
- [ ] Ver que los numeros cambian cada 2 segundos
- [ ] Click en "Simular pico" → Aparece alarma
- [ ] Click en "Simular falla" → Medidor se recupera
- [ ] Detener servidor → "Reconectando..."
- [ ] Reiniciar servidor → "En vivo"

## Futuras Mejoras (Opcional)

1. Graficas de consumo historico (Chart.js)
2. Notificaciones del navegador para alarmas criticas
3. Filtros y busqueda de medidores
4. Exportar datos a CSV
5. Temas claro/oscuro
6. WebSockets para actualizacion push (sin polling)
7. Service Worker para offline
8. PWA para instalar en el home screen
9. Animaciones de transicion
10. Tooltips con mas informacion
