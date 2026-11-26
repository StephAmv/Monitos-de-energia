# SUPUESTOS.md — Gemelo digital #8 Monitor de energía

**Proyecto:** #8 Monitor de energía — Gemelo digital con programación lógica  
**Autora:** Stephanie Ariana Medrano Vargas (23212013)  

## Supuestos de la alumna

Estos valores los decidí yo porque el problema original no los especifica:

| Concepto | Valor | Justificación |
|---|---|---|
| Límite de demanda del edificio | 40 kW (promedio de la ventana) | Edificio pequeño, 3 pisos |
| Ventana de demanda | Fija, 900 s, alineada a :00/:15/:30/:45 | Simplifica la implementación |
| Medidor que mide la demanda del edificio | `acometida` | Es el único medidor que ve todo el edificio |
| Motores | bomba 7.5 kW, compresor 11 kW, extractor 3.7 kW | Motores industriales típicos |
| Prioridad motores | bomba 1 (agua del edificio), extractor 2 (seguridad del taller), compresor 3 (puede esperar) | Bomba es crítica, extractor es seguridad |
| Timeout | 1000 ms | RS-485 lento, el doble de lo normal |
| Medidor lento | ≥ 2 de sus últimas 3 consultas con resultado `ok` y > 500 ms | Los timeouts no cuentan, pueden ser culpa de otro |
| Lectura vieja | edad > 15 s respecto a `ahora/1` | Tres ciclos completos (3 × 5 s) |
| Voltaje bajo | < 114 V (≈ 90% de 127 V) | Protección típica de equipos |
| Máximo del contador | 99999.9 kWh | Contador de 5 dígitos + 1 decimal |
| Margen para desbordamiento | el anterior estaba a menos del 1% del máximo (≥ 98999.9) | Detectar desbordamiento inminente |
| Lectura hueca en la ventana | se rellena con el último valor conocido y la certeza baja a `estimacion` | Supuesto conservador |
| Horario oficinas | 08:00–18:00 (28800–64800 s) | Horario laboral típico |
| Horario laboratorio | uso 08:00–20:00 (28800–72000 s) + base 24 h | Incluye uso nocturno |
| Horario aulas | 07:00–22:00 (25200–79200 s) | Incluye clases matutinas y vespertinas |
| Equipos 24 h del laboratorio | 1.5 kW (refrigerador y servidor) | Base constante |
| Tolerancia nocturna | base × 1.2 = 1.8 kW | 20% de margen para variaciones |
| Carga declarada (parte variable) | laboratorio 0.3 / oficinas 0.7 | Oficinas = clima y computadoras; equipos fijos del lab ya van en la base |
| Penalización por FP < 0.90 | se reparte igual que el cargo por demanda | Criterio justo |

## Cifras del problema original

Estas vienen del documento del proyecto #8 original:

| Concepto | Valor | Origen |
|---|---|---|
| Voltaje de red | 127 V monofásico / 220 V trifásico | Original |
| Frecuencia | 60 Hz | Original |
| Ventana de demanda | 15 min | Original |
| Factor de potencia mínimo | 0.90 | Original |
| Bus RS-485 | 9600 baud, respuestas de decenas de ms | Original |
| Ciclo de consulta | 5 s | Original |
| Horizonte | 24 h | Original |
| Escala original | 30 medidores en 3 buses | Original (aquí reducido a 7 en 2) |

## Decisiones tomadas durante la implementación

Esta sección la llena el agente (OpenCode) cuando encuentra algo ambiguo y elige la opción más simple. Las decisiones deben estar numeradas y fechadas.

1. **Carga de escenarios (Nov 25, 2026)**: Los archivos de escenarios definen un predicado `cargar_datos/0` que usa `assertz` para agregar los hechos dinámicos. `cargar_escenario/1` limpia la base de datos, consulta el archivo y llama a `cargar_datos/0`. Esto es más simple que intentar módulos complejos y permite generar lecturas repetitivas con bucles.

---

*Última actualización: Nov 25, 2026*
