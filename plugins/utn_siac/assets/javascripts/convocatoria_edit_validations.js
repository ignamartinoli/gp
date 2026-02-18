// ======================================================
// SIAC - Validaciones EDIT Convocatoria (sin AR)
// - 1 solo punto: onsubmit inline
// - Errores SOLO en .errorXXX
// - No resetea campos
// - No bloquea submit
// - En "válido": fuerza envío nativo (form.submit()) para evitar interceptores externos
// ======================================================

(function () {
  // ---- Helpers ----
  window.mostrarError = function (contenedor, mensaje) {
    if (!contenedor) return;
    const p = document.createElement("p");
    p.className = "error-message";
    p.textContent = mensaje;
    contenedor.appendChild(p);
  };

  window.limpiarErrores = function (contenedor) {
    if (!contenedor) return;
    contenedor.innerHTML = "";
  };

  function setSubmitEnabled(form, enabled) {
    if (!form) return;
    const btn = form.querySelector("#inputSubmit") || form.querySelector('button[type="submit"], input[type="submit"]');
    if (btn) btn.disabled = !enabled;
  }

  function getInputByName(form, name) {
    if (!form) return null;
    return form.querySelector(`[name="${name}"]`);
  }

  function parseDateSafe(v) {
    if (!v) return null;
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
  }

  function dateGt(a, b) {
    return a && b && a.getTime() > b.getTime();
  }

  // ---- Resolución (misma lógica que NEW) ----
  window.validarResolucionEdit = function (form) {
    const resolucion = getInputByName(form, "convocatoria[resolucion]");
    const errorCont = document.querySelector(".errorResolucion");
    limpiarErrores(errorCont);

    if (!resolucion) return true;

    let value = resolucion.value;
    value = value.replace(/[^0-9/]/g, "");

    if (value.length > 6 && value.indexOf("/") === -1) {
      value = value.slice(0, 6) + "/" + value.slice(6);
    }
    if (value.indexOf("/") !== 6) {
      value = value.replace("/", "");
    }
    if (value.length > 9) value = value.slice(0, 9);

    resolucion.value = value;

    if (!/^\d{6}\/\d{2}$/.test(value)) {
      mostrarError(errorCont, 'El campo "Resolución" debe tener el formato "XXXXXX/XX".');
      return false;
    }

    const partes = value.split("/");
    const anioIngresado = parseInt(partes[1], 10);
    const anioActual = new Date().getFullYear() % 100;

    if (anioIngresado < anioActual) {
      mostrarError(errorCont, `El año de la resolución no puede ser menor a ${anioActual}.`);
      return false;
    }

    return true;
  };

  // ---- VALIDACIÓN EDIT (la única) ----
  let _submitting = false;

  window.validarEditarConvocatoria = function (event) {
    const form = event && event.target ? event.target : document.querySelector("form");
    if (!form) return true;

    // guard: evita doble envío si hay doble click
    if (_submitting) return false;

    setSubmitEnabled(form, true);

    const errorResolucion = document.querySelector(".errorResolucion");
    const errorNombre = document.querySelector(".errorNombre");
    const errorFinCap = document.querySelector(".errorFechaFinCapacitacion");
    const errorFinCarga = document.querySelector(".errorFechaFinCarga");
    const errorFinRev = document.querySelector(".errorFechaFinRevision");
    const errorFinCorr = document.querySelector(".errorFechaFinCorrecciones");
    const errorFinAud = document.querySelector(".errorFechaFinAuditoria");

    [
      errorResolucion, errorNombre,
      errorFinCap, errorFinCarga, errorFinRev, errorFinCorr, errorFinAud
    ].forEach(limpiarErrores);

    const nombre = getInputByName(form, "convocatoria[nombre]");

    const fIni = getInputByName(form, "convocatoria[fecha_inicio]");
    const fFin = getInputByName(form, "convocatoria[fecha_hasta]");

    const finCap = getInputByName(form, "convocatoria[fecha_fin_capacitacion]");
    const finCarga = getInputByName(form, "convocatoria[fecha_fin_carga]");
    const finRev = getInputByName(form, "convocatoria[fecha_fin_revision]");
    const finCorr = getInputByName(form, "convocatoria[fecha_fin_correcciones]");
    const finAud = getInputByName(form, "convocatoria[fecha_fin_auditoria]");

    // 1) Resolución: corta
    if (!validarResolucionEdit(form)) {
      event && event.preventDefault();
      setSubmitEnabled(form, true);
      return false;
    }

    // 2) Nombre: corta
    if (!nombre || !nombre.value.trim()) {
      mostrarError(errorNombre, 'El campo "Nombre" no puede estar vacío.');
      event && event.preventDefault();
      setSubmitEnabled(form, true);
      return false;
    }

    // 3) Fechas obligatorias
    const inicio = parseDateSafe(fIni && fIni.value);
    const fin = parseDateSafe(fFin && fFin.value);

    const cap = parseDateSafe(finCap && finCap.value);
    const carga = parseDateSafe(finCarga && finCarga.value);
    const rev = parseDateSafe(finRev && finRev.value);
    const corr = parseDateSafe(finCorr && finCorr.value);
    const aud = parseDateSafe(finAud && finAud.value);

    let ok = true;
    if (!cap)   { mostrarError(errorFinCap,   "El campo Fin capacitación no puede estar vacío."); ok = false; }
    if (!carga) { mostrarError(errorFinCarga, "El campo Fin carga no puede estar vacío.");       ok = false; }
    if (!rev)   { mostrarError(errorFinRev,   "El campo Fin revisión no puede estar vacío.");    ok = false; }
    if (!corr)  { mostrarError(errorFinCorr,  "El campo Fin correcciones no puede estar vacío.");ok = false; }
    if (!aud)   { mostrarError(errorFinAud,   "El campo Fin auditoría no puede estar vacío.");   ok = false; }

    if (!ok) {
      event && event.preventDefault();
      setSubmitEnabled(form, true);
      return false;
    }

    // 4) Orden + rango
    if (inicio && dateGt(inicio, cap))  { mostrarError(errorFinCap,   "Debe ser igual o posterior a Fecha inicio."); ok = false; }
    if (dateGt(cap, carga))             { mostrarError(errorFinCarga, "Debe ser igual o posterior a Fin capacitación."); ok = false; }
    if (dateGt(carga, rev))             { mostrarError(errorFinRev,   "Debe ser igual o posterior a Fin carga."); ok = false; }
    if (dateGt(rev, corr))              { mostrarError(errorFinCorr,  "Debe ser igual o posterior a Fin revisión."); ok = false; }
    if (dateGt(corr, aud))              { mostrarError(errorFinAud,   "Debe ser igual o posterior a Fin correcciones."); ok = false; }
    if (fin && dateGt(aud, fin))        { mostrarError(errorFinAud,   "No puede ser posterior a la Fecha fin de convocatoria."); ok = false; }

    if (!ok) {
      event && event.preventDefault();
      setSubmitEnabled(form, true);
      return false;
    }

    // === VÁLIDO ===
    // Para evitar que algún JS externo cancele el submit, forzamos envío nativo:
    event && event.preventDefault(); // cancelamos el envío “normal” (que puede ser interceptado)
    _submitting = true;
    setSubmitEnabled(form, true);

    // Sacar onsubmit para no reentrar y enviar nativo
    form.removeAttribute("onsubmit");
    form.submit();

    return false;
  };
})();
