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
        const errorIni = document.querySelector(".errorFechaInicio");
        const errorFin = document.querySelector(".errorFechaHasta");

        limpiarErrores(errorIni);
        limpiarErrores(errorFin);

        const inicioStr = convocatoria_fecha_inicio.value;
        const hastaStr = convocatoria_fecha_hasta.value;

        // ambos obligatorios
        if (!inicioStr) {
          mostrarError(errorIni, "Debes seleccionar la fecha de inicio.");
          return false;
        }
        if (!hastaStr) {
          mostrarError(errorFin, "Debes seleccionar la fecha de cierre.");
          return false;
        }

        function parseFechaDMY(fechaStr) {
          // formato esperado: yyyy-mm-dd
          const partes = fechaStr.split("-");
          return new Date(parseInt(partes[0]), parseInt(partes[1]) - 1, parseInt(partes[2]));
        }  

        const inicio = parseFechaDMY(inicioStr);
        const hasta = parseFechaDMY(hastaStr);

        // hoy a las 00:00
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);

        // inicio puede ser hoy, pero NO menor a hoy
        if (inicio < hoy) {
          mostrarError(errorIni, "La fecha de inicio no puede ser menor a la fecha actual.");
          return false;
        }

        // cierre debe ser HOY o posterior (no menor)
        if (hasta < hoy) {
          mostrarError(errorFin, "La fecha de cierre no puede ser menor a la fecha actual.");
          return false;
        }

        // cierre > inicio (no puede ser igual ni menor)
        if (hasta <= inicio) {
          mostrarError(errorFin, "La fecha de cierre debe ser posterior a la fecha de inicio.");
          return false;
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
