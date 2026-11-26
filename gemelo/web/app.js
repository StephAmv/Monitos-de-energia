// Gemelo digital - Monitor de energia
// Interfaz: SOLO pregunta al gemelo (Prolog) y pinta. Ninguna regla del dominio vive aqui:
// no hay umbrales ni comparaciones de kW contra el limite; el color sale del campo de estado
// que manda Prolog. Lo unico que se calcula son anchos de barras para dibujar.

(() => {
  "use strict";

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const params = new URLSearchParams(location.search);
  const MODO_DEMO = params.has("demo");
  const REFRESCO_MS = 5 * 1000; // igual que el ciclo de consulta

  // ---------- Textos (solo presentacion) ----------
  const ETIQUETAS = {
    ninguna: "Ninguna", anticipada: "Anticipada", vigente: "Vigente",
    no_puedo_decir: "No puedo decir", no_se_puede_decir: "No se puede decir", no_se: "No sé",
    firme: "Firme", estimacion: "Estimación",
    fresco: "Fresco", viejo: "Lectura vieja", timeout: "Timeout", sin_dato: "Sin dato",
    causante: "Causante", victima: "Víctima", normal: "Normal",
    red: "Red de CFE", arranque_motores: "Arranque de motores", medidor_local: "Falla local del medidor", sin_caida: "Sin caída",
    esperado: "Esperado", anomalia: "Anomalía",
    rebase_proyectado: "Rebase proyectado", rebase_vigente: "Rebase vigente",
    contador_reiniciado: "Contador reiniciado", contador_desbordado: "Contador desbordado",
    dato_corrupto: "Dato corrupto", medidor_lento: "Medidor lento", lectura_atrasada: "Lectura atrasada",
    caida_por_arranque: "Caída por arranque", caida_de_red: "Caída de red",
    consumo_nocturno_esperado: "Consumo nocturno esperado", consumo_nocturno_anomalo: "Consumo nocturno anómalo",
    piso1: "Piso 1", piso2: "Piso 2", piso3: "Piso 3", acometida: "Acometida",
    laboratorio: "Laboratorio", oficinas: "Oficinas", taller: "Taller", aulas: "Aulas",
    bomba: "Bomba de cisterna", compresor: "Compresor", extractor: "Extractor",
    bus_a: "Bus A", bus_b: "Bus B", ventana: "Ventana de demanda"
  };
  const MEDIDORES = {
    acometida: ["Acometida", "Entrada del edificio"],
    p1_general: ["P1 · General", "Tablero del piso 1"],
    p1_motores: ["P1 · Motores", "Bomba, compresor y extractor"],
    p1_alumbrado: ["P1 · Alumbrado", "Iluminación del taller"],
    p2_general: ["P2 · General", "Tablero del piso 2"],
    p2_compartido: ["P2 · Compartido", "Laboratorio + oficinas"],
    p3_aulas: ["P3 · Aulas", "Piso 3 completo"]
  };
  const PISOS = { piso1: "Taller", piso2: "Laboratorio y oficinas", piso3: "Aulas" };
  const ESCENARIOS = {
    s0_normal: "Normal", s1a: "Pico breve", s1b: "Carga sostenida", s2: "Contador",
    s3: "Medidor lento", s4a: "Caída · red", s4b: "Caída · motores", s4c: "Caída · sin datos", s5: "Reparto"
  };

  // Tono visual de cada estado que manda Prolog (no es una regla: es la paleta)
  const TONO = {
    ok: ["ninguna", "normal", "fresco", "ok", "esperado", "sin_caida", "sin_problema", "firme", "si", "consumo_nocturno_esperado"],
    warn: ["anticipada", "estimacion", "victima", "viejo", "anomalia", "arranque_motores", "medidor_local", "rebase_proyectado",
      "contador_reiniciado", "contador_desbordado", "caida_por_arranque", "consumo_nocturno_anomalo", "diferir"],
    bad: ["vigente", "causante", "falla", "critico", "red", "rebase_vigente", "dato_corrupto", "medidor_lento", "caida_de_red", "penaliza", "aislar"],
    unk: ["no_se", "no_puedo_decir", "no_se_puede_decir", "desconocido", "sin_dato", "timeout", "lectura_atrasada"]
  };
  const tono = (e) => {
    const k = norm(e);
    for (const [t, l] of Object.entries(TONO)) if (l.includes(k)) return t;
    return "unk";
  };

  // ---------- Utilidades ----------
  function norm(x) { return String(x ?? "").trim().toLowerCase().replace(/\s+/g, "_").normalize("NFD").replace(/[̀-ͯ]/g, ""); }
  function etiqueta(x) {
    if (x === null || x === undefined || x === "") return "—";
    const k = norm(x);
    if (ETIQUETAS[k]) return ETIQUETAS[k];
    const s = String(x).replace(/_/g, " ");
    return s.charAt(0).toUpperCase() + s.slice(1);
  }
  function lista(x) {
    if (x === null || x === undefined || x === "") return [];
    if (Array.isArray(x)) return x.map(texto).filter(Boolean);
    return [texto(x)];
  }
  function texto(x) {
    if (x === null || x === undefined) return "";
    if (typeof x === "string") return x;
    if (typeof x === "number" || typeof x === "boolean") return String(x);
    if (Array.isArray(x)) return x.map(texto).join(", ");
    if (x.texto) return x.texto;
    return Object.entries(x).map(([k, v]) => `${etiqueta(k)}: ${texto(v)}`).join(" · ");
  }
  function esNum(x) { return typeof x === "number" && isFinite(x); }
  function n(x, dec = 1) { return esNum(x) ? x.toLocaleString("es-MX", { minimumFractionDigits: dec, maximumFractionDigits: dec }) : "—"; }
  function hora(x) {
    if (!esNum(x)) return x ?? "—";
    const s = Math.max(0, Math.round(x)), h = Math.floor(s / 3600) % 24, m = Math.floor(s / 60) % 60, ss = s % 60;
    return [h, m, ss].map(v => String(v).padStart(2, "0")).join(":");
  }
  function duracion(seg) {
    if (!esNum(seg)) return "—";
    if (seg < 60) return `${Math.round(seg)} s`;
    const m = Math.floor(seg / 60), s = Math.round(seg % 60);
    return s ? `${m} min ${s} s` : `${m} min`;
  }
  function esc(s) { return String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])); }
  const pick = (o, ...ks) => { for (const k of ks) if (o && o[k] !== undefined && o[k] !== null) return o[k]; return undefined; };
  const chip = (estado, txt, extra = "") => `<span class="chip ${tono(estado)} ${extra}">${esc(txt ?? etiqueta(estado))}</span>`;
  function setChip(el, estado, txt, vivo = false) {
    if (!el) return;
    el.className = `chip ${tono(estado)}${vivo ? " vivo" : ""}`;
    el.textContent = txt ?? etiqueta(estado);
  }
  const icono = (id) => `<svg><use href="#${id}"/></svg>`;

  // ---------- Conexion con el gemelo ----------
  async function api(ruta) {
    if (MODO_DEMO) return window.DEMO_API(ruta);
    const r = await fetch(ruta, { headers: { Accept: "application/json" }, cache: "no-store" });
    if (!r.ok) {
      let msg = `HTTP ${r.status}`;
      try { msg = (await r.json()).error || msg; } catch (_) { /* sin cuerpo */ }
      throw new Error(msg);
    }
    return r.json();
  }
  let fallos = 0;
  function estadoConexion(ok, err) {
    const c = $("#conexion");
    if (ok) {
      fallos = 0;
      c.className = "conexion en-linea";
      c.lastElementChild.textContent = MODO_DEMO ? "Modo demo (sin servidor)" : "Gemelo en línea";
      $("#toast").classList.add("oculto");
    } else {
      fallos++;
      c.className = "conexion caida";
      c.lastElementChild.textContent = "Sin conexión";
      if (fallos === 1) toast(`No pude hablar con el gemelo (${esc(err?.message || "error")}). Revisa que esté corriendo <code>swipl servidor.pl</code>. En WSL abre la página con la IP de <code>hostname -I</code>, no con localhost.`);
    }
  }
  function toast(html) { const t = $("#toast"); t.innerHTML = html; t.classList.remove("oculto"); }

  async function seguro(fn, ...args) {
    try { await fn(...args); estadoConexion(true); }
    catch (e) { console.error(e); estadoConexion(false, e); }
  }

  // ---------- Navegacion ----------
  function irA(vista) {
    if (!["panel", "medidores", "alarmas", "reparto"].includes(vista)) vista = "panel";
    $$(".vista").forEach(v => v.classList.toggle("activa", v.id === `vista-${vista}`));
    $$(".nav a").forEach(a => a.classList.toggle("activo", a.dataset.vista === vista));
    window.scrollTo({ top: 0, behavior: "instant" in window ? "instant" : "auto" });
    cargarVista(vista);
  }
  const vistaActual = () => (location.hash || "#panel").slice(1);
  window.addEventListener("hashchange", () => irA(vistaActual()));

  function cargarVista(v) {
    if (v === "panel") seguro(cargarDemanda);
    if (v === "medidores") seguro(cargarEstado);
    if (v === "alarmas") { seguro(cargarSituaciones); seguro(cargarCaida, pisoCaida); }
    if (v === "reparto") seguro(cargarReparto);
  }

  // ---------- Escenarios ----------
  async function cargarEscenarios() {
    const d = await api("/api/escenarios");
    const lst = pick(d, "escenarios") || (Array.isArray(d) ? d : []);
    const actual = pick(d, "actual");
    const sel = $("#escenario");
    sel.innerHTML = lst.map(e => {
      const nom = typeof e === "string" ? e : e.nombre;
      const desc = typeof e === "string" ? "" : (e.descripcion || "");
      return `<option value="${esc(nom)}" title="${esc(desc)}">${esc(ESCENARIOS[nom] || etiqueta(nom))}</option>`;
    }).join("");
    if (actual) sel.value = actual;
  }
  async function cambiarEscenario(nombre) {
    document.body.classList.add("cargando");
    await api(`/api/escenario?nombre=${encodeURIComponent(nombre)}`);
    $("#que-falta").classList.add("oculto");
    $("#hipotesis").classList.add("oculto");
    await refrescarTodo();
    document.body.classList.remove("cargando");
  }

  // ---------- Estado general (medidores y pisos) ----------
  let ultimoEstado = null;
  async function cargarEstado() {
    const d = await api("/api/estado");
    ultimoEstado = d;
    const ahora = pick(d, "ahora", "ahora_hora");
    if (ahora !== undefined) $("#ahora").textContent = hora(ahora);
    pintarPisos(d);
    pintarMedidores(d);
  }

  function pisosDe(d) {
    const ps = pick(d, "pisos") || [];
    return ps.map(p => ({
      id: pick(p, "piso", "id"),
      nombre: pick(p, "nombre") || `${etiqueta(pick(p, "piso", "id"))} · ${PISOS[pick(p, "piso", "id")] || ""}`,
      kw: pick(p, "kw", "total_kw"),
      estado: pick(p, "estado") || "no_se",
      detalle: pick(p, "detalle", "texto")
    }));
  }

  function pintarPisos(d) {
    const ps = pisosDe(d);
    $("#lista-pisos").innerHTML = ps.length ? ps.map(p => `
      <div class="piso-item">
        <div><b>${esc(p.nombre)}</b><small>${esc(p.detalle ? texto(p.detalle) : etiqueta(p.estado))}</small></div>
        <div style="display:flex;gap:10px;align-items:center"><span class="kw">${esNum(p.kw) ? n(p.kw) + " kW" : "—"}</span>${chip(p.estado)}</div>
      </div>`).join("") : `<div class="vacio">El gemelo no mandó pisos.</div>`;
    $("#nav-pisos").innerHTML = ps.map(p => `<div><span>${esc(etiqueta(p.id))}</span><b>${esNum(p.kw) ? n(p.kw) + " kW" : "no sé"}</b></div>`).join("");
  }

  function medidoresDe(d) {
    return (pick(d, "medidores") || []).map(m => {
      const id = pick(m, "id", "medidor", "nombre");
      const rol = pick(m, "rol") || "normal";
      const est = pick(m, "estado") || "sin_dato";
      return {
        id, rol, estado: est,
        nombre: (MEDIDORES[id] || [etiqueta(id)])[0],
        desc: pick(m, "descripcion") || (MEDIDORES[id] || [, ""])[1],
        piso: pick(m, "piso", "lugar"), bus: pick(m, "bus"), turno: pick(m, "turno", "orden"),
        ms: pick(m, "ultimo_ms", "ms"), edad: pick(m, "edad_s", "edad"),
        v: pick(m, "v", "voltaje"), kw: pick(m, "kw", "potencia"),
        // el tono de la fila: el rol manda (causante/victima); si es normal, manda la frescura
        tonoFila: rol !== "normal" ? tono(rol) : tono(est)
      };
    });
  }

  function etiquetaFila(m) {
    if (m.rol && m.rol !== "normal") return chip(m.rol);
    if (tono(m.estado) === "unk") return chip("no_se", "No sé");
    return chip(m.estado, etiqueta(m.estado === "fresco" ? "normal" : m.estado));
  }

  function pintarMedidores(d) {
    const ms = medidoresDe(d);
    const porId = Object.fromEntries(ms.map(m => [m.id, m]));
    const pisos = Object.fromEntries(pisosDe(d).map(p => [p.id, p]));

    // Arbol de topologia
    const ac = porId.acometida || { nombre: "Acometida", tonoFila: "unk" };
    const hijosDe = { piso1: ["p1_general", "p1_motores", "p1_alumbrado"], piso2: ["p2_general", "p2_compartido"], piso3: ["p3_aulas"] };
    const colorPunto = { ok: "var(--ok)", warn: "var(--warn)", bad: "var(--bad)", unk: "var(--unk)" };
    $("#arbol").innerHTML = `
      <div class="nodo raiz ${ac.tonoFila}">
        <span class="etiqueta-mono">Acometida · entrada del edificio</span>
        <b>${esc(ac.nombre)}</b>
        <div class="datos">${esNum(ac.v) ? n(ac.v) + " V" : "— V"} · ${esNum(ac.kw) ? n(ac.kw) + " kW" : "— kW"} ${etiquetaFila(ac)}</div>
      </div>
      <div class="conector"></div>
      <div class="ramas">
        ${["piso1", "piso2", "piso3"].map(pid => {
          const p = pisos[pid] || { estado: "no_se" };
          return `<div class="rama">
            <div class="nodo ${tono(p.estado)}">
              <span class="etiqueta-mono">${esc(etiqueta(pid))}</span>
              <b>${esc(PISOS[pid])}</b>
              <div class="datos">${esNum(p.kw) ? n(p.kw) + " kW" : "— kW"} ${chip(p.estado)}</div>
            </div>
            <div class="hijos">${hijosDe[pid].map(h => {
              const m = porId[h]; if (!m) return "";
              return `<div class="hijo"><span style="display:flex;gap:8px;align-items:center"><i class="p" style="background:${colorPunto[m.tonoFila]}"></i>${esc(m.nombre)}</span><span>${esNum(m.kw) ? n(m.kw) + " kW" : "no sé"}</span></div>`;
            }).join("")}</div>
          </div>`;
        }).join("")}
      </div>`;

    // Buses en orden de consulta
    const buses = {};
    ms.forEach(m => (buses[m.bus] ||= []).push(m));
    $("#buses").innerHTML = Object.keys(buses).sort().map(b => {
      const fil = buses[b].sort((a, c) => (a.turno ?? 0) - (c.turno ?? 0));
      const causante = fil.find(m => m.rol === "causante");
      return `<article class="tarjeta bus">
        <div class="tarjeta-cabeza">
          <h3><span class="bus-tag">${esc(etiqueta(b).toUpperCase())}</span> Orden de consulta</h3>
          ${causante ? chip("causante", `Retrasa: ${causante.nombre}`, "vivo") : chip("ok", "Sin retrasos")}
        </div>
        ${fil.map(m => `<div class="fila-bus ${m.tonoFila}">
          <span class="turno">${esc(m.turno ?? "?")}</span>
          <div><b>${esc(m.nombre)}</b><small>${esc(m.desc)}</small></div>
          <span class="ms">${esNum(m.ms) ? Math.round(m.ms) + " ms" : "timeout"}<br><small>${esNum(m.edad) ? "hace " + duracion(m.edad) : "sin lectura"}</small></span>
          ${etiquetaFila(m)}
        </div>`).join("")}
      </article>`;
    }).join("");

    // Tabla completa
    $("#tabla-medidores tbody").innerHTML = ms.map(m => `<tr>
      <td><b>${esc(m.nombre)}</b><br><small class="texto-suave">${esc(m.desc)}</small></td>
      <td>${esc(etiqueta(m.piso))}</td>
      <td class="mono">${esc(etiqueta(m.bus))} · ${esc(m.turno ?? "—")}</td>
      <td class="num">${esNum(m.ms) ? Math.round(m.ms) + " ms" : '<span class="sin-dato">timeout</span>'}</td>
      <td class="num">${esNum(m.edad) ? duracion(m.edad) : '<span class="sin-dato">—</span>'}</td>
      <td class="num">${esNum(m.v) ? n(m.v) + " V" : '<span class="sin-dato">—</span>'}</td>
      <td class="num">${esNum(m.kw) ? n(m.kw, 2) + " kW" : '<span class="sin-dato">—</span>'}</td>
      <td>${etiquetaFila(m)}</td>
    </tr>`).join("");
  }

  // ---------- Panel: ventana de demanda ----------
  let ultimaDemanda = null;
  async function cargarDemanda() {
    const d = await api("/api/demanda");
    ultimaDemanda = d;
    const alarma = pick(d, "alarma", "tipo") || "no_se";
    const certeza = pick(d, "certeza") || "no_se";
    const acum = pick(d, "acumulado_kw", "promedio_acumulado");
    const proy = pick(d, "proyectado_kw", "proyectado", "promedio_proyectado");
    const lim = pick(d, "limite_kw", "limite");
    const margen = pick(d, "margen_kw", "margen");
    const ahora = pick(d, "ahora");
    if (ahora !== undefined) $("#ahora").textContent = hora(ahora);

    $("#chips-ventana").innerHTML =
      chip(alarma, `Alarma: ${etiqueta(alarma)}`, tono(alarma) === "ok" ? "" : "vivo") +
      chip(certeza, `Certeza: ${etiqueta(certeza)}`);

    // Tiempo de la ventana (solo dibujo)
    const ini = pick(d, "inicio"), fin = pick(d, "fin");
    $("#pv-rango").textContent = `${hora(ini)} – ${hora(fin)}`;
    let prog = pick(d, "progreso");
    if (!esNum(prog) && esNum(ini) && esNum(fin) && esNum(ahora)) prog = (ahora - ini) / (fin - ini);
    $("#pv-barra").style.width = esNum(prog) ? `${Math.min(100, Math.max(0, prog * 100))}%` : "0";
    const rest = pick(d, "restante_s");
    $("#pv-restante").textContent = esNum(rest) ? `faltan ${duracion(rest)}` + (esNum(prog) ? ` · ${Math.round(prog * 100)} % transcurrido` : "") : "";

    // Metricas
    $("#v-acum").textContent = n(acum);
    const kws = pick(d, "acumulado_kws", "acumulado");
    $("#v-acum-pie").textContent = esNum(kws) ? `${n(kws, 0)} kW·s en lo que va de la ventana` : "promedio con lo ya consumido";
    $("#v-proy").textContent = n(proy);
    $("#v-lim").textContent = n(lim);
    $("#m-proy").className = `metrica ${tono(alarma)}`;
    $("#m-acum").className = `metrica ${tono(certeza) === "unk" ? "unk" : ""}`;
    setChip($("#chip-proy"), alarma, etiqueta(alarma));
    $("#v-margen").textContent = esNum(margen)
      ? `Margen contra el límite: ${margen > 0 ? "+" : ""}${n(margen, 2)} kW`
      : (tono(alarma) === "unk" ? "Sin lectura fresca para saberlo" : "");

    // Barra contra el limite (escala solo para dibujar)
    const escala = Math.max(esNum(lim) ? lim : 0, esNum(proy) ? proy : 0, esNum(acum) ? acum : 0) * 1.15 || 1;
    const pct = (x) => esNum(x) ? `${Math.min(100, (x / escala) * 100)}%` : "0";
    $("#ml-acum").style.width = pct(acum);
    $("#ml-proy").style.width = pct(proy);
    $("#ml-lim").style.left = pct(lim);
    $("#ml-lim").style.display = esNum(lim) ? "block" : "none";

    // Lecturas faltantes
    const falt = lista(pick(d, "faltantes"));
    const f = $("#faltantes");
    if (falt.length) {
      f.innerHTML = `Faltan ${falt.length} lectura(s) en la ventana (${esc(falt.map(x => hora(isNaN(+x) ? x : +x)).join(", "))}). Se rellenaron con el último valor, por eso la proyección es <b>estimación</b>.`;
      f.classList.remove("oculto");
    } else f.classList.add("oculto");

    // Recomendacion
    const rec = pick(d, "recomendacion");
    const r = $("#recomendacion");
    if (rec && (rec.motor || typeof rec === "string")) {
      if (typeof rec === "string") { $("#rec-titulo").textContent = rec; $("#rec-detalle").textContent = ""; }
      else {
        $("#rec-titulo").textContent = `Diferir ${etiqueta(rec.motor).toLowerCase()} hasta ${hora(rec.hasta)} — afecta a ${etiqueta(rec.se_le_falla_a).toLowerCase()}`;
        const nuevo = pick(rec, "proyectado_kw", "proyectado");
        $("#rec-detalle").innerHTML = esNum(nuevo)
          ? `Con ese cambio la ventana cerraría en <b>${n(nuevo, 2)} kW</b>. Se prueban los motores de menor a mayor prioridad.`
          : `Se prueban los motores de menor a mayor prioridad; el primero que deja la ventana bajo el límite es la recomendación.`;
      }
      r.className = "tarjeta recomendacion";
    } else if (tono(alarma) === "ok") {
      $("#rec-titulo").textContent = "No hace falta diferir ningún arranque";
      $("#rec-detalle").textContent = "Con lo acumulado y la carga esperada, la ventana cierra bajo el límite.";
      r.className = "tarjeta recomendacion ok";
      r.querySelector(".ceja").textContent = "Recomendación del gemelo";
    } else r.className = "tarjeta recomendacion oculto";

    // Explicacion
    const ex = lista(pick(d, "explicacion"));
    $("#n-factores").textContent = ex.length ? `${ex.length} hechos y condiciones` : "";
    $("#explicacion").innerHTML = ex.length ? ex.map(t => `<li>${esc(t)}</li>`).join("") : `<li class="vacio">Sin explicación.</li>`;
  }

  async function queFalta() {
    const b = $("#btn-que-falta"); b.disabled = true;
    try {
      const d = await api("/api/que_falta?entidad=ventana");
      const c = lista(pick(d, "cambios") ?? d);
      const ul = $("#que-falta");
      ul.innerHTML = c.length ? c.map(t => `<li>${esc(t)}</li>`).join("") : `<li>Nada: la decisión ya no depende de ningún cambio.</li>`;
      ul.classList.remove("oculto");
      estadoConexion(true);
    } catch (e) { estadoConexion(false, e); }
    b.disabled = false;
  }

  let retrasoMin = 10;
  async function hipotesis() {
    const b = $("#btn-hipotesis"); b.disabled = true;
    const motor = $('input[name="motor"]:checked').value;
    try {
      const d = await api(`/api/hipotesis?motor=${encodeURIComponent(motor)}&retraso=${retrasoMin * 60}`);
      const antes = pick(d, "antes") || ultimaDemanda || {};
      const desp = pick(d, "despues", "decision") || {};
      const caja = (sel, o) => {
        const a = pick(o, "alarma", "tipo", "estado") || (typeof o === "string" ? o : "no_se");
        const p = pick(o, "proyectado_kw", "proyectado", "promedio");
        const el = $(sel);
        el.textContent = `${etiqueta(a)}${esNum(p) ? " · " + n(p, 2) + " kW" : ""}`;
        el.parentElement.className = `comp-caja ${tono(a)}`;
      };
      caja("#h-antes", antes); caja("#h-despues", desp);
      $("#h-explicacion").innerHTML = lista(pick(d, "explicacion")).map(t => `<li>${esc(t)}</li>`).join("");
      $("#hipotesis").classList.remove("oculto");
      estadoConexion(true);
    } catch (e) { estadoConexion(false, e); }
    b.disabled = false;
  }

  // ---------- Alarmas ----------
  const ICONO_SIT = {
    rebase_proyectado: "i-rayo", rebase_vigente: "i-rayo", medidor_lento: "i-medidor", lectura_atrasada: "i-medidor",
    contador_reiniciado: "i-flechas", contador_desbordado: "i-flechas", dato_corrupto: "i-x",
    caida_por_arranque: "i-alarma", caida_de_red: "i-alarma", consumo_nocturno_esperado: "i-luna", consumo_nocturno_anomalo: "i-luna"
  };
  async function cargarSituaciones() {
    const d = await api("/api/situaciones");
    const s = pick(d, "situaciones") || (Array.isArray(d) ? d : []);
    $("#k-situaciones").textContent = s.length;
    setChip($("#chip-n-sit"), s.length ? "anticipada" : "ok", `${s.length} activa(s)`);
    const relevantes = s.filter(x => tono(pick(x, "estado", "situacion")) !== "ok").length;
    const badge = $("#badge-alarmas");
    badge.textContent = relevantes; badge.classList.toggle("oculto", !relevantes);
    $("#situaciones").innerHTML = s.length ? s.map(x => {
      const sit = pick(x, "situacion", "tipo");
      const t = tono(pick(x, "estado") || sit);
      const ent = pick(x, "entidad");
      const cert = pick(x, "certeza");
      return `<div class="situacion ${t}">
        <span class="ico-caja ${t}">${icono(ICONO_SIT[norm(sit)] || "i-alarma")}</span>
        <div>
          <div class="cabeza"><div><b>${esc(etiqueta(sit))}</b><small>${esc((MEDIDORES[ent] || [etiqueta(ent)])[0])}</small></div>${cert ? chip(cert) : ""}</div>
          <p>${esc(lista(pick(x, "evidencia", "explicacion")).join(" · "))}</p>
        </div>
      </div>`;
    }).join("") : `<div class="vacio-caja">${icono("i-check")}El gemelo no dedujo ninguna situación en este escenario.</div>`;
  }

  let pisoCaida = "piso1";
  async function cargarCaida(piso) {
    const d = await api(`/api/caida?piso=${encodeURIComponent(piso)}`);
    const causa = pick(d, "causa") || "no_se";
    const t = tono(pick(d, "estado") || causa);
    const evid = lista(pick(d, "evidencia")), desc = lista(pick(d, "descartada")), falta = lista(pick(d, "dato_que_falta", "dato_falta"));
    const accion = pick(d, "accion");
    const resumen = {
      red: "Reportar a CFE y proteger equipos.", arranque_motores: "Escalonar los arranques de los motores.",
      medidor_local: "Revisar ese medidor: su general aguas arriba no cayó.", no_se_puede_decir: "Con timeouts no se inventa una causa.",
      sin_caida: "Ningún medidor del piso está bajo el umbral."
    }[norm(causa)];
    const bloque = (cls, ico, tit, items, vacio) => `<div class="paso ${cls}">
        <div class="paso-titulo">${icono(ico)} ${tit}</div>
        ${items.length ? `<ul>${items.map(i => `<li>${esc(i)}</li>`).join("")}</ul>` : `<p>${vacio}</p>`}
      </div>`;
    $("#causa").innerHTML = `
      <div class="causa-resumen ${t}">
        <span class="ico-caja ${t}">${icono(t === "ok" ? "i-check" : "i-rayo")}</span>
        <div><span class="etiqueta-mono">1 · Causa más probable · ${esc(etiqueta(piso))}</span><h4>${esc(etiqueta(causa))}</h4><p>${esc(accion || resumen || "")}</p></div>
      </div>
      ${bloque("p2", "i-lista", "2 · Evidencia", evid, "Sin evidencia registrada.")}
      ${bloque("p3", "i-x", "3 · Explicación descartada", desc, "No se descartó nada.")}
      ${bloque("p4", "i-flechas", "4 · Dato que cambiaría la deducción", falta, "Ninguno: con estos datos la conclusión es firme.")}`;
  }

  // ---------- Reparto ----------
  async function cargarReparto() {
    const d = await api("/api/reparto");
    const cert = pick(d, "certeza") || "estimacion";
    setChip($("#chip-certeza-reparto"), cert);
    $("#regla").textContent = texto(pick(d, "regla")) || "—";

    const e = pick(d, "energia") || {};
    const de = pick(d, "demanda") || {};
    barraDoble("#barra-energia", pick(e, "lab", "laboratorio"), pick(e, "ofi", "oficinas"), "kWh");
    barraDoble("#barra-demanda", pick(de, "lab", "laboratorio"), pick(de, "ofi", "oficinas"), "kW", pick(de, "pct_lab"), pick(de, "pct_ofi"));
    const el = pick(e, "lab", "laboratorio"), eo = pick(e, "ofi", "oficinas");
    $("#tot-energia").textContent = esNum(el) && esNum(eo) ? `Total ${n(el + eo, 1)} kWh` : "";
    const vm = pick(de, "ventana", "ventana_seg");
    $("#ventana-max").textContent = vm !== undefined ? `ventana de las ${hora(vm)}` : "";

    // La conclusion "energia vs demanda" la redacta el gemelo, no la pagina
    $("#nota-divergencia").textContent = texto(pick(d, "nota", "divergencia"));

    const fp = pick(d, "fp") || {};
    const fpv = esNum(fp) ? fp : pick(fp, "valor");
    const min = pick(fp, "minimo");
    const pen = pick(fp, "penaliza") ?? pick(d, "penaliza");
    $("#fp").textContent = esNum(fpv) ? n(fpv, 3) : "—";
    $("#fp-ref").textContent = esNum(min) ? `/ mín. ${n(min, 2)}` : "";
    setChip($("#chip-fp"), pen === true || norm(pen) === "si" ? "penaliza" : (pen === false || norm(pen) === "no" ? "ok" : "no_se"),
      pen === true || norm(pen) === "si" ? "Penaliza" : (pen === false || norm(pen) === "no" ? "Sin penalización" : "No sé"));
    $("#fp-texto").textContent = texto(pick(fp, "texto", "explicacion")) ||
      (pen === true || norm(pen) === "si" ? "La penalización se reparte igual que el cargo por demanda." : "");

    const noc = pick(d, "nocturno") || {};
    const nocE = pick(noc, "estado") || (typeof noc === "string" ? noc : "no_se");
    setChip($("#chip-nocturno"), nocE);
    $("#nocturno-texto").textContent = lista(pick(noc, "explicacion")).join(" ") ||
      (norm(nocE) === "esperado" ? "El consumo de madrugada lo explican los equipos 24 h del laboratorio: no es anomalía." : "");

    const falla = pick(d, "se_le_falla_a") || [];
    $("#se-le-falla").innerHTML = (Array.isArray(falla) ? falla : [falla]).map(f =>
      typeof f === "string" ? `<li>${esc(f)}</li>` : `<li><b>${esc(etiqueta(pick(f, "area")))}</b> — ${esc(texto(pick(f, "si", "si_pasa_que", "texto")))}</li>`
    ).join("") || `<li>—</li>`;
  }

  function barraDoble(sel, a, b, unidad, pa, pb) {
    const el = $(sel);
    if (!esNum(a) || !esNum(b) || a + b <= 0) { el.innerHTML = `<div style="flex:1;background:var(--sup-3);color:var(--texto-3);justify-content:center">sin dato</div>`; return; }
    const pA = esNum(pa) ? pa : (a / (a + b)) * 100, pB = esNum(pb) ? pb : 100 - pA;
    el.innerHTML = `
      <div class="lab" style="flex-basis:${pA}%"><span>Laboratorio</span><span>${n(a, 2)} ${unidad} · ${Math.round(pA)} %</span></div>
      <div class="ofi" style="flex-basis:${pB}%"><span>Oficinas</span><span>${n(b, 2)} ${unidad} · ${Math.round(pB)} %</span></div>`;
  }

  // ---------- Arranque ----------
  async function refrescarTodo() {
    await seguro(cargarEstado);
    cargarVista(vistaActual());
    if (vistaActual() !== "alarmas") seguro(cargarSituaciones); // para el contador del menu
  }

  function enlazar() {
    $("#escenario").addEventListener("change", (e) => seguro(cambiarEscenario, e.target.value));
    $("#btn-que-falta").addEventListener("click", queFalta);
    $("#btn-hipotesis").addEventListener("click", hipotesis);
    $$("#seg-retraso button").forEach(b => b.addEventListener("click", () => {
      $$("#seg-retraso button").forEach(x => x.classList.toggle("activo", x === b));
      retrasoMin = +b.dataset.min; $("#lbl-retraso").textContent = `${retrasoMin} min`;
    }));
    $$("#seg-piso button").forEach(b => b.addEventListener("click", () => {
      $$("#seg-piso button").forEach(x => x.classList.toggle("activo", x === b));
      pisoCaida = b.dataset.piso; seguro(cargarCaida, pisoCaida);
    }));
  }

  async function iniciar() {
    if (MODO_DEMO && !window.DEMO_API) {
      await new Promise((ok, mal) => { const s = document.createElement("script"); s.src = "/web/demo-datos.js"; s.onload = ok; s.onerror = mal; document.head.appendChild(s); });
    }
    enlazar();
    await seguro(cargarEscenarios);
    irA(vistaActual());
    seguro(cargarEstado);
    seguro(cargarSituaciones);
    setInterval(() => {
      if (document.hidden) return;
      seguro(cargarEstado);
      if (vistaActual() === "panel") seguro(cargarDemanda);
    }, REFRESCO_MS);
  }
  iniciar();
})();
