# Manual de Usuario - Monitor de Energia

## Para que Sirve

El Monitor de Energia es un sistema que permite visualizar en tiempo real el consumo electrico de un edificio dividido en pisos y medidores. Muestra:

- Consumo instantaneo y acumulado de cada medidor
- Estado de cada medidor (normal, alerta, critico) segun su consumo
- Totales por piso y del edificio completo
- Alarmas activas cuando un medidor supera el 80% de su umbral
- Simulacion de picos de consumo y fallos para pruebas

## Requisitos

- Erlang/OTP 27 instalado
- Rebar3 instalado
- Navegador web moderno (Chrome, Firefox, Safari, Edge)
- Puerto 8080 disponible

## Instalacion

1. Clonar o descargar el proyecto
2. Abrir terminal en la carpeta del proyecto
3. Compilar:
   ```bash
   rebar3 compile
   ```

## Ejecucion

### Iniciar el Servidor

```bash
rebar3 shell
```

Esperar a ver el prompt de Erlang:
```
Erlang/OTP 27 [...]

Eshell V27.0 (press Ctrl+C to abort, type help(). for help)
1>
```

El servidor HTTP esta activo en puerto 8080.

### Detener el Servidor

En el shell de Erlang, presionar `Ctrl+C` dos veces.

## Acceso a la Interfaz

### Opcion 1: Localhost (Maquina Local)

Si estas en la misma maquina donde corre el servidor:

```
http://localhost:8080
```

[CAPTURA: navegador abriendo localhost:8080]

### Opcion 2: IP de la VM (Desde Otra Maquina)

Si el servidor corre en una VM o maquina remota:

```
http://IP_DE_LA_VM:8080
```

Ejemplo: `http://192.168.1.100:8080`

**Nota**: Asegurar que el puerto 8080 este accesible desde la red.

[CAPTURA: navegador abriendo IP:8080]

### Opcion 3: AWS Academy (Grupo de Seguridad)

Si usas AWS Academy Learner Lab:

1. En la consola de AWS, ir a EC2 > Security Groups
2. Seleccionar el grupo de seguridad de tu instancia
3. Editar reglas de entrada (Inbound rules)
4. Agregar regla:
   - Type: Custom TCP
   - Port: 8080
   - Source: 0.0.0.0/0 (o tu IP especifica)
5. Guardar
6. Acceder via: `http://IP_PUBLICA_EC2:8080`

[CAPTURA: configuracion de grupo de seguridad en AWS]

[CAPTURA: acceso exitoso desde navegador]

### Opcion 4: Tunel SSH

Si no puedes abrir el puerto 8080, usa un tunel SSH:

```bash
ssh -L 8080:localhost:8080 usuario@IP_DEL_SERVIDOR
```

Luego en tu navegador local:
```
http://localhost:8080
```

El trafico se redirige a traves del tunel SSH.

[CAPTURA: comando ssh -L en terminal]

## Como Usar la Interfaz

### Vista Principal

La interfaz muestra:

1. **Indicador de conexion** (esquina superior derecha):
   - "En vivo" (verde): Sistema conectado
   - "Reconectando..." (rojo): Sin conexion

2. **Panel de totales**:
   - Consumo actual del edificio (kW)
   - Consumo acumulado (kWh)
   - Numero de alarmas activas

3. **Seccion de alarmas**:
   - Lista de medidores en estado alerta o critico
   - "Todo en orden" si no hay alarmas

4. **Tarjetas de pisos**:
   - Una tarjeta por piso con su consumo total
   - Grid de medidores del piso

5. **Tarjetas de medidores**:
   - Estado (normal/alerta/critico) con color
   - Consumo actual (kW)
   - Consumo acumulado (kWh)
   - Umbral configurado (kW)
   - Botones "Simular pico" y "Simular falla"

[CAPTURA: vista completa de la interfaz]

### Actualizacion Automatica

Los datos se actualizan automaticamente cada 2 segundos sin necesidad de recargar la pagina.

[CAPTURA: timestamp cambiando automaticamente]

### Interpretar Estados de un Medidor

Cada medidor puede estar en uno de tres estados:

| Estado   | Color  | Significado                                  | Rango              |
|----------|--------|----------------------------------------------|--------------------|
| Normal   | Verde  | Consumo dentro de limites normales           | < 80% del umbral   |
| Alerta   | Ambar  | Consumo elevado, cerca del limite            | 80-99% del umbral  |
| Critico  | Rojo   | Consumo excede el umbral, requiere atencion  | >= 100% del umbral |

**Ejemplo**: Si el umbral es 10.0 kW:
- Normal: 0.0 - 7.9 kW
- Alerta: 8.0 - 9.9 kW
- Critico: >= 10.0 kW

[CAPTURA: medidor en estado normal]

[CAPTURA: medidor en estado alerta]

[CAPTURA: medidor en estado critico]

### Simular Pico de Consumo

Para probar que el sistema detecta sobrecargas:

1. Hacer clic en "Simular pico" de cualquier medidor
2. El boton cambia a "Enviando..." y luego "Pico activado"
3. En 2-4 segundos, el medidor cambia a estado critico
4. Aparece en la seccion de alarmas
5. El contador de alarmas se incrementa
6. Despues de ~10 segundos, el pico termina y vuelve a normal

[CAPTURA: boton "Simular pico" antes de hacer clic]

[CAPTURA: medidor en estado critico tras simular pico]

[CAPTURA: alarma apareciendo en la lista]

### Simular Falla de Medidor

Para demostrar la recuperacion automatica:

1. Hacer clic en "Simular falla" de un medidor
2. El boton cambia a "Enviando..." y luego "Falla activada"
3. El medidor puede mostrar momentaneamente valores en 0
4. En menos de 1 segundo, el supervisor lo reinicia
5. El medidor vuelve a funcionar con valores iniciales
6. Los demas medidores no se ven afectados

[CAPTURA: boton "Simular falla"]

[CAPTURA: medidor reiniciado con valores en 0]

[CAPTURA: otros medidores funcionando normalmente]

## Ejemplos con curl

### Ver Estado del Edificio

```bash
curl http://localhost:8080/api/edificio
```

Respuesta (abreviada):
```json
{
  "total_kw": 28.5,
  "total_kwh": 45.3,
  "pisos": [...],
  "alarmas": [...],
  "medidores": [...]
}
```

[CAPTURA: curl /api/edificio con respuesta JSON]

### Ver Solo Alarmas

```bash
curl http://localhost:8080/api/edificio | jq '.alarmas'
```

[CAPTURA: curl con jq mostrando solo alarmas]

### Ver Medidores de un Piso

```bash
curl http://localhost:8080/api/edificio | jq '.medidores[] | select(.piso == 1)'
```

### Provocar Pico en Medidor

```bash
curl -X POST http://localhost:8080/api/demo/pico/1/2
```

Simula pico en Piso 1, Medidor 2.

Respuesta:
```json
{"ok": true}
```

[CAPTURA: curl POST /api/demo/pico]

### Provocar Falla en Medidor

```bash
curl -X POST http://localhost:8080/api/demo/falla/2/1
```

Mata el proceso del Piso 2, Medidor 1. El supervisor lo reinicia automaticamente.

[CAPTURA: curl POST /api/demo/falla]

## Configuracion

El archivo `config/sys.config` permite ajustar:

```erlang
[
  {energia, [
    {pisos, 2},                    % Numero de pisos (ej: 3, 5)
    {medidores_por_piso, 3},       % Medidores por piso (ej: 4, 6)
    {umbral_kw, 10.0},             % Umbral en kW (ej: 15.0)
    {intervalo_ms, 2000},          % Intervalo de actualizacion (ej: 1000, 5000)
    {puerto, 8080}                 % Puerto HTTP (ej: 3000, 8888)
  ]}
].
```

Despues de modificar, recompilar y reiniciar:
```bash
rebar3 compile
rebar3 shell
```

[CAPTURA: sys.config abierto en editor]

## Solucion de Problemas

| Problema                                | Posible Causa                          | Solucion                                         |
|-----------------------------------------|----------------------------------------|--------------------------------------------------|
| No se puede acceder a localhost:8080    | Servidor no esta corriendo             | Ejecutar `rebar3 shell`                          |
| Error "eaddrinuse"                      | Puerto 8080 ya en uso                  | Cambiar puerto en sys.config o cerrar otro proceso |
| Interfaz muestra "Reconectando..."      | Servidor detenido o no accesible       | Verificar que `rebar3 shell` este activo         |
| Botones no responden                    | Error de JavaScript                    | Abrir consola del navegador (F12) y revisar errores |
| No se ven datos en la interfaz          | API no responde                        | Probar `curl localhost:8080/api/edificio`        |
| Pagina no carga (404)                   | Archivos estaticos no encontrados      | Verificar que exista `priv/static/index.html`    |
| Datos no se actualizan                  | JavaScript no ejecutandose             | Recargar pagina (Ctrl+R o F5)                    |
| No puedo acceder desde otra maquina     | Firewall o puerto cerrado              | Abrir puerto 8080 en firewall o usar tunel SSH  |
| Error "connection refused"              | IP incorrecta o servidor no escuchando | Verificar IP con `ip addr` o `ifconfig`          |
| Valores siempre en 0                    | Simulador no esta enviando lecturas    | Esperar 2 segundos para primera lectura          |

[CAPTURA: consola del navegador mostrando logs]

## Comandos Utiles

### Ver Procesos Registrados

En el shell de Erlang:
```erlang
1> registered().
```

Deberia incluir: `energia_sup`, `medidor_sup`, `simulador`, `medidor_p1_m1`, etc.

### Ver Estado de un Medidor

```erlang
2> medidor:estado(1, 1).
#{estado => normal, id => 1, kw => 4.5, kwh => 12.3, piso => 1, umbral => 10.0}
```

### Provocar Pico Manualmente

```erlang
3> simulador:pico(1, 2).
ok
```

### Ver Datos Completos

```erlang
4> energia_datos:edificio_completo().
#{alarmas => [...], medidores => [...], pisos => [...], total_kw => 28.5, total_kwh => 45.3}
```

[CAPTURA: shell de Erlang ejecutando comandos]

## Notas Adicionales

- Los datos de consumo acumulado (kWh) se pierden si se reinicia un medidor tras fallo
- En produccion, se usaria persistencia (Mnesia, base de datos) para conservar historico
- El simulador genera valores aleatorios; cada medidor tiene consumo base distinto
- El sistema es demostrativo; no esta conectado a medidores reales
