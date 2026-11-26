// Datos de ejemplo SOLO para ver el diseno sin servidor: abre la pagina con ?demo
// Son respuestas copiadas de lo que debe contestar el gemelo (PLAN.md). No hay reglas aqui.
(() => {
  let actual = "s1b";
  const desc = {
    s0_normal: "Todo en orden, lecturas frescas", s1a: "Pico de 70 kW brevísimo al inicio de la ventana",
    s1b: "Carga sostenida y tres arranques previstos", s2: "El contador del alumbrado vuelve a cero",
    s3: "Un medidor lento retrasa a los de su bus", s4a: "Cae el voltaje en todo el edificio",
    s4b: "Cae el piso 1 tras arrancar el compresor", s4c: "Cae el piso 1 pero hay timeouts", s5: "Un día completo del medidor compartido"
  };
  const med = (id, piso, bus, turno, ms, edad, v, kw, estado = "fresco", rol = "normal") => ({ id, piso, bus, turno, ultimo_ms: ms, edad_s: edad, v, kw, estado, rol });
  const base = () => [
    med("acometida", "acometida", "bus_a", 1, 38, 5, 126.8, 36.0),
    med("p1_general", "piso1", "bus_a", 2, 44, 5, 126.4, 14.2),
    med("p1_motores", "piso1", "bus_a", 3, 41, 5, 126.1, 0.0),
    med("p1_alumbrado", "piso1", "bus_a", 4, 47, 5, 126.5, 2.1),
    med("p2_general", "piso2", "bus_b", 1, 33, 5, 127.0, 12.6),
    med("p2_compartido", "piso2", "bus_b", 2, 36, 5, 126.9, 6.0),
    med("p3_aulas", "piso3", "bus_b", 3, 39, 5, 126.7, 9.2)
  ];
  const pisos = (e) => [
    { piso: "piso1", kw: e === "s3" ? null : 14.2, estado: e === "s3" ? "no_se" : (e.startsWith("s4") && e !== "s4a" ? "anticipada" : "normal"), detalle: e === "s3" ? "Lecturas viejas por el bus" : "3 motores · alumbrado" },
    { piso: "piso2", kw: 12.6, estado: "normal", detalle: "Medidor compartido (estimación)" },
    { piso: "piso3", kw: 9.2, estado: "normal", detalle: "Aulas" }
  ];
  const estado = () => {
    const m = base();
    if (actual === "s3") {
      Object.assign(m[1], { ultimo_ms: 900, rol: "causante" });
      Object.assign(m[2], { ultimo_ms: null, edad_s: 20, v: null, kw: null, estado: "viejo", rol: "victima" });
      Object.assign(m[3], { ultimo_ms: null, edad_s: 40, v: null, kw: null, estado: "timeout", rol: "victima" });
    }
    return { ahora: { s1b: 43860, s1a: 43320, s3: 50700, s5: 86000 }[actual] ?? 45000, medidores: m, pisos: pisos(actual) };
  };
  const demanda = () => ({
    s1a: { inicio: 43200, fin: 44100, ahora: 43320, progreso: 0.133, restante_s: 780, acumulado_kws: 4350, acumulado_kw: 4.83, proyectado_kw: 26.5, limite_kw: 40, margen_kw: 13.5, alarma: "ninguna", certeza: "firme", faltantes: [], recomendacion: null,
      explicacion: ["Pico de 70 kW durante 30 s al inicio de la ventana", "Después 25 kW sostenidos", "Acumulado: 4 350 kW·s", "Restan 780 s a 25 kW = 19 500 kW·s", "Promedio proyectado: 26.5 kW, bajo el límite de 40 kW"] },
    s3: { inicio: 50400, fin: 51300, ahora: 50700, progreso: 0.333, restante_s: 600, acumulado_kws: 9000, acumulado_kw: 30, proyectado_kw: 30, limite_kw: 40, margen_kw: 10, alarma: "no_puedo_decir", certeza: "no_se", faltantes: [], recomendacion: null,
      explicacion: ["La acometida marca 30 kW (lectura fresca)", "La lectura de p1_motores tiene 20 s: está vieja", "Está vieja porque p1_general (turno 2) tarda 750–900 ms", "No sé si los motores ya arrancaron", "El margen (10 kW) es menor que la potencia de motores que podría esconderse (22.2 kW)"] }
  }[actual] || { inicio: 43200, fin: 44100, ahora: 43860, progreso: 0.733, restante_s: 240, acumulado_kws: 23760, acumulado_kw: 26.4, proyectado_kw: 40.57, limite_kw: 40, margen_kw: -0.57, alarma: "anticipada", certeza: "estimacion", faltantes: [43500],
    recomendacion: { motor: "compresor", hasta: 44100, se_le_falla_a: "taller", proyectado_kw: 38.37 },
    explicacion: ["Acumulado en la ventana: 23 760 kW·s (falta la lectura de 12:05:00)", "Potencia actual: 36 kW × 240 s restantes = 8 640 kW·s", "Arranques previstos: bomba 12:11:30, compresor 12:12:00, extractor 12:12:30 → 4 110 kW·s", "Promedio proyectado: 40.57 kW contra un límite de 40 kW", "Diferir el compresor (prioridad 3) deja la ventana en 38.37 kW"] });
  const R = {
    "/api/escenarios": () => ({ actual, escenarios: Object.keys(desc).map(nombre => ({ nombre, descripcion: desc[nombre] })) }),
    "/api/estado": estado,
    "/api/demanda": demanda,
    "/api/que_falta": () => ({ cambios: ["Bajar 2.13 kW de aquí al cierre (510 kW·s en 240 s)", "o diferir el extractor → 39.95 kW", "o diferir el compresor → 38.37 kW", "o diferir la bomba → 38.82 kW"] }),
    "/api/hipotesis": () => ({ antes: { alarma: "anticipada", proyectado_kw: 40.57 }, despues: { alarma: "ninguna", proyectado_kw: 38.37 },
      explicacion: ["El compresor arrancaría a las 12:22:00, fuera de la ventana", "Sin sus 1 980 kW·s el promedio queda en 38.37 kW"] }),
    "/api/situaciones": () => ({
      s3: [{ entidad: "p1_general", situacion: "medidor_lento", evidencia: ["750, 820 y 900 ms en sus últimas 3 consultas", "Es el primero lento del bus A"], certeza: "firme" },
        { entidad: "p1_motores", situacion: "lectura_atrasada", evidencia: ["Edad 20 s", "Víctima de p1_general"] },
        { entidad: "p1_alumbrado", situacion: "lectura_atrasada", evidencia: ["3 timeouts", "Víctima de p1_general, no causante"] }],
      s5: [{ entidad: "laboratorio", situacion: "consumo_nocturno_esperado", evidencia: ["1.6 kW de madrugada ≤ base 1.5 kW × 1.2"], certeza: "estimacion" }]
    }[actual] || [{ entidad: "ventana", situacion: "rebase_proyectado", evidencia: ["Cierre proyectado 40.57 kW contra 40 kW"], certeza: "estimacion" }]),
    "/api/caida": (q) => {
      const piso = q.get("piso");
      if (piso !== "piso1" && actual !== "s4a") return { causa: "sin_caida", evidencia: [], descartada: [], dato_que_falta: [] };
      return {
        s4a: { causa: "red", evidencia: ["Acometida 108 V a las 08:20:00", "Pisos 2 y 3 (sin motores) también bajo 114 V"], descartada: ["Arranque de motores: cayeron pisos que no tienen motores"], dato_que_falta: [] },
        s4c: { causa: "no_se_puede_decir", evidencia: ["P1 · General 108 V a las 08:20:00"], descartada: [], dato_que_falta: ["Voltaje de la acometida a las 08:20:00 (timeout)", "Potencia de p1_motores a las 08:20:00 (timeout)"] }
      }[actual] || { causa: "arranque_motores", evidencia: ["Arranque del compresor a las 08:19:55", "p1_motores subió de 0 a 11 kW antes de la caída", "P1 · General 108 V; acometida 124 V"], descartada: ["Red de CFE: la acometida no cayó"], dato_que_falta: ["Si la acometida también hubiera caído, sería la red"] };
    },
    "/api/reparto": () => ({
      regla: "Fuera del horario de oficinas todo es del laboratorio. En horario, primero la base del laboratorio (1.5 kW) y el resto 30 % laboratorio / 70 % oficinas. Desempate: gana la base del laboratorio.",
      certeza: "estimacion",
      energia: { lab: 54.33, ofi: 30.63 },
      demanda: { lab: 3.75, ofi: 5.25, pct_lab: 41.7, pct_ofi: 58.3, ventana: 57600 },
      nota: "El laboratorio consume más energía en el día (equipos 24 h), pero en la ventana máxima de las 16:00 pesan más las oficinas: quien más consume no es quien más pesa en la demanda.",
      fp: { valor: 0.874, minimo: 0.9, penaliza: true, texto: "En la ventana de las 16:00 el FP baja de 0.90. La penalización se reparte 41.7 % / 58.3 %, igual que la demanda." },
      nocturno: { estado: "esperado", explicacion: ["1.6 kW de madrugada; la base declarada del laboratorio con tolerancia es 1.8 kW: no es anomalía."] },
      se_le_falla_a: [
        { area: "laboratorio", si: "si su base real es menor a 1.5 kW, paga de más" },
        { area: "laboratorio", si: "si las oficinas dejan equipos encendidos de noche, el laboratorio paga ese consumo" },
        { area: "oficinas", si: "si su carga declarada está inflada, pagan de más en la demanda" }]
    })
  };
  window.DEMO_API = async (ruta) => {
    const u = new URL(ruta, location.origin);
    if (u.pathname === "/api/escenario") { actual = u.searchParams.get("nombre"); return { actual }; }
    await new Promise(r => setTimeout(r, 120));
    return R[u.pathname](u.searchParams);
  };
})();
