// componentes_v2.js (UI + Validaciones) — versión sin doble binding
(() => {
  function uniqueKey() {
    return Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  }

  // ============================================================
  // Helpers: detecta scope/idx real del campo desde el name
  // Evita el bug: componente[campos_attributes][autoevaluacion][...]
  // ============================================================
  function campoKeyScope(campoWrapper) {
    const any =
      campoWrapper.querySelector('[name^="componente[campos_attributes]"]') ||
      campoWrapper.querySelector('[name^="componente[campos]"]');

    if (!any) return null;

    // Caso OK: componente[campos_attributes][IDX][...]
    let m = any.name.match(/^componente\[(campos_attributes|campos)\]\[(.+?)\]\[/);
    if (m) return { scope: m[1], idx: m[2] };

    // Fallback: no hay idx en el name (legacy). Tomamos del DOM.
    const fallbackIdx = campoWrapper.dataset.campoKey || campoWrapper.dataset.index;
    const scope = any.name.includes("campos_attributes") ? "campos_attributes" : "campos";
    if (fallbackIdx) return { scope, idx: fallbackIdx };

    return null;
  }

  // ============================================================
  // Renumeración (solo visibles)
  // ============================================================
  function renumerar() {
    const visiblesCampos = Array.from(
      document.querySelectorAll("#campos-convo .nested-fields, #campos-autoeval .nested-fields")
    ).filter((c) => c.style.display !== "none");

    visiblesCampos.forEach((c, i) => {
      const el = c.querySelector(".campo-index");
      if (el) el.textContent = String(i + 1);
    });

    document.querySelectorAll(".subcampos-container").forEach((cont) => {
      const visiblesSub = Array.from(cont.querySelectorAll(".subcampo")).filter(
        (sc) => sc.style.display !== "none"
      );
      visiblesSub.forEach((sc, i) => {
        const el = sc.querySelector(".subcampo-index");
        if (el) el.textContent = String(i + 1);
      });
    });
  }

  // ============================================================
  // Adds
  // ============================================================
  function addFromPrototype(container) {
    const tpl = container.querySelector("template.campo-template");
    if (!tpl) return;

    const key = uniqueKey();
    const html = tpl.innerHTML.replace(/NEW_RECORD/g, key);

    container.insertAdjacentHTML("beforeend", html);

    const nuevo =
      container.querySelector(
        `.nested-fields[data-campo-key="${key}"], .nested-fields[data-index="${key}"]`
      ) || container.querySelector(".nested-fields:last-of-type");

    if (nuevo) {
      renderOpcionesCampo(nuevo);

      const po = nuevo.querySelector(".checkbox_pregunta_orientadora");
      if (po) togglePO(nuevo, po.checked, ".pregunta_orientadora_container");
    }

    renumerar();
  }

  function addSubFromTemplate(campoWrapper) {
    const tpl = campoWrapper.querySelector("template.subcampo-template");
    const subCont = campoWrapper.querySelector(".subcampos-container");
    if (!tpl || !subCont) return;

    const html = tpl.innerHTML.replaceAll("NEW_SUB", uniqueKey());
    subCont.insertAdjacentHTML("beforeend", html);

    const nuevoSub = subCont.lastElementChild?.closest(".subcampo") || subCont.querySelector(".subcampo:last-child");
    if (nuevoSub) {
      renderOpcionesSubcampo(nuevoSub);
    }

    renumerar();
  }


  // ============================================================
  // Destroy (Rails nested)
  // ============================================================
  function markDestroy(wrapper, selectorDestroy) {
    const destroy = wrapper.querySelector(selectorDestroy);
    const id = wrapper.querySelector('input[name$="[id]"]');

    if (id && id.value && destroy) {
      destroy.value = "1";
      wrapper.style.display = "none";
    } else {
      wrapper.remove();
    }

    renumerar();
  }

  function togglePO(wrapper, checked, selector) {
    const cont = wrapper.querySelector(selector);
    if (!cont) return;
    cont.style.display = checked ? "" : "none";
  }

  // ============================================================
  // Opciones (solo tipos 4/5) — FIX nameBase con idx correcto
  // ============================================================
  function renderOpcionesCampo(campoWrapper) {
    const select = campoWrapper.querySelector("select.tipo-campo");
    const container = campoWrapper.querySelector(".tipo-campo-container");
    if (!select || !container) return;

    if (!["4", "5"].includes(select.value)) {
      container.innerHTML = "";
      return;
    }

  // 🔥 NAME BASE ROBUSTO: sale del name real del select
  if (!select.name || !select.name.includes("[tipo_campo_id]")) {
    console.warn("tipo-campo sin name esperado:", select);
    return;
  }
  const nameBase = select.name.replace(/\[tipo_campo_id\]$/, "[opciones_campos_attributes]");

    let opciones = [];
    try {
      const script = campoWrapper.querySelector("script.opciones-json");
      const raw = script?.textContent ? script.textContent.trim() : "[]";
      opciones = JSON.parse(raw || "[]").filter(
        (o) => (o.opcion || "").toString().trim() !== ""
      );
    } catch (_) {
      opciones = [];
    }

    if (opciones.length === 0) opciones = [{}, {}];

    const rows = opciones
      .map((o, i) => {
        const id = o.id
          ? `<input type="hidden" name="${nameBase}[${i}][id]" value="${o.id}">`
          : "";
        const op = (o.opcion ?? "").toString();
        const val = (o.valor ?? i + 1).toString();

        return `
          <div class="long-field-4 opcion-row">
            <div class="lf4c1"><label>Opción ${i + 1}:</label></div>
            <div class="lf4c2"><button type="button" class="eliminar-opcion siac_button">❌</button></div>
            <div class="lf4c3">
              ${id}
              <input type="text" name="${nameBase}[${i}][opcion]" value="${op}" class="cb-input">
              <input type="hidden" name="${nameBase}[${i}][valor]" value="${val}">
              <input type="hidden" name="${nameBase}[${i}][_destroy]" value="0">
            </div>
            <div class="lf4c4 error-cb-input"></div>
          </div>`;
      })
      .join("");

    container.innerHTML = `
      <div class="combo-box-container">
        <div class="opciones-dinamicas">${rows}</div>
        <div class="long-field-2">
          <div class="lf2c1"><button type="button" class="agregar-opcion siac_button">Agregar opción</button></div>
        </div>
      </div>`;
  }

  function addOpcion(comboBox) {
    if (!comboBox) return;

    // ¿Estoy dentro de un subcampo?
    const subWrapper = comboBox.closest(".subcampo");
    let nameBase = null;

    if (subWrapper) {
      const select = subWrapper.querySelector("select.tipo-subcampo");
      if (!select?.name || !select.name.includes("[tipo_campo_id]")) {
        console.warn("No pude derivar nameBase de subcampo (select.name):", select);
        return;
      }
      nameBase = select.name.replace(/\[tipo_campo_id\]$/, "[opciones_campos_attributes]");
    } else {
      // Campo normal
      const campoWrapper = comboBox.closest(".nested-fields");
      if (!campoWrapper) return;

      const sel = campoWrapper.querySelector("select.tipo-campo");
      if (!sel?.name || !sel.name.includes("[tipo_campo_id]")) {
        console.warn("No pude derivar nameBase de campo (select.name):", sel);
        return;
      }
      nameBase = sel.name.replace(/\[tipo_campo_id\]$/, "[opciones_campos_attributes]");

    }

    const cont = comboBox.querySelector(".opciones-dinamicas");
    if (!cont) return;

    const visibles = Array.from(cont.querySelectorAll(".opcion-row")).filter(
      (r) => r.style.display !== "none"
    );
    const i = visibles.length;

    const row = document.createElement("div");
    row.className = "long-field-4 opcion-row";
    row.innerHTML = `
      <div class="lf4c1"><label>Opción ${i + 1}:</label></div>
      <div class="lf4c2"><button type="button" class="eliminar-opcion siac_button">❌</button></div>
      <div class="lf4c3">
        <input type="text" name="${nameBase}[${i}][opcion]" class="cb-input">
        <input type="hidden" name="${nameBase}[${i}][valor]" value="${i + 1}">
        <input type="hidden" name="${nameBase}[${i}][_destroy]" value="0">
      </div>
      <div class="lf4c4 error-cb-input"></div>
    `;

    cont.appendChild(row);
  }



  function removeOpcion(row) {
    const destroy = row.querySelector('input[name$="[_destroy]"]');
    const id = row.querySelector('input[name$="[id]"]');

    if (id && id.value && destroy) {
      destroy.value = "1";
      row.style.display = "none";
    } else {
      row.remove();
    }
  }

  function renderOpcionesSubcampo(subWrapper) {
    const select = subWrapper.querySelector("select.tipo-subcampo");
    if (!select) return;

    // asegurar contenedor
    let container = subWrapper.querySelector(".tipo-subcampo-container");
    if (!container) {
      container = document.createElement("div");
      container.className = "tipo-subcampo-container";
      subWrapper.appendChild(container);
    }

    // si no requiere opciones, limpiar
    if (!["4", "5"].includes(String(select.value))) {
      container.innerHTML = "";
      return;
    }

    // 🔥 NAME BASE ROBUSTO: sale del name real del select
    // componente[campos_attributes][0][subcampos_attributes][NEW_SUB][tipo_campo_id]
    // => componente[campos_attributes][0][subcampos_attributes][NEW_SUB][opciones_campos_attributes]
    if (!select.name || !select.name.includes("[tipo_campo_id]")) {
      console.warn("tipo-subcampo sin name esperado:", select);
      return;
    }
    const nameBase = select.name.replace(/\[tipo_campo_id\]$/, "[opciones_campos_attributes]");

    // opciones existentes (si en algún momento las agregás para subcampos)
    let opciones = [];
    try {
      const script = subWrapper.querySelector("script.opciones-json-sub");
      const raw = script?.textContent ? script.textContent.trim() : "[]";
      opciones = JSON.parse(raw || "[]").filter(o => (o.opcion || "").toString().trim() !== "");
    } catch (_) {
      opciones = [];
    }
    if (opciones.length === 0) opciones = [{}, {}];

    const rows = opciones.map((o, i) => {
      const id = o.id
        ? `<input type="hidden" name="${nameBase}[${i}][id]" value="${o.id}">`
        : "";
      const op = (o.opcion ?? "").toString();
      const val = (o.valor ?? i + 1).toString();

      return `
        <div class="long-field-4 opcion-row">
          <div class="lf4c1"><label>Opción ${i + 1}:</label></div>
          <div class="lf4c2"><button type="button" class="eliminar-opcion siac_button">❌</button></div>
          <div class="lf4c3">
            ${id}
            <input type="text" name="${nameBase}[${i}][opcion]" value="${op}" class="cb-input">
            <input type="hidden" name="${nameBase}[${i}][valor]" value="${val}">
            <input type="hidden" name="${nameBase}[${i}][_destroy]" value="0">
          </div>
          <div class="lf4c4 error-cb-input"></div>
        </div>`;
    }).join("");

    container.innerHTML = `
      <div class="combo-box-container">
        <div class="opciones-dinamicas">${rows}</div>
        <div class="long-field-2">
          <div class="lf2c1"><button type="button" class="agregar-opcion siac_button">Agregar opción</button></div>
        </div>
      </div>
    `;
  }



  // ============================================================
  // VALIDACIONES
  // ============================================================
  function mostrarError(contenedor, mensaje) {
    if (!contenedor) return;
    const errorMensaje = document.createElement("p");
    errorMensaje.className = "error-message";
    errorMensaje.textContent = mensaje;
    contenedor.appendChild(errorMensaje);
  }

  function limpiarErrores(contenedor) {
    if (!contenedor) return;
    contenedor.innerHTML = "";
  }

  function estaVisibleYNoDestroy(wrapper) {
    if (!wrapper) return false;
    if (wrapper.style.display === "none") return false;
    const destroy = wrapper.querySelector('input[name$="[_destroy]"]');
    if (destroy && destroy.value === "1") return false;
    return true;
  }

    function validarComponente(event) {
    let isValid = true;

    // -------------------------
    // BASE
    // -------------------------
    const nombre = document.querySelector("#inputNombreComponente");
    const descripcion = document.querySelector("#inputDescripcionComponente");
    const dimension =
        document.querySelector("#componenteDimensionId") ||
        document.querySelector("#componente_dimension_id") ||
        document.querySelector('select[name="componente[dimension_id]"]');

    const errorNombre = document.querySelector(".errorNombre");
    const errorDescripcion = document.querySelector(".errorDescripcion");
    const errorDimension = document.querySelector(".errorDimension");

    if (!nombre || !descripcion || !dimension) {
        console.warn("⚠️ validarComponente: faltan campos base en el DOM", {
        tieneNombre: !!nombre,
        tieneDescripcion: !!descripcion,
        tieneDimension: !!dimension,
        });
        return false;
    }

    limpiarErrores(errorNombre);
    limpiarErrores(errorDescripcion);
    limpiarErrores(errorDimension);

    if (!nombre.value.trim()) {
        mostrarError(errorNombre, 'El campo "Nombre de Componente" no puede estar vacío.');
        isValid = false;
    }

    if (!descripcion.value.trim()) {
        mostrarError(errorDescripcion, 'El campo "Descripción de Componente" no puede estar vacío.');
        isValid = false;
    }

    if (!dimension.value.trim()) {
        mostrarError(errorDimension, 'Debe seleccionar una opción válida en "Dimensión".');
        isValid = false;
    }

    // -------------------------
    // HELPERS internos
    // -------------------------
    function validarCampoWrapper(campoWrapper, labelGrupo, indexVisible) {
        // Ignorar campos borrados/ocultos
        if (!estaVisibleYNoDestroy(campoWrapper)) return;

        const pregunta = campoWrapper.querySelector(".inputPregunta");
        const tipoCampo = campoWrapper.querySelector("select.tipo-campo");
        const checkPO = campoWrapper.querySelector(".checkbox_pregunta_orientadora");
        const inputPO = campoWrapper.querySelector(".inputPreguntaOrientadora");

        const errorPreguntaCampo = campoWrapper.querySelector(".errorPreguntaCampo");
        const errorTipoCampo = campoWrapper.querySelector(".errorTipoCampo");
        const errorPreguntaOrientadora = campoWrapper.querySelector(".errorPreguntaOrientadora");

        limpiarErrores(errorPreguntaCampo);
        limpiarErrores(errorTipoCampo);
        limpiarErrores(errorPreguntaOrientadora);

        // Pregunta
        if (!pregunta || !pregunta.value.trim()) {
        mostrarError(
            errorPreguntaCampo,
            `La "Pregunta" del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
        );
        isValid = false;
        }

        // Tipo campo
        if (!tipoCampo || tipoCampo.value === "" || tipoCampo.value === "0") {
        mostrarError(
            errorTipoCampo,
            `Debe seleccionar un "Tipo de Campo" para el campo ${indexVisible} (${labelGrupo}).`
        );
        isValid = false;
        }

        // Pregunta orientadora (si está tildado)
        if (checkPO && checkPO.checked) {
        if (!inputPO || !inputPO.value.trim()) {
            mostrarError(
            errorPreguntaOrientadora,
            `La "Pregunta Orientadora" del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
            );
            isValid = false;
        }
        }

        // Opciones dinámicas SOLO si tipo es 4 o 5
        if (tipoCampo && ["4", "5"].includes(tipoCampo.value)) {
        const opcionesVisibles = Array.from(
            campoWrapper.querySelectorAll(".tipo-campo-container .opcion-row")
        ).filter((row) => row.style.display !== "none");

        // Si no hay filas, también es inválido
        if (opcionesVisibles.length === 0) {
            const cont = campoWrapper.querySelector(".tipo-campo-container");
            // intentamos mostrar el error en el primer error-cb-input disponible, si no existe, no rompe
            const fallback = cont?.querySelector(".error-cb-input") || errorTipoCampo;
            mostrarError(fallback, `Debe cargar opciones para el campo ${indexVisible} (${labelGrupo}).`);
            isValid = false;
        }

        opcionesVisibles.forEach((row, iOpt) => {
            const inputOpt = row.querySelector(".cb-input");
            const errorOpt = row.querySelector(".error-cb-input");
            limpiarErrores(errorOpt);

            if (!inputOpt || !inputOpt.value.trim()) {
            mostrarError(
                errorOpt,
                `La opción ${iOpt + 1} del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
            );
            isValid = false;
            }
        });
        }

        // -------------------------
        // SUBCAMPOS
        // -------------------------
        const subcampos = Array.from(campoWrapper.querySelectorAll(".subcampo")).filter(
        estaVisibleYNoDestroy
        );

        subcampos.forEach((sub, sidx0) => {
        const sidx = sidx0 + 1;

        const inputPreguntaSub = sub.querySelector(".inputPreguntaSubcampo");
        const tipoSub = sub.querySelector("select.tipo-subcampo");
        const checkPOSub = sub.querySelector(".checkbox_pregunta_orientadora_subcampo");
        const inputPOSub = sub.querySelector(".inputDescripcionSubcampo");

        // Contenedores de error:
        // Si todavía no agregaste divs, igual validamos: pero no se verá el texto.
        const errorPreguntaSub =
            sub.querySelector(".errorPreguntaSubcampo") || sub.querySelector(".errorSubcampo");
        const errorTipoSub =
            sub.querySelector(".errorTipoSubcampo") || sub.querySelector(".errorSubcampo");
        const errorPOSub =
            sub.querySelector(".errorPreguntaOrientadoraSubcampo") || sub.querySelector(".errorSubcampo");

        if (errorPreguntaSub) limpiarErrores(errorPreguntaSub);
        if (errorTipoSub) limpiarErrores(errorTipoSub);
        if (errorPOSub) limpiarErrores(errorPOSub);

        if (!inputPreguntaSub || !inputPreguntaSub.value.trim()) {
            mostrarError(
            errorPreguntaSub,
            `La "Pregunta del Subcampo" ${sidx} del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
            );
            isValid = false;
        }

        if (!tipoSub || tipoSub.value === "" || tipoSub.value === "0") {
            mostrarError(
            errorTipoSub,
            `Debe seleccionar un "Tipo de Campo" para el Subcampo ${sidx} del campo ${indexVisible} (${labelGrupo}).`
            );
            isValid = false;
        }

        if (checkPOSub && checkPOSub.checked) {
            if (!inputPOSub || !inputPOSub.value.trim()) {
            mostrarError(
                errorPOSub,
                `La "Pregunta Orientadora" del Subcampo ${sidx} del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
            );
            isValid = false;
            }
        }

        // Opciones de subcampo: solo si es 4 o 5
        if (tipoSub && ["4", "5"].includes(tipoSub.value)) {
            const opcionesSub = Array.from(
            sub.querySelectorAll(".tipo-subcampo-container .opcion-row, .tipo-subcampo-container .long-field-4")
            ).filter((row) => row.style.display !== "none");

            // si hay inputs .cb-input visibles, validarlos
            const inputsSub = opcionesSub
            .map((row) => ({
                row,
                inp: row.querySelector(".cb-input"),
                err: row.querySelector(".error-cb-input"),
            }))
            .filter((x) => x.inp);

            if (inputsSub.length === 0) {
            // sin estructura, pero el tipo requiere opciones: inválido
            const fallback = errorTipoSub || errorPreguntaSub;
            mostrarError(
                fallback,
                `Debe cargar opciones para el Subcampo ${sidx} del campo ${indexVisible} (${labelGrupo}).`
            );
            isValid = false;
            }

            inputsSub.forEach((x, iOpt) => {
            if (x.err) limpiarErrores(x.err);
            if (!x.inp.value.trim()) {
                mostrarError(
                x.err,
                `La opción ${iOpt + 1} del Subcampo ${sidx} del campo ${indexVisible} (${labelGrupo}) no puede estar vacía.`
                );
                isValid = false;
            }
            });
        }
        });
    }

    // -------------------------
    // CONVOCATORIA
    // -------------------------
    const camposConvo = Array.from(document.querySelectorAll("#campos-convo .nested-fields")).filter(
        estaVisibleYNoDestroy
    );

    camposConvo.forEach((campo, i) => {
        validarCampoWrapper(campo, "Convocatoria", i + 1);
    });

    // -------------------------
    // AUTOEVALUACIÓN
    // -------------------------
    const camposAuto = Array.from(
        document.querySelectorAll("#campos-autoeval .nested-fields")
    ).filter(estaVisibleYNoDestroy);

    camposAuto.forEach((campo, i) => {
        validarCampoWrapper(campo, "Autoevaluación", i + 1);
    });

    return isValid;
    }





    // 👇 EXPONER para que el submit delegado la pueda llamar
    window.validarComponente = validarComponente;

  // ============================================================
  // INIT UI + INIT VALIDACIÓN (con guardas anti-duplicación)
  // ============================================================
  function initUI() {
    // guarda global para no enganchar listeners al document más de una vez
    if (document.documentElement.dataset.componentesV2UiBound === "1") return;
    document.documentElement.dataset.componentesV2UiBound = "1";

    const convo = document.getElementById("campos-convo");
    const autoe = document.getElementById("campos-autoeval");
    if (!convo || !autoe) return;

    document.getElementById("add_field_convo")?.addEventListener("click", (e) => {
      e.preventDefault();
      addFromPrototype(convo);
    });

    document.getElementById("add_field_autoeval")?.addEventListener("click", (e) => {
      e.preventDefault();
      addFromPrototype(autoe);
    });

    // Changes
    document.addEventListener("change", (e) => {
      if (e.target.classList.contains("checkbox_pregunta_orientadora")) {
        const campo = e.target.closest(".nested-fields");
        togglePO(campo, e.target.checked, ".pregunta_orientadora_container");
      }

      if (e.target.classList.contains("checkbox_pregunta_orientadora_subcampo")) {
        const sub = e.target.closest(".subcampo");
        togglePO(sub, e.target.checked, ".pregunta_orientadora_container_subcampo");
      }

      if (e.target.classList.contains("tipo-campo")) {
        const campo = e.target.closest(".nested-fields");
        renderOpcionesCampo(campo);
      }

      if (e.target.classList.contains("tipo-subcampo")) {
        const sub = e.target.closest(".subcampo");
        if (sub) renderOpcionesSubcampo(sub);
      }
    });

    // Clicks (delegado)
    document.addEventListener("click", (e) => {
      const removeCampo = e.target.closest(".remove_fields");
      if (removeCampo) {
        e.preventDefault();
        const campo = removeCampo.closest(".nested-fields");
        markDestroy(campo, ".campo-destroy");
        return;
      }

      const addSub = e.target.closest(".add_subfield");
      if (addSub) {
        e.preventDefault();
        const campo = addSub.closest(".nested-fields");
        addSubFromTemplate(campo);
        return;
      }

      const removeSub = e.target.closest(".remove_subfields");
      if (removeSub) {
        e.preventDefault();
        const sub = removeSub.closest(".subcampo");
        markDestroy(sub, ".subcampo-destroy");
        return;
      }

      const addOpt = e.target.closest(".agregar-opcion");
      if (addOpt) {
        e.preventDefault();
        const combo = addOpt.closest(".combo-box-container");
        if (combo) addOpcion(combo);
        return;
      }

      const delOpt = e.target.closest(".eliminar-opcion");
      if (delOpt) {
        e.preventDefault();
        const row = delOpt.closest(".opcion-row");
        if (row) removeOpcion(row);
        return;
      }
    });

    // Inicial visual
    document.querySelectorAll(".nested-fields").forEach((campo) => {
      renderOpcionesCampo(campo);
      const po = campo.querySelector(".checkbox_pregunta_orientadora");
      if (po) togglePO(campo, po.checked, ".pregunta_orientadora_container");
    });

    document.querySelectorAll(".subcampo").forEach((sub) => {
      const po = sub.querySelector(".checkbox_pregunta_orientadora_subcampo");
      if (po) togglePO(sub, po.checked, ".pregunta_orientadora_container_subcampo");
    });

    document.querySelectorAll(".subcampo").forEach((sub) => {
      renderOpcionesSubcampo(sub);
      const po = sub.querySelector(".checkbox_pregunta_orientadora_subcampo");
      if (po) togglePO(sub, po.checked, ".pregunta_orientadora_container_subcampo");
    });

    renumerar();
  }

    function initAll() {
    initUI();
    }

    // Redmine/rails viejo: DOMContentLoaded suele ser suficiente
    document.addEventListener("DOMContentLoaded", initAll);

    // Por si hay turbo/turbolinks (si existe, no rompe)
    document.addEventListener("turbo:load", initAll);
    document.addEventListener("turbolinks:load", initAll);
})();


// ============================================================
// VALIDACIÓN: SUBMIT delegado (NO se duplica, NO se pierde)
// ============================================================
(function bindSubmitDelegadoUnaVez() {
  // guarda global para no duplicar el listener aunque el JS se evalúe 2 veces
  if (window.__SIAC_COMPONENTES_SUBMIT_BOUND__) return;
  window.__SIAC_COMPONENTES_SUBMIT_BOUND__ = true;

  document.addEventListener(
    "submit",
    function (e) {
      const form = e.target;
      if (!form || form.id !== "formComponente") return;

      // DEBUG: confirma que entró SIEMPRE
      console.log("🧪 submit capturado (#formComponente)");

      const ok = window.validarComponente(e);
      if (!ok) {
        e.preventDefault();
        e.stopPropagation();
        console.log("Formulario no válido.");
      } else {
        console.log("Formulario válido. Enviando...");
      }
    },
    true // CAPTURE: intercepta antes que Rails UJS / otras cosas
  );
})();
