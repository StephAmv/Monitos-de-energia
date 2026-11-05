#!/bin/bash
# Script de prueba para verificar la API

echo "=== Probando API del Monitor de Energia ==="
echo ""

echo "1. Esperando que el servidor este listo..."
sleep 3

echo ""
echo "2. Obteniendo estado del edificio..."
curl -s http://localhost:8080/api/edificio | jq '.total_kw, .total_kwh, .medidores | length' || echo "Error: asegurate de que el servidor este corriendo con 'rebar3 shell'"

echo ""
echo "3. Probando simulacion de pico (Piso 1, Medidor 1)..."
curl -s -X POST http://localhost:8080/api/demo/pico/1/1

echo ""
echo "4. Esperando 2 segundos..."
sleep 2

echo ""
echo "5. Verificando alarmas..."
curl -s http://localhost:8080/api/edificio | jq '.alarmas'

echo ""
echo "6. Probando simulacion de falla (Piso 2, Medidor 2)..."
curl -s -X POST http://localhost:8080/api/demo/falla/2/2

echo ""
echo "7. Esperando 2 segundos para que se recupere..."
sleep 2

echo ""
echo "8. Verificando que el medidor se recupero..."
curl -s http://localhost:8080/api/edificio | jq '.medidores[] | select(.piso == 2 and .id == 2)'

echo ""
echo ""
echo "=== Pruebas completadas ==="
echo "Abre http://localhost:8080 en tu navegador para ver la interfaz"
