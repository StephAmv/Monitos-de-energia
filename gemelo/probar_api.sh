#!/bin/bash
# probar_api.sh - Prueba la API del gemelo digital

echo "=== Iniciando servidor en segundo plano ==="
swipl servidor.pl &
PID=$!
sleep 3

echo -e "\n=== GET /api/escenarios ==="
curl -s http://localhost:8080/api/escenarios | head -20

echo -e "\n\n=== GET /api/estado ==="
curl -s http://localhost:8080/api/estado | head -20

echo -e "\n\n=== GET /api/demanda ==="
curl -s http://localhost:8080/api/demanda

echo -e "\n\n=== GET /api/decide?entidad=ventana ==="
curl -s http://localhost:8080/api/decide?entidad=ventana

echo -e "\n\n=== Cambiando a escenario s1b ==="
curl -s http://localhost:8080/api/escenario?nombre=s1b

echo -e "\n\n=== GET /api/demanda (s1b) ==="
curl -s http://localhost:8080/api/demanda

echo -e "\n\n=== GET /api/hipotesis (mover compresor 600s) ==="
curl -s "http://localhost:8080/api/hipotesis?motor=compresor&retraso=600"

echo -e "\n\n=== Deteniendo servidor ==="
kill $PID
echo "Pruebas completadas"
