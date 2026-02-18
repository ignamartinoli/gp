document.addEventListener("DOMContentLoaded", function () {
  
  let currentStep = 1;
  let siacCargado = false;


  function showStep(step) {
    document.querySelectorAll(".step-content").forEach(s => s.style.display = "none");
    document.querySelector(`.step-content[data-step='${step}']`).style.display = "block";

    document.querySelectorAll(".step").forEach(s => s.classList.remove("active"));
    document.querySelector(`.step[data-step='${step}']`).classList.add("active");
  }



  function validarPaso(step) {
    switch (step) {

      case 1: {
        const errorResol = document.querySelector(".errorResolucion");
        const errorNombre = document.querySelector(".errorNombre");

        limpiarErrores(errorResol);
        limpiarErrores(errorNombre);

        // Validar resolución
        const resolOK = validarResolucion(); // esta ya va a escribir errores

        // Validar nombre
        const nombreOK = inputNombre.value.trim() !== "";
        if (!nombreOK) {
          mostrarError(errorNombre, 'El campo "Nombre" no puede estar vacío.');
        }

        return resolOK && nombreOK;
      }

      case 2:
        return (
          convocatoria_titulaciones.value.trim() !== "" &&
          Array.from(document.querySelectorAll("#tableEspecialidades input[type=checkbox]"))
            .some(c => c.checked)
        );

      case 3: {
        // Mapa: name => selector del div de error (1 por input)
        const errMap = {
          fecha_inicio: ".errorFechaInicio",
          fecha_fin_capacitacion: ".errorFechaFinCapacitacion",
          fecha_fin_carga: ".errorFechaFinCarga",
          fecha_fin_revision: ".errorFechaFinRevision",
          fecha_fin_correcciones: ".errorFechaFinCorrecciones",
          fecha_fin_auditoria: ".errorFechaFinAuditoria",
          fecha_hasta: ".errorFechaHasta"
        };

        const getInput = (name) =>
          document.querySelector(`input[name='convocatoria[${name}]']`);

        const getErrEl = (name) =>
          document.querySelector(errMap[name]);

        // Limpia todos los errores + estilos
        for (const k of Object.keys(errMap)) {
          const errEl = getErrEl(k);
          if (errEl) limpiarErrores(errEl);

          const input = getInput(k);
          if (input) input.classList.remove("input-error");
        }

        const setFieldError = (name, msg) => {
          const errEl = getErrEl(name);
          const input = getInput(name);

          if (errEl) mostrarError(errEl, msg);
          if (input) input.classList.add("input-error");

          return false;
        };

        const getVal = (name) => {
          const el = getInput(name);
          console.log(`[SIAC][Paso3] ${name}=`, el ? el.value : null, el);
          return el ? el.value : "";
        };

        const parseYMD = (s) => {
          // input type="date" => "YYYY-MM-DD"
          const [y, m, d] = s.split("-").map(n => parseInt(n, 10));
          return new Date(y, m - 1, d, 12, 0, 0, 0); // 12:00 evita edge TZ
        };

        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);

        // Orden real de carga/validación (cierre al final)
        const chain = [
          { name: "fecha_inicio",          label: "Inicio" },
          { name: "fecha_fin_capacitacion",label: "Fin capacitación" },
          { name: "fecha_fin_carga",       label: "Fin carga" },
          { name: "fecha_fin_revision",    label: "Fin revisión" },
          { name: "fecha_fin_correcciones",label: "Fin correcciones" },
          { name: "fecha_fin_auditoria",   label: "Fin auditoría" },
          { name: "fecha_hasta",           label: "Fin convocatoria" }
        ];

        // 1) Required por campo (error debajo del input correcto)
        for (const f of chain) {
          const v = getVal(f.name);
          if (!v) {
            return setFieldError(f.name, `Debes seleccionar ${f.label.toLowerCase()}.`);
          }
        }

        // 2) No menor a hoy (error en el campo que falla)
        for (const f of chain) {
          const dt = parseYMD(getVal(f.name));
          if (dt < hoy) {
            return setFieldError(
              f.name,
              `${f.label} no puede ser menor a la fecha actual.`
            );
          }
        }

        // 3) Orden secuencial (error en el campo que rompe la cadena)
        for (let i = 1; i < chain.length; i++) {
          const prev = chain[i - 1];
          const curr = chain[i];

          const prevDt = parseYMD(getVal(prev.name));
          const currDt = parseYMD(getVal(curr.name));

          if (currDt < prevDt) {
            return setFieldError(
              curr.name,
              `${curr.label} debe ser igual o posterior a ${prev.label}.`
            );
          }
        }

        return true;
      }




      case 4:
        return Array.from(document.querySelectorAll("#tableSedes input[type=checkbox]"))
          .some(c => c.checked);

      case 5:
        return Array.from(document.querySelectorAll("#tableDimensiones input[type=checkbox]"))
          .some(c => c.checked);


      default:
        return true;
    }
  }


  document.querySelectorAll(".next-step").forEach(btn => {
    btn.addEventListener("click", function () {
      if (!validarPaso(currentStep)) {
        alert("Completá todos los campos obligatorios antes de avanzar.");
        return;
      }
      currentStep++;
      showStep(currentStep);
      if (currentStep === 5) {
        cargarPersonasSIAC();
      }

    });
  });

  document.querySelectorAll(".prev-step").forEach(btn => {
    btn.addEventListener("click", function () {
      currentStep--;
      showStep(currentStep);
    });
  });

  showStep(currentStep);
});
