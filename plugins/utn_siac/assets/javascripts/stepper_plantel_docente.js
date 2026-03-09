document.addEventListener('DOMContentLoaded', function () {
  // Estado por modal
  const modalState = new Map(); // modalEl -> { currentStep, materiaActiva }

  function getModalState(modal) {
    if (!modalState.has(modal)) {
      modalState.set(modal, { currentStep: 0, materiaActiva: null });
    }
    return modalState.get(modal);
  }

  function isJqueryUiDialogOpen(modal) {
    return window.$ && typeof $(modal).dialog === 'function';
  }

  function closeModal(modal) {
    if (isJqueryUiDialogOpen(modal)) {
      $(modal).dialog('close');
    } else {
      // fallback
      modal.style.display = 'none';
    }
  }

  function openModal(modal) {
    // Si usás openDocenteDialog global, la respetamos.
    // openDocenteDialog recibe id string ("modal_docente_55")
    if (typeof window.openDocenteDialog === 'function') {
      window.openDocenteDialog(modal.id);
      return;
    }

    // fallback simple
    modal.style.display = 'block';
  }

  function showStep(modal, index) {
    const steps = modal.querySelectorAll('.step');
    const contents = modal.querySelectorAll('.step-content');
    const btnNext = modal.querySelector('.step-btn.next');
    const btnPrev = modal.querySelector('.step-btn.prev');

    if (index < 0 || index >= contents.length) return;

    steps.forEach(s => s.classList.remove('active'));
    contents.forEach(c => c.classList.remove('active'));

    steps[index]?.classList.add('active');
    contents[index].classList.add('active');

    btnPrev.style.display = index === 0 ? 'none' : 'inline-block';
    btnNext.textContent = index === contents.length - 1 ? 'Guardar' : 'Siguiente';

    getModalState(modal).currentStep = index;

    // Si estamos entrando al último step, construimos resumen
    if (index === contents.length - 1) {
      buildResumen(modal);
    }
  }

  function resetModal(modal) {
    const state = getModalState(modal);

    // Limpiar inputs/select/textarea
    modal.querySelectorAll('input, select, textarea').forEach(el => {
      if (el.type === 'checkbox' || el.type === 'radio') el.checked = false;
      else el.value = '';
    });

    // Ocultar alerta "docente-no-encontrado"
   // Ocultar alerta "docente encontrado / no encontrado"
    const msg = modal.querySelector('[id^="docente-no-encontrado-"]');
    if (msg) {
      msg.style.display = 'none';
      msg.textContent = '';
      msg.classList.remove('alert-warning', 'alert-danger', 'alert-success');
    }

    // Si habías deshabilitado guardar por "ya en materia", re-habilitalo
    const btnGuardar = modal.querySelector('.step-btn.next');
    if (btnGuardar) btnGuardar.disabled = false;

    // Reset de selects dependientes si existen
    const cargoSelect = modal.querySelector('#cargo_select');
    if (cargoSelect) cargoSelect.innerHTML = '<option value="">Seleccione cargo</option>';

    // Si tenés proyectos dinámicos, acá se resetea el container
    const proyectosContainer = modal.querySelector('.proyectos-container');
    if (proyectosContainer) {
      // Dejar solo el primero (si lo renderizás así) o vaciar.
      // Como tu helper renderiza render_proyecto_investigacion(0), dejamos el primero.
      const first = proyectosContainer.querySelector('.proyecto-investigacion');
      proyectosContainer.innerHTML = '';
      if (first) proyectosContainer.appendChild(first);
    }

    // Volver al step 0
    state.currentStep = 0;
    showStep(modal, 0);
  }

  // Helpers para leer valores dentro del modal
  function q(modal, selector) { return modal.querySelector(selector); }
  function val(modal, nameAttr) {
    const el = modal.querySelector(`[name="${nameAttr}"]`);
    return el ? (el.value || '').trim() : '';
  }
  function filePresent(modal, nameAttr) {
    const el = modal.querySelector(`[name="${nameAttr}"]`);
    return el && el.files && el.files.length > 0;
  }
  function selectedText(modal, nameAttr) {
    const el = modal.querySelector(`[name="${nameAttr}"]`);
    if (!el) return '';
    const opt = el.options?.[el.selectedIndex];
    return (opt?.textContent || '').trim();
  }

  // Resumen (Step final)
  function buildResumen(modal) {
    const state = getModalState(modal);

    const setTarget = (key, html) => {
      const el = modal.querySelector(`[data-target="${key}"]`);
      if (el) el.innerHTML = html;
    };

    const materia = state.materiaActiva || {};

    // Proyectos (investigación)
    const proyectos = Array.from(modal.querySelectorAll('[data-proyecto-item="true"]')).map(p => {
      const nombre = p.querySelector('input[name*="[nombre]"]')?.value?.trim() || '';
      const horas  = p.querySelector('input[name*="[horas_semanales]"]')?.value?.trim() || '';
      const cargo  = p.querySelector('select[name*="[id_cargo_investigacion]"]')?.selectedOptions?.[0]?.textContent?.trim() || '';
      const tipo   = p.querySelector('select[name*="[tipo_encuadre]"]')?.selectedOptions?.[0]?.textContent?.trim() || '';
      const ref    = p.querySelector('select[name*="[referencia_id]"]')?.selectedOptions?.[0]?.textContent?.trim() || '';

      if (![nombre, horas, cargo, tipo, ref].some(v => v)) return null;
      return { nombre, horas, cargo, tipo, ref };
    }).filter(Boolean);

    // Empresa (IMPORTANTE: scoped al modal)
    const empresaNombre = (modal.querySelector('#empresa_nombre')?.textContent || '').trim();

    // ---- Pintar secciones ----
    setTarget('resumen_materia', `
      <div class="mb-2">
        <strong>Materia:</strong> ${materia.nombre || '-'}
        ${materia.codigo ? `<span class="text-muted">(${materia.codigo})</span>` : ''}
      </div>
    `);

    setTarget('resumen_personales', `
      <div class="mb-2"><strong>Docente</strong></div>
      <ul class="mb-2">
        <li><strong>CUIT:</strong> ${val(modal, 'docente[cuit]') || '-'}</li>
        <li><strong>Legajo:</strong> ${val(modal, 'docente[legajo]') || '-'}</li>
        <li><strong>Nombre:</strong> ${(val(modal, 'docente[apellido]') + ' ' + val(modal, 'docente[nombre]')).trim() || '-'}</li>
        <li><strong>Fecha nacimiento:</strong> ${val(modal, 'docente[fecha_nacimiento]') || '-'}</li>
        <li><strong>Titulación:</strong> ${selectedText(modal, 'docente[id_especialidad]') || '-'}</li>
        <li><strong>CV adjunto:</strong> ${filePresent(modal, 'docente[cv]') ? 'Sí' : 'No'}</li>
      </ul>
    `);

    setTarget('resumen_academico', `
      <div class="mb-2"><strong>Desempeño académico</strong></div>
      <ul class="mb-2">
        <li><strong>Cargo docente:</strong> ${selectedText(modal, 'docente[id_cargo_docente]') || '-'}</li>
        <li><strong>Horas dictado:</strong> ${val(modal, 'docente[horas_dictado]') || '-'}</li>
        <li><strong>Comisión:</strong> ${selectedText(modal, 'docente[id_comision]') || '-'}</li>
      </ul>
    `);

    setTarget('resumen_laboral', `
      <div class="mb-2"><strong>Datos laborales</strong></div>
      <ul class="mb-2">
        <li><strong>Empresa CUIT:</strong> ${val(modal, 'empresa[cuit]') || '-'}</li>
        <li><strong>Empresa:</strong> ${empresaNombre || '-'}</li>
      </ul>
    `);

    setTarget('resumen_investigacion', `
      <div class="mb-2"><strong>Investigación</strong></div>
      <ul class="mb-2">
        ${
          proyectos.length
            ? proyectos.map(p => `
                <li>
                  ${p.nombre || '-'}
                  ${p.cargo ? `, ${p.cargo}` : ''}
                  ${p.horas ? `, ${p.horas} hs` : ''}
                  ${p.tipo ? `, ${p.tipo}` : ''}
                  ${p.ref ? ` (${p.ref})` : ''}
                </li>
              `).join('')
            : '<li>-</li>'
        }
      </ul>
    `);
  }

  // Validación mínima por step (para fase 1)
  function validateStep(modal, stepIndex) {
    const contents = modal.querySelectorAll('.step-content');
    const stepEl = contents[stepIndex];
    if (!stepEl) return true;

    // 1) Validación normal de obligatorios no laborales
    const requiredEls = stepEl.querySelectorAll('[data-required="true"], [data-required="1"]');
    for (const el of requiredEls) {
      if (el.dataset.laboral === "true") continue;

      if (el.type === 'file') {
        if (!el.files || el.files.length === 0) return false;
      } else if (!String(el.value || '').trim()) {
        return false;
      }
    }

    // 2) Validación condicional del bloque laboral
    const laborales = Array.from(stepEl.querySelectorAll('[data-laboral="true"]'));
    if (laborales.length > 0) {
      const hayAlgoLaboral = laborales.some(el => String(el.value || '').trim() !== '');

      if (hayAlgoLaboral) {
        const requeridosLaborales = stepEl.querySelectorAll('[data-laboral-required="true"]');
        for (const el of requeridosLaborales) {
          if (!String(el.value || '').trim()) {
            return false;
          }
        }
      }
    }

    return true;
  }

  // Armar payload (contrato frontend->backend)
  function must(modal, selector) {
    const el = modal.querySelector(selector);
    if (!el) throw new Error(`No se encontró ${selector} dentro del modal ${modal.id}`);
    return el;
  }

  function opt(modal, selector) {
    return modal.querySelector(selector);
  }

  function safeInt(v) {
    const s = String(v ?? '').trim();
    if (!s) return null;
    const n = parseInt(s, 10);
    return Number.isFinite(n) ? n : null;
  }

  function buildPayload(modal) {
    // id_especialidad viene de la URL
    const urlParams = new URLSearchParams(window.location.search);
    const idEspecialidad = safeInt(urlParams.get('especialidad_id'));

    // ⚠️ codigo_materia: lo tomamos del state del modal (lo seteás al abrir)
    const state = getModalState(modal);
    const codigoMateria = state?.materiaActiva?.codigo || null;

    const cuil = must(modal, '[name="docente[cuit]"], [name="docente[cuil]"]').value.trim();

    return {
      docente: {
        cuil: cuil,
        nombre: must(modal, '[name="docente[nombre]"]').value.trim(),
        apellido: must(modal, '[name="docente[apellido]"]').value.trim(),
        legajo: val(modal, 'docente[legajo]') ? Number(val(modal, 'docente[legajo]')) : null,
        fecha_nacimiento: must(modal, '[name="docente[fecha_nacimiento]"]').value || null,
        tipo_especialidad: safeInt(must(modal, '[name="docente[tipo_especialidad]"]').value),
        id_especialidad: idEspecialidad
      },
      cargo: {
        codigo_materia: codigoMateria,
        cuil: cuil,
        id_cargo: safeInt(must(modal, '[name="cargo[id_cargo]"], [name="docente[id_cargo_docente]"]').value),
        horas: safeInt(must(modal, '[name="cargo[horas]"], [name="docente[horas_dictado]"]').value),
        id_comision: safeInt(opt(modal, '[name="cargo[id_comision]"], [name="docente[id_comision]"]')?.value),
        fecha_asignacion: (opt(modal, '[name="cargo[fecha_asignacion]"]')?.value) || new Date().toISOString().slice(0, 10),
        fecha_baja: opt(modal, '[name="cargo[fecha_baja]"]')?.value || null
      },
      empresa: {
        cuit: opt(modal, '[name="empresa[cuit]"]')?.value?.trim() || null,
        nombre_empresa: opt(modal, '[name="empresa[nombre_empresa]"]')?.value?.trim() || null,
        horas_trabajo_empresa: safeInt(opt(modal, '[name="empresa[horas_trabajo_empresa]"]')?.value),
        hora_inicio: opt(modal, '[name="empresa[hora_inicio]"]')?.value || null,
        hora_salida: opt(modal, '[name="empresa[hora_salida]"]')?.value || null
      }
    };
  }

  // Pintar docente en la tabla (visual)
  function insertDocenteInTable(materiaCodigo, docenteLabel) {
    const cont = document.querySelector(`.docentes-container[data-codigo-materia="${CSS.escape(materiaCodigo)}"]`);
    if (!cont) return;

    const empty = cont.querySelector('.docentes-empty');
    if (empty) empty.remove();

    const item = document.createElement('div');
    item.className = 'docente-item';
    item.textContent = docenteLabel;

    cont.appendChild(item);
  }

  // Capturar click en "Agregar docente" (botón de la tabla)
  document.addEventListener('click', function (e) {
    const btn = e.target.closest('.btn-agregar-docente');
    if (!btn) return;

    // 1) modal id desde onclick
    const onclick = btn.getAttribute('onclick') || '';
    const m = onclick.match(/openDocenteDialog\(['"]([^'"]+)['"]\)/);
    const modalId = m ? m[1] : null;
    const modal = modalId ? document.getElementById(modalId) : null;
    if (!modal) return;

    // 2) dataset (data-codigo-materia => dataset.codigoMateria)
    const codigoMateria = btn.dataset.codigoMateria || null;
    const materiaNombre = btn.dataset.materia || null;

    const state = getModalState(modal);
    state.materiaActiva = { codigo: codigoMateria, nombre: materiaNombre };

    // DEBUG (dejalo hasta ver que deja de ser nil)
    console.log("materiaActiva SET:", state.materiaActiva);

    resetModal(modal);
    openModal(modal);
  });

  // Inicializar todos los modales presentes
  document.querySelectorAll('[id^="modal_docente_"]').forEach(function (modal) {
    const btnNext = modal.querySelector('.step-btn.next');
    const btnPrev = modal.querySelector('.step-btn.prev');

    if (!btnNext || !btnPrev) return;

    btnNext.addEventListener('click', async function () {
      const state = getModalState(modal);
      const contents = modal.querySelectorAll('.step-content');

      // Validar step actual
      if (!validateStep(modal, state.currentStep)) {
        // fase 1: feedback mínimo
        alert('Faltan completar campos obligatorios en este paso.');
        return;
      }

      if (state.currentStep < contents.length - 1) {
        showStep(modal, state.currentStep + 1);
        return;
      }

      // Último paso => guardar
      try {
        const payload = buildPayload(modal);
        const result = await guardarDocente(payload);

        if (!result || result.ok === false) {
          alert(result?.error || 'Error al guardar docente');
          return;
        }

        const state = getModalState(modal);

        // ✅ usar codigo materia desde cargo (contrato real)
        const materiaCodigo = payload.cargo?.codigo_materia || state.materiaActiva?.codigo || null;

        const label =
          `${payload.docente.apellido || ''} ${payload.docente.nombre || ''}`.trim() ||
          (payload.docente.cuil || 'Docente');

        const cargoTxt = payload.cargo?.id_cargo ? selectedText(modal, 'docente[id_cargo_docente]') : '';
        const horasTxt = payload.cargo?.horas ? `${payload.cargo.horas} hs` : '';

        const docenteLabel = [label, cargoTxt, horasTxt].filter(Boolean).join(' - ');

        if (materiaCodigo) insertDocenteInTable(materiaCodigo, docenteLabel);

        closeModal(modal);
        resetModal(modal);
      } catch (err) {
        console.error(err);
        alert('Error inesperado al guardar docente');
      }
    });

    btnPrev.addEventListener('click', function () {
      const state = getModalState(modal);
      showStep(modal, state.currentStep - 1);
    });

    // init
    resetModal(modal);
  });

  // Hook específico: Buscar docente por CUIT (botón buscar dentro del modal)
  document.addEventListener("click", async function (e) {
    const btn = e.target.closest('[data-action="empresa:consultar"]');
    if (!btn) return;

    const modal = btn.closest('[id^="modal_docente_"]');
    if (!modal) return;

    const cuitEl = modal.querySelector('input[name="empresa[cuit]"]');
    const labelEl = modal.querySelector('[data-target="empresa_nombre"]');
    const nombreHidden = modal.querySelector('input[name="empresa[nombre_empresa]"]');

    if (!cuitEl || !labelEl || !nombreHidden) return;

    const cuit = (cuitEl.value || "").trim();

    if (!/^\d{11}$/.test(cuit)) {
      labelEl.textContent = "CUIT inválido (11 dígitos).";
      nombreHidden.value = "";
      return;
    }

    labelEl.textContent = "Consultando...";

    try {
      // Ajustá este endpoint al tuyo real (NOSIS proxy backend)
      const resp = await fetch(`/siac_cliente/buscar_empresa_nosis?cuit=${encodeURIComponent(cuit)}`, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      });

      if (!resp.ok) throw new Error("HTTP " + resp.status);

      const data = await resp.json();

      // Definí acá cómo viene tu JSON. Ej: { ok:true, razon_social:"..." }
      const razon = (data?.razon_social || data?.nombre || "").trim();

      if (!razon) {
        labelEl.textContent = "Empresa no encontrada.";
        nombreHidden.value = "";
        return;
      }

      labelEl.textContent = razon;
      nombreHidden.value = razon;
    } catch (err) {
      console.error(err);
      labelEl.textContent = "Error consultando empresa.";
      nombreHidden.value = "";
    }
  });



  // =========================
  // HIDRATAR DOCENTES POR MATERIA (al F5)
  // =========================
  function renderDocentesIntoContainer(containerEl, docentes) {
    // Borra placeholder "Sin docentes cargados"
    const empty = containerEl.querySelector('.docentes-empty');
    if (empty) empty.remove();

    // Borra items previos (si querés que sea idempotente)
    containerEl.querySelectorAll('.docente-item').forEach(n => n.remove());

    if (!Array.isArray(docentes) || docentes.length === 0) {
      // Reponer placeholder si no hay
      const placeholder = document.createElement('div');
      placeholder.className = 'docentes-empty';
      placeholder.textContent = 'Sin docentes cargados';
      // OJO: insertalo antes del botón "Agregar docente" si existe
      const btn = containerEl.querySelector('.btn-agregar-docente');
      if (btn) containerEl.insertBefore(placeholder, btn);
      else containerEl.appendChild(placeholder);
      return;
    }

    // Pintar docentes
    docentes.forEach(d => {
      const label = [
        `${d.apellido || ''} ${d.nombre || ''}`.trim() || (d.cuil || ''),
        d.cargo || d.nombre_cargo || '',     // si el backend lo manda
        d.horas ? `${d.horas} hs` : (d.horas_asignadas ? `${d.horas_asignadas} hs` : '')
      ].filter(Boolean).join(' - ');

      const item = document.createElement('div');
      item.className = 'docente-item';
      item.textContent = label || 'Docente';
      containerEl.appendChild(item);
    });
  }

  async function hydrateDocentesPorMateria() {
    const containers = document.querySelectorAll('.docentes-container[data-codigo-materia]');
    if (!containers.length) return;

    // headers típicos para que rails te lo trate como XHR/JSON
    const headers = { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" };

    for (const cont of containers) {
      const codigo = cont.dataset.codigoMateria;
      if (!codigo) continue;

      try {
        const resp = await fetch(`/docentes/por_materia?codigo_materia=${encodeURIComponent(codigo)}`, { headers });
        const data = await resp.json();

        // Soportar varios shapes:
        const docentes = data?.docentes || data?.rows || data || [];
        if (data?.ok === false) {
          // opcional: dejar placeholder
          continue;
        }

        renderDocentesIntoContainer(cont, docentes);
      } catch (e) {
        console.error("Error hidratando docentes", codigo, e);
      }
    }
  }

  function mostrarCvExistente(modal, cv) {
    const el = modal.querySelector('[data-target="cv_existente"]');
    if (!el) return;

    if (!cv) {
      el.innerHTML = '<span class="text-muted">Sin CV cargado</span>';
      return;
    }

    el.innerHTML = `
      <span>CV actual: <strong>${cv.filename}</strong></span>
      ${cv.url ? ` - <a href="${cv.url}" target="_blank" rel="noopener">Ver</a>` : ''}
    `;
  }

  function autocompletarDocenteBasico(modal, docente) {
    const set = (selector, value) => {
      const el = modal.querySelector(selector);
      if (!el || value === undefined || value === null) return;
      el.value = String(value);
      el.dispatchEvent(new Event("change", { bubbles: true }));
    };

    set('input[name="docente[cuit]"], input[name="docente[cuil]"]', docente.cuil);
    set('input[name="docente[nombre]"]', docente.nombre);
    set('input[name="docente[apellido]"]', docente.apellido);
    set('input[name="docente[fecha_nacimiento]"]', docente.fecha_nacimiento);
    set('input[name="docente[legajo]"]', docente.legajo);

    // titulacion = tipo_especialidad
    set('select[name="docente[tipo_especialidad]"]', docente.tipo_especialidad);
  }

  ///BUSCAR POR CUIT
  document.addEventListener("click", async function (e) {
    const btn = e.target.closest('[data-action="buscar-docente"]');
    if (!btn) return;

    const modal = btn.closest('[id^="modal_docente_"]');
    if (!modal) return;

    const cuitInput = modal.querySelector('input[name="docente[cuit]"], input[name="docente[cuil]"]');
    if (!cuitInput) return;

    const cuil = (cuitInput.value || "").trim();
    const mensaje = modal.querySelector('[id^="docente-no-encontrado-"]');
    const btnGuardar = modal.querySelector(".step-btn.next");
    const state = getModalState(modal);
    const codigoMateria = state?.materiaActiva?.codigo || "";

    if (btnGuardar) btnGuardar.disabled = false;

    if (mensaje) {
      mensaje.style.display = "none";
      mensaje.textContent = "";
      mensaje.classList.remove("alert-warning", "alert-danger", "alert-success");
    }

    if (!/^\d{11}$/.test(cuil)) {
      if (mensaje) {
        mensaje.textContent = "Ingrese un CUIT/CUIL válido";
        mensaje.classList.add("alert-danger");
        mensaje.style.display = "block";
      }
      return;
    }

    try {
      const resp = await fetch(
        `/docentes/por_cuit?cuil=${encodeURIComponent(cuil)}&codigo_materia=${encodeURIComponent(codigoMateria)}`,
        { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" } }
      );

      const data = await resp.json();
      console.log("RESP por_cuit:", data);

      if (!resp.ok || data.ok === false) {
        throw new Error(data.error || `HTTP ${resp.status}`);
      }

      if (!data.found) {
        if (mensaje) {
          mensaje.textContent = "Docente no encontrado. Puede cargarlo manualmente.";
          mensaje.classList.add("alert-warning");
          mensaje.style.display = "block";
        }
        return;
      }

      autocompletarDocenteBasico(modal, data.docente);
      mostrarCvExistente(modal, data.cv);

      if (mensaje) {
        mensaje.textContent = "Docente encontrado";
        mensaje.classList.add("alert-success");
        mensaje.style.display = "block";
      }

      if (data.ya_en_materia) {
        if (mensaje) {
          mensaje.textContent = "Este docente ya está cargado en esta materia.";
          mensaje.classList.remove("alert-success");
          mensaje.classList.add("alert-danger");
        }
        if (btnGuardar) btnGuardar.disabled = true;
      }
    } catch (err) {
      console.error(err);
      if (mensaje) {
        mensaje.textContent = err.message || "Error al buscar docente";
        mensaje.classList.add("alert-danger");
        mensaje.style.display = "block";
      }
    }
  });
  // correr al cargar la página
  hydrateDocentesPorMateria();
});


