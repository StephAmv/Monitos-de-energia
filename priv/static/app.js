// Monitor de Energia - Logica de interfaz
// Sin frameworks, JavaScript vanilla

(function() {
    'use strict';
    
    // Estado de la aplicacion
    let estadoConexion = true;
    let intervaloActualizacion = null;
    let datosEdificio = null;
    
    // Elementos del DOM
    const elementos = {
        totalKw: document.getElementById('total-kw'),
        totalKwh: document.getElementById('total-kwh'),
        totalAlarmas: document.getElementById('total-alarmas'),
        alarmasContainer: document.getElementById('alarmas-container'),
        pisosContainer: document.getElementById('pisos-container'),
        timestamp: document.getElementById('timestamp'),
        jsonData: document.getElementById('json-data'),
        estadoConexion: document.getElementById('estado-conexion')
    };
    
    // Obtener datos del edificio desde la API
    async function obtenerDatosEdificio() {
        try {
            const response = await fetch('/api/edificio');
            
            if (!response.ok) {
                throw new Error('Error en la respuesta del servidor');
            }
            
            const datos = await response.json();
            
            // Marcar como conectado
            if (!estadoConexion) {
                estadoConexion = true;
                actualizarEstadoConexion();
            }
            
            return datos;
            
        } catch (error) {
            console.error('Error al obtener datos:', error);
            
            // Marcar como desconectado
            if (estadoConexion) {
                estadoConexion = false;
                actualizarEstadoConexion();
            }
            
            return null;
        }
    }
    
    // Actualizar indicador de estado de conexion
    function actualizarEstadoConexion() {
        if (estadoConexion) {
            elementos.estadoConexion.textContent = 'En vivo';
            elementos.estadoConexion.className = 'estado-conexion conectado';
        } else {
            elementos.estadoConexion.textContent = 'Reconectando...';
            elementos.estadoConexion.className = 'estado-conexion desconectado';
        }
    }
    
    // Actualizar totales del edificio
    function actualizarTotales(datos) {
        elementos.totalKw.textContent = datos.total_kw.toFixed(2);
        elementos.totalKwh.textContent = datos.total_kwh.toFixed(2);
        elementos.totalAlarmas.textContent = datos.alarmas.length;
    }
    
    // Actualizar seccion de alarmas
    function actualizarAlarmas(datos) {
        const alarmas = datos.alarmas;
        
        if (alarmas.length === 0) {
            // Sin alarmas
            elementos.alarmasContainer.innerHTML = `
                <div class="alarmas sin-alarmas">
                    <h2>Estado del Sistema</h2>
                    <p><strong>Todo en orden</strong> - No hay alarmas activas</p>
                </div>
            `;
        } else {
            // Con alarmas
            let htmlAlarmas = `
                <div class="alarmas">
                    <h2>Alarmas Activas (${alarmas.length})</h2>
                    <ul>
            `;
            
            alarmas.forEach(alarma => {
                const claseEstado = alarma.estado === 'critico' ? 'critico' : 'alerta';
                const estadoTexto = alarma.estado.toUpperCase();
                
                htmlAlarmas += `
                    <li>
                        <span class="${claseEstado}">
                            Piso ${alarma.piso}, Medidor ${alarma.id}: 
                            ${alarma.kw.toFixed(2)} kW
                        </span>
                        (${estadoTexto}, umbral: ${alarma.umbral.toFixed(1)} kW)
                    </li>
                `;
            });
            
            htmlAlarmas += `
                    </ul>
                </div>
            `;
            
            elementos.alarmasContainer.innerHTML = htmlAlarmas;
        }
    }
    
    // Obtener todos los medidores de los datos
    function obtenerTodosMedidores(datos) {
        const medidores = [];
        
        // Hacemos un fetch sincrono de los medidores desde el JSON completo
        // Los datos vienen en el formato que genera energia_datos:edificio_completo()
        // Necesitamos reconstruir la lista completa de medidores
        
        // Como no tenemos la lista completa en el JSON de /api/edificio,
        // debemos obtenerla haciendo peticiones individuales o desde otra fuente
        // Por ahora, asumimos que tenemos acceso a los datos completos
        
        return medidores;
    }
    
    // Actualizar tarjetas de pisos y medidores
    function actualizarPisos(datos) {
        // Necesitamos obtener los medidores individuales
        // Los datos actuales solo tienen agregados por piso
        // Vamos a hacer peticiones adicionales o reconstruir desde el JSON
        
        // Por ahora, generamos la vista basada en lo que tenemos
        // y hacemos fetch individual de cada medidor
        
        const pisos = datos.pisos || [];
        
        let html = '';
        
        pisos.forEach(piso => {
            html += generarTarjetaPiso(piso, datos);
        });
        
        elementos.pisosContainer.innerHTML = html;
        
        // Agregar event listeners a los botones
        agregarEventListenersBotones();
    }
    
    // Generar HTML para una tarjeta de piso
    function generarTarjetaPiso(piso, datosCompletos) {
        const numeroPiso = piso.piso;
        
        // Filtrar medidores de este piso de las alarmas y crear una lista completa
        // Como no tenemos todos los medidores en el JSON, necesitamos hacer suposiciones
        // basadas en la configuracion (2 pisos x 3 medidores)
        
        const medidoresPorPiso = 3; // De la configuracion
        
        let html = `
            <div class="piso-card">
                <div class="piso-header">
                    <div class="piso-titulo">Piso ${numeroPiso}</div>
                    <div class="piso-consumo">
                        ${piso.total_kw.toFixed(2)} kW | 
                        ${piso.total_kwh.toFixed(2)} kWh acumulados
                    </div>
                </div>
                <div class="medidores-grid" id="medidores-piso-${numeroPiso}">
        `;
        
        // Generar placeholder para los medidores
        // Los datos reales se cargaran de forma asincrona
        for (let i = 1; i <= medidoresPorPiso; i++) {
            html += `
                <div class="medidor-card" id="medidor-p${numeroPiso}-m${i}">
                    <div class="medidor-header">
                        <div class="medidor-titulo">Medidor ${i}</div>
                        <span class="medidor-estado">Cargando...</span>
                    </div>
                    <div class="medidor-datos">
                        <div><span>Consumo:</span><span>-- kW</span></div>
                        <div><span>Acumulado:</span><span>-- kWh</span></div>
                        <div><span>Umbral:</span><span>-- kW</span></div>
                    </div>
                    <div class="medidor-botones">
                        <button class="btn btn-pico" data-piso="${numeroPiso}" data-medidor="${i}">
                            Simular pico
                        </button>
                        <button class="btn btn-falla" data-piso="${numeroPiso}" data-medidor="${i}">
                            Simular falla
                        </button>
                    </div>
                </div>
            `;
        }
        
        html += `
                </div>
            </div>
        `;
        
        return html;
    }
    
    // Obtener datos de un medidor individual
    async function obtenerDatosMedidor(piso, medidor) {
        // Como no tenemos endpoint individual, buscamos en los datos completos
        // que ya tenemos cargados
        
        if (!datosEdificio) {
            return null;
        }
        
        // Buscar en las alarmas
        const alarma = datosEdificio.alarmas.find(a => a.piso === piso && a.id === medidor);
        
        if (alarma) {
            return alarma;
        }
        
        // Si no esta en alarmas, necesitamos calcularlo desde los totales
        // Esto es una limitacion del API actual - solo tenemos agregados
        // En una version real, tendriamos /api/medidor/:piso/:id
        
        return null;
    }
    
    // Actualizar vista de un medidor especifico
    function actualizarMedidor(piso, medidor, datos) {
        const elementoId = `medidor-p${piso}-m${medidor}`;
        const elemento = document.getElementById(elementoId);
        
        if (!elemento || !datos) {
            return;
        }
        
        const estado = datos.estado || 'normal';
        const kw = datos.kw || 0;
        const kwh = datos.kwh || 0;
        const umbral = datos.umbral || 10;
        
        // Actualizar clases
        elemento.className = `medidor-card ${estado}`;
        
        // Actualizar contenido
        elemento.innerHTML = `
            <div class="medidor-header">
                <div class="medidor-titulo">Medidor ${medidor}</div>
                <span class="medidor-estado ${estado}">${estado}</span>
            </div>
            <div class="medidor-datos">
                <div><span>Consumo:</span><span>${kw.toFixed(2)} kW</span></div>
                <div><span>Acumulado:</span><span>${kwh.toFixed(2)} kWh</span></div>
                <div><span>Umbral:</span><span>${umbral.toFixed(1)} kW</span></div>
            </div>
            <div class="medidor-botones">
                <button class="btn btn-pico" data-piso="${piso}" data-medidor="${medidor}">
                    Simular pico
                </button>
                <button class="btn btn-falla" data-piso="${piso}" data-medidor="${medidor}">
                    Simular falla
                </button>
            </div>
        `;
        
        // Re-agregar event listeners
        const btnPico = elemento.querySelector('.btn-pico');
        const btnFalla = elemento.querySelector('.btn-falla');
        
        if (btnPico) {
            btnPico.addEventListener('click', manejarBotonPico);
        }
        
        if (btnFalla) {
            btnFalla.addEventListener('click', manejarBotonFalla);
        }
    }
    
    // Agregar event listeners a todos los botones
    function agregarEventListenersBotones() {
        // Botones de pico
        document.querySelectorAll('.btn-pico').forEach(btn => {
            btn.addEventListener('click', manejarBotonPico);
        });
        
        // Botones de falla
        document.querySelectorAll('.btn-falla').forEach(btn => {
            btn.addEventListener('click', manejarBotonFalla);
        });
    }
    
    // Manejar click en boton "Simular pico"
    async function manejarBotonPico(evento) {
        const boton = evento.target;
        const piso = boton.dataset.piso;
        const medidor = boton.dataset.medidor;
        
        boton.disabled = true;
        boton.textContent = 'Enviando...';
        
        try {
            const response = await fetch(`/api/demo/pico/${piso}/${medidor}`, {
                method: 'POST'
            });
            
            if (response.ok) {
                boton.textContent = 'Pico activado';
                setTimeout(() => {
                    boton.disabled = false;
                    boton.textContent = 'Simular pico';
                }, 2000);
            } else {
                throw new Error('Error al activar pico');
            }
            
        } catch (error) {
            console.error('Error al simular pico:', error);
            boton.textContent = 'Error';
            setTimeout(() => {
                boton.disabled = false;
                boton.textContent = 'Simular pico';
            }, 2000);
        }
    }
    
    // Manejar click en boton "Simular falla"
    async function manejarBotonFalla(evento) {
        const boton = evento.target;
        const piso = boton.dataset.piso;
        const medidor = boton.dataset.medidor;
        
        boton.disabled = true;
        boton.textContent = 'Enviando...';
        
        try {
            const response = await fetch(`/api/demo/falla/${piso}/${medidor}`, {
                method: 'POST'
            });
            
            if (response.ok) {
                boton.textContent = 'Falla activada';
                setTimeout(() => {
                    boton.disabled = false;
                    boton.textContent = 'Simular falla';
                }, 2000);
            } else {
                throw new Error('Error al activar falla');
            }
            
        } catch (error) {
            console.error('Error al simular falla:', error);
            boton.textContent = 'Error';
            setTimeout(() => {
                boton.disabled = false;
                boton.textContent = 'Simular falla';
            }, 2000);
        }
    }
    
    // Actualizar timestamp
    function actualizarTimestamp() {
        const ahora = new Date();
        elementos.timestamp.textContent = ahora.toLocaleTimeString('es-ES');
    }
    
    // Actualizar JSON de debug
    function actualizarJsonDebug(datos) {
        elementos.jsonData.textContent = JSON.stringify(datos, null, 2);
    }
    
    // Necesitamos obtener los datos individuales de cada medidor
    // Como el API actual solo devuelve agregados, vamos a hacer una peticion
    // especial o modificar la logica para extraer los datos
    
    // Por ahora, vamos a hacer una solucion: guardar todos los medidores
    // cuando obtengamos los datos completos
    
    let todosLosMedidores = [];
    
    // Extraer todos los medidores del JSON completo
    function extraerMedidoresCompletos(datos) {
        // Ahora el API devuelve todos los medidores en el campo 'medidores'
        return datos.medidores || [];
    }
    
    // Funcion principal de actualizacion
    async function actualizar() {
        const datos = await obtenerDatosEdificio();
        
        if (!datos) {
            // Sin datos, mantener la interfaz como esta
            return;
        }
        
        // Guardar datos globalmente
        datosEdificio = datos;
        
        // Extraer medidores completos
        todosLosMedidores = extraerMedidoresCompletos(datos);
        
        // Actualizar todas las secciones
        actualizarTotales(datos);
        actualizarAlarmas(datos);
        actualizarPisos(datos);
        actualizarTimestamp();
        actualizarJsonDebug(datos);
        
        // Actualizar medidores individuales
        todosLosMedidores.forEach(medidor => {
            actualizarMedidor(medidor.piso, medidor.id, medidor);
        });
    }
    
    // Iniciar la aplicacion
    function iniciar() {
        console.log('Iniciando monitor de energia...');
        
        // Primera actualizacion inmediata
        actualizar();
        
        // Actualizar cada 2 segundos
        intervaloActualizacion = setInterval(actualizar, 2000);
    }
    
    // Iniciar cuando el DOM este listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', iniciar);
    } else {
        iniciar();
    }
    
})();
