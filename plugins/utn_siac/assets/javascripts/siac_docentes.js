// =========================
// GUARDAR DOCENTE
// =========================
function guardarDocente(payload) {
  const cvInput = document.getElementById('docente_cv');
  const cvFile = cvInput?.files?.[0] || null;

  const formData = new FormData();

  Object.entries(payload?.docente || {}).forEach(([key, value]) => {
    formData.append(`docente[${key}]`, value ?? '');
  });

  Object.entries(payload?.cargo || {}).forEach(([key, value]) => {
    formData.append(`cargo[${key}]`, value ?? '');
  });

  Object.entries(payload?.empresa || {}).forEach(([key, value]) => {
    formData.append(`empresa[${key}]`, value ?? '');
  });

  if (cvFile) {
    formData.append('docente[cv]', cvFile);
  }

  return fetch('/docentes/guardar', {
    method: 'POST',
    redirect: 'manual',
    headers: {
      'Accept': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
    },
    body: formData
  }).then(async (r) => {
    if (r.type === 'opaqueredirect' || (r.status >= 300 && r.status < 400)) {
      throw new Error('La sesión/permisos redirigieron la petición (302).');
    }

    const text = await r.text();
    let data;
    try { data = JSON.parse(text); }
    catch (_) { data = { ok: false, error: text.slice(0, 200) }; }

    if (!r.ok) throw new Error(data.error || `HTTP ${r.status}`);
    return data;
  });
}

function autocompletarDocente(modal, data) {
  const d = data.docente || {};
  const empleo = data.empleo || null;
  const inv = data.investigacion || [];

  const set = (selector, value) => {
    const el = modal.querySelector(selector);
    if (!el || value === undefined || value === null) return;
    el.value = value;
    el.dispatchEvent(new Event("change", { bubbles: true }));
  };

  // =========================
  // DATOS PERSONALES
  // =========================
  set('input[name="docente[nombre]"]', d.nombre);
  set('input[name="docente[apellido]"]', d.apellido);
  set('input[name="docente[fecha_nacimiento]"]', d.fecha_nacimiento);
  set('input[name="docente[legajo]"]', d.legajo);

  // =========================
  // EMPLEO
  // =========================
  if (empleo) {
    set('input[name="empresa[cuit]"]', empleo.cuit);
    set('input[name="empresa[nombre_empresa]"]', empleo.nombre_empresa);
    set('input[name="empresa[horas_trabajo_empresa]"]', empleo.horas_trabajo_empresa);
    set('input[name="empresa[hora_inicio]"]', empleo.hora_inicio);
    set('input[name="empresa[hora_salida]"]', empleo.hora_salida);

    const label = modal.querySelector('[data-target="empresa_nombre"]');
    if (label) label.textContent = empleo.nombre_empresa || '';
  }

  // =========================
  // INVESTIGACIÓN
  // =========================
  if (Array.isArray(inv) && inv.length > 0) {
    const container = modal.querySelector('.proyectos-container');
    if (!container) return;

    const template = container.querySelector('[data-proyecto-item="true"]');
    container.innerHTML = '';

    inv.forEach((p, i) => {
      const item = template.cloneNode(true);

      item.querySelectorAll("input, select").forEach(el => {
        if (el.name) {
          el.name = el.name.replace(/\[proyectos\]\[\d+\]/, `[proyectos][${i}]`);
        }
      });

      const setLocal = (sel, val) => {
        const el = item.querySelector(sel);
        if (el && val !== undefined && val !== null) el.value = val;
      };

      setLocal('input[name*="[nombre]"]', p.nombre);
      setLocal('input[name*="[horas_semanales]"]', p.horas_semanales);
      setLocal('select[name*="[id_cargo_investigacion]"]', p.id_cargo_investigacion);
      setLocal('select[name*="[tipo_encuadre]"]', p.tipo_encuadre);
      setLocal('select[name*="[referencia_id]"]', p.referencia_id);

      container.appendChild(item);
    });
  }
}

//agregar proyecto
document.addEventListener("click", function (e) {
  const btn = e.target.closest('[data-action="investigacion:add"]');
  if (!btn) return;

  const modal = btn.closest('[id^="modal_docente_"]');
  if (!modal) return;

  const step = btn.closest(".investigacion-step");
  if (!step) return;

  const container = step.querySelector('[data-target="proyectos"]') || step.querySelector(".proyectos-container");
  if (!container) return;

  const items = container.querySelectorAll('[data-proyecto-item="true"]');
  const nextIndex = items.length;

  const first = container.querySelector('[data-proyecto-item="true"]');
  if (!first) return;

  const clone = first.cloneNode(true);
  clone.dataset.index = String(nextIndex);

  // Renumerar names y limpiar valores
  clone.querySelectorAll("input, select, textarea").forEach(el => {
    if (el.name) el.name = el.name.replace(/\[proyectos\]\[\d+\]/, `[proyectos][${nextIndex}]`);

    if (el.tagName === "SELECT") {
      el.selectedIndex = 0;
    } else {
      el.value = "";
    }

    // opcional: si querés resetear opciones del select referencia
    if (el.dataset.role === "investigacion-referencia") {
      el.innerHTML = '<option value="">Seleccione grupo o centro</option>';
      el.disabled = true; // ✅ hasta elegir tipo
    }
  });

  container.appendChild(clone);
});


function reindexProyectos(container) {
  const items = container.querySelectorAll('[data-proyecto-item="true"]');
  items.forEach((item, idx) => {
    item.dataset.index = String(idx);
    item.querySelectorAll("input, select, textarea").forEach(el => {
      if (!el.name) return;
      el.name = el.name.replace(/\[proyectos\]\[\d+\]/, `[proyectos][${idx}]`);
    });
  });
}

//quitar proyecto
document.addEventListener("click", function (e) {
  const btn = e.target.closest('[data-action="investigacion:remove"]');
  if (!btn) return;

  const modal = btn.closest('[id^="modal_docente_"]');
  if (!modal) return;

  const item = btn.closest('[data-proyecto-item="true"]');
  if (!item) return;

  // si querés impedir borrar el último:
  const container = item.parentElement;
  const count = container.querySelectorAll('[data-proyecto-item="true"]').length;
  if (count <= 1) return;

  item.remove();
  reindexProyectos(container);
});


document.addEventListener("change", function (e) {
  const tipoSel = e.target.closest('[data-action="investigacion:tipo_change"]');
  if (!tipoSel) return;

  const modal = tipoSel.closest('[id^="modal_docente_"]');
  if (!modal) return;

  const step = tipoSel.closest(".investigacion-step");
  if (!step) return;

  const item = tipoSel.closest('[data-proyecto-item="true"]');
  if (!item) return;

  const refSel = item.querySelector('[data-role="investigacion-referencia"]');
  if (!refSel) return;

  let grupos = [];
  let centros = [];
  try {
    grupos = JSON.parse(step.dataset.grupos || "[]");
    centros = JSON.parse(step.dataset.centros || "[]");
  } catch (err) {
    console.error("JSON inválido en data-grupos/data-centros", err);
  }

  const tipo = (tipoSel.value || "").trim();

  if (!tipo) {
    refSel.innerHTML = '<option value="">Seleccione grupo o centro</option>';
    refSel.disabled = true;
    return;
  }

  const source = (tipo === "grupo") ? grupos : (tipo === "centro") ? centros : [];
  refSel.innerHTML = '<option value="">Seleccione...</option>';

  source.forEach(x => {
    const opt = document.createElement("option");
    if (tipo === "grupo") opt.value = String(x.id_grupo ?? "");
    if (tipo === "centro") opt.value = String(x.id_centro ?? "");
    opt.textContent = String(x.denominacion ?? "");
    refSel.appendChild(opt);
  });

  refSel.disabled = source.length === 0;
});


function textoSelect(selectEl) {
  if (!selectEl) return "";
  const opt = selectEl.options?.[selectEl.selectedIndex];
  return (opt?.textContent || "").trim();
}

function setHtml(modal, target, html) {
  const el = modal.querySelector(`[data-target="${target}"]`);
  if (el) el.innerHTML = html;
}

function actualizarResumen(modal) {
  // 1) Materia (depende de cómo la guardes en el modal)
  const codigoMateria = modal.dataset.codigoMateria || modal.querySelector('[name="codigo_materia"]')?.value || "";
  const nombreMateria = modal.dataset.nombreMateria || "";

  setHtml(modal, "resumen_materia", `
    <div class="mb-2"><strong>Materia:</strong> ${nombreMateria} <span class="text-muted">(${codigoMateria})</span></div>
  `);

  // 2) Datos personales (ajustá names a los tuyos reales)
  const cuit = val(modal, 'input[name="docente[cuit]"]');
  const nombre = val(modal, 'input[name="docente[nombre]"]');
  const apellido = val(modal, 'input[name="docente[apellido]"]');
  const nacimiento = val(modal, 'input[name="docente[fecha_nacimiento]"]');

  setHtml(modal, "resumen_personales", `
    <div class="mb-2"><strong>Docente</strong></div>
    <ul class="mb-2">
      <li><strong>CUIT:</strong> ${cuit}</li>
      <li><strong>Nombre:</strong> ${apellido}, ${nombre}</li>
      <li><strong>Nacimiento:</strong> ${nacimiento}</li>
    </ul>
  `);

  // 3) Académico (ajustá ids/names a los tuyos)
  const cargoDocente = textoSelect(modal.querySelector('select[name="docente[id_cargo_docente]"], select[name="cargo_docente"], #cargo_select'));
  const horasDictado = val(modal, 'input[name="docente[horas_dictado]"], input[name="horas_dictado"]');

  setHtml(modal, "resumen_academico", `
    <div class="mb-2"><strong>Desempeño académico</strong></div>
    <ul class="mb-2">
      <li><strong>Cargo:</strong> ${cargoDocente}</li>
      <li><strong>Horas:</strong> ${horasDictado}</li>
    </ul>
  `);

  // 4) Investigación: leer N proyectos existentes
  const proyectos = Array.from(modal.querySelectorAll('[data-proyecto-item="true"]')).map(item => {
    const nombreP = (item.querySelector('input[name*="[nombre]"]')?.value || "").trim();
    const cargoInv = textoSelect(item.querySelector('select[name*="[id_cargo_investigacion]"]'));
    const tipoEnc = textoSelect(item.querySelector('select[name*="[tipo_encuadre]"]'));
    const ref = textoSelect(item.querySelector('select[name*="[referencia_id]"]'));
    const linea = textoSelect(item.querySelector('select[name*="[linea_accion]"]'));
    const horas = (item.querySelector('input[name*="[horas_semanales]"]')?.value || "").trim();

    if (!nombreP && !cargoInv && !tipoEnc && !ref && !linea && !horas) return null;

    return `
      <li class="mb-1">
        <div><strong>${nombreP || "(Sin nombre)"}</strong></div>
        <div class="text-muted">
          Cargo: ${cargoInv || "-"} · ${tipoEnc || "-"}: ${ref || "-"} · Línea: ${linea || "-"} · Horas: ${horas || "-"}
        </div>
      </li>
    `;
  }).filter(Boolean);

  setHtml(modal, "resumen_investigacion", `
    <div class="mb-2"><strong>Investigación</strong></div>
    ${proyectos.length ? `<ul class="mb-2">${proyectos.join("")}</ul>` : `<div class="text-muted mb-2">Sin proyectos cargados</div>`}
  `);

  // 5) Laboral (si lo tenés en inputs; ajustá)
  const empresaNombre = valSel(modal, 'input[name="empresa[nombre_empresa]"]') || '';
  const horasEmpresa  = val(modal, 'empresa[horas_trabajo_empresa]') || '';
  const horaInicio    = val(modal, 'empresa[hora_inicio]') || '';
  const horaSalida    = val(modal, 'empresa[hora_salida]') || '';

  setHtml(modal, "resumen_laboral", `
    <div class="mb-2"><strong>Datos laborales</strong></div>
    <ul class="mb-2">
      <li><strong>Empresa CUIT:</strong> ${val(modal, 'empresa[cuit]') || '-'}</li>
      <li><strong>Empresa:</strong> ${empresaNombre || '-'}</li>
      <li><strong>Horas semanales:</strong> ${horasEmpresa || '-'}</li>
      <li><strong>Horario:</strong> ${
        (horaInicio || horaSalida)
          ? `${horaInicio || '--:--'} a ${horaSalida || '--:--'}`
          : '-'
      }</li>
    </ul>
  `);
}

async function cargarDocentesMateria(codigoMateria) {
  const resp = await fetch(`/docentes/por_materia?codigo_materia=${encodeURIComponent(codigoMateria)}`, {
    headers: { "Accept": "", "X-Requested-With": "XMLHttpRequest" }
  });
  const data = await resp.json();
  if (!resp.ok || data.ok === false) throw new Error(data.error || `HTTP ${resp.status}`);
  return data.docentes || [];
}

async function hidratarPlantelDesdeDB() {
  const containers = document.querySelectorAll('.docentes-container[data-codigo-materia]');
  for (const c of containers) {
    const codigo = (c.dataset.codigoMateria || '').trim();
    if (!codigo) continue;
    try {
      const docentes = await cargarDocentesMateria(codigo);
      // pintás como ya venías (docente-item)
      // ...
    } catch (e) {
      console.error("Error hidratando materia", codigo, e);
    }
  }
}
