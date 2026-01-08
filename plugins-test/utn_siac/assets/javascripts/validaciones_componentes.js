// Función para validar la creación de un componente
  function validarNuevoComponente(event) {
    let isValid = true;

    // Selección de los campos y contenedores de error
    const nombre     = document.querySelector('#inputNombreComponente');
    const descripcion = document.querySelector('#inputDescripcionComponente');
    const dimension  = document.querySelector('#componenteDimensionId') 
                  || document.querySelector('#componente_dimension_id')   // id por defecto de Rails
                  || document.querySelector('select[name="componente[dimension_id]"]');

    const errorNombre      = document.querySelector('.errorNombre');
    const errorDescripcion = document.querySelector('.errorDescripcion');
    const errorDimension   = document.querySelector('.errorDimension');

    // 🛡️ Si alguno de los campos base NO existe, no validamos nada para no romper otras vistas
    if (!nombre || !descripcion || !dimension) {
      console.warn("⚠️ validarNuevoComponente: faltan campos básicos en el DOM", {
        tieneNombre: !!nombre,
        tieneDescripcion: !!descripcion,
        tieneDimension: !!dimension
      });
      // Mejor bloquear el envío, para no dejar pasar nada raro
      return false;
    }

    // Limpiar errores previos
    limpiarErrores(errorNombre);
    limpiarErrores(errorDescripcion);
    limpiarErrores(errorDimension);

    // Validar nombre del componente
    if (!nombre.value.trim()) {
      mostrarError(errorNombre, 'El campo "Nombre de Componente" no puede estar vacío.');
      isValid = false;
    }

    // Validar descripción del componente
    if (!descripcion.value.trim()) {
      mostrarError(errorDescripcion, 'El campo "Descripción de Componente" no puede estar vacío.');
      isValid = false;
    }

    // Validar selección de dimensión
    if (!dimension.value.trim()) {
      mostrarError(errorDimension, 'Debe seleccionar una opción válida en "Dimensión".');
      isValid = false;
    }


    // Validar los campos anidados (preguntas)
    const campos = document.querySelectorAll('.nested-fields');
    campos.forEach((campo, index) => {
      const preguntaOrientadora = campo.querySelector('.inputPreguntaOrientadora');
      const preguntaOrientadoraCheckbox = campo.querySelector(".checkbox_pregunta_orientadora");
      const pregunta = campo.querySelector('.inputPregunta');
      const tipoCampo = campo.querySelector('select');
      const errorPreguntaCampo = campo.querySelector('.errorPreguntaCampo'); // Limpiar los errores de cada campo
      const errorPreguntaOrientadora = campo.querySelector('.errorPreguntaOrientadora');
      const errorTipoCampo = campo.querySelector('.errorTipoCampo');
      const tipoCampoContainer = campo.querySelector('.tipo-campo-container');
      const subcamposContainer = campo.querySelector('.subcampos-container');

      // Limpiar errores previos
      limpiarErrores(errorTipoCampo);
      limpiarErrores(errorPreguntaCampo);
      limpiarErrores(errorPreguntaOrientadora);

      // Verificar si el checkbox está marcado y la pregunta orientadora no está vacía
      if (preguntaOrientadoraCheckbox.checked && !preguntaOrientadora.value.trim()) {
        mostrarError(errorPreguntaOrientadora, `La "Pregunta Orientadora" del campo ${index + 1} no puede estar vacía.`);
        isValid = false;
      }

      if (!pregunta.value.trim()) {
        mostrarError(errorPreguntaCampo, `La "Pregunta" del campo ${index + 1} no puede estar vacía.`);
        isValid = false;
      }

      if (tipoCampo.value === "" || tipoCampo.value === "0") {
        mostrarError(errorTipoCampo, `Debe seleccionar un "Tipo de Campo" para el campo ${index + 1}.`);
        isValid = false;
      }
      else {
        if (tipoCampo.value != '1') {

          // Convertir tipoCampoContainer en una lista iterable SIEMPRE
          const containers = tipoCampoContainer
            ? (tipoCampoContainer.length !== undefined
                ? Array.from(tipoCampoContainer)        // NodeList → array
                : [tipoCampoContainer])                 // Element único → array
            : [];

          containers.forEach((tcContainer) => {
            const ComboBoxInputContainer = tcContainer.querySelectorAll('.long-field-4');

            ComboBoxInputContainer.forEach((container, index) => {
              const ComboBoxInput = container.querySelector('.cb-input');
              const ComboBoxInputError = container.querySelector('.error-cb-input');

              limpiarErrores(ComboBoxInputError);

              if (!ComboBoxInput || !ComboBoxInput.value.trim()) {
                mostrarError(
                  ComboBoxInputError,
                  `El Campo Opción ${index + 1} no puede estar vacío.`
                );
                isValid = false;
              }
            });
          });

        }
      }



      campo.querySelectorAll('.subcampo').forEach((subcampo, index) => {
          const inputPregunta = subcampo.querySelector('.inputPreguntaSubcampo');
          const tipoCampo = subcampo.querySelector('.tipo-subcampo');
          const errores = subcampo.querySelectorAll('.errorSubcampo');
      
          // Limpiamos errores anteriores
          errores.forEach(e => e.innerHTML = "");
      
          // Validamos la pregunta
          if (!inputPregunta || !inputPregunta.value.trim()) {
            mostrarError(errores[0], "La pregunta no puede estar vacía.")
            isValid = false;
          }
      
          // Validamos el tipo de campo seleccionado
          if (!tipoCampo || tipoCampo.value === "0") {
              mostrarError(errores[1], "Debe seleccionar un tipo de campo.")
            isValid = false;
          }

          if (["8", "9"].includes(tipoCampo.value)) {
            const tipoSubcampoContainer = subcampo.querySelector('.tipo-subcampo-container');
            
            if (tipoSubcampoContainer) {
              const comboBoxInputContainers = tipoSubcampoContainer.querySelectorAll('.long-field-4');
          
              comboBoxInputContainers.forEach((container, index) => {
                const ComboBoxInput = container.querySelector('.cb-input');
                const ComboBoxInputError = container.querySelector('.error-cb-input');
          
                limpiarErrores(ComboBoxInputError);
          
                if (!ComboBoxInput || !ComboBoxInput.value.trim()) {
                  mostrarError(ComboBoxInputError, `El Campo Opción ${index + 1} no puede estar vacío.`);
                  isValid = false;
                }
              });
            }
          }
          

        });
    });

    // Validar los campos anidados (preguntas)
    const camposAutoeval = document.querySelectorAll('.nested-fields-autoeval');
    camposAutoeval.forEach((campo, index) => {
      const preguntaOrientadora = campo.querySelector('.inputPreguntaOrientadora');
      const preguntaOrientadoraCheckbox = campo.querySelector(".checkbox_pregunta_orientadora");
      const pregunta = campo.querySelector('.inputPregunta');
      const tipoCampo = campo.querySelector('select');
      const errorPreguntaCampo = campo.querySelector('.errorPreguntaCampo'); // Limpiar los errores de cada campo
      const errorPreguntaOrientadora = campo.querySelector('.errorPreguntaOrientadora');
      const errorTipoCampo = campo.querySelector('.errorTipoCampo');
      const tipoCampoContainer = campo.querySelectorAll('.tipo-campo-container')

      // Limpiar errores previos
      limpiarErrores(errorTipoCampo);
      limpiarErrores(errorPreguntaCampo);
      limpiarErrores(errorPreguntaOrientadora);

      // Verificar si el checkbox está marcado y la pregunta orientadora no está vacía
      if (preguntaOrientadoraCheckbox.checked && !preguntaOrientadora.value.trim()) {
        mostrarError(errorPreguntaOrientadora, `La "Pregunta Orientadora" del campo ${index + 1} de autoevaluación no puede estar vacía.`);
        isValid = false;
      }

      if (!pregunta.value.trim()) {
        mostrarError(errorPreguntaCampo, `La "Pregunta" del campo ${index + 1} de autoevaluación no puede estar vacía.`);
        isValid = false;
      }

      if (tipoCampo.value === "" || tipoCampo.value === "0") {
        mostrarError(errorTipoCampo, `Debe seleccionar un "Tipo de Campo" para el campo ${index + 1} de autoevaluación.`);
        isValid = false;
      }
      else {
        if (tipoCampo.value != '1') {

          // Convertir tipoCampoContainer en una lista iterable SIEMPRE
          const containers = tipoCampoContainer
            ? (tipoCampoContainer.length !== undefined
                ? Array.from(tipoCampoContainer)        // NodeList → array
                : [tipoCampoContainer])                 // Element único → array
            : [];

          containers.forEach((tcContainer) => {
            const ComboBoxInputContainer = tcContainer.querySelectorAll('.long-field-4');

            ComboBoxInputContainer.forEach((container, index) => {
              const ComboBoxInput = container.querySelector('.cb-input');
              const ComboBoxInputError = container.querySelector('.error-cb-input');

              limpiarErrores(ComboBoxInputError);

              if (!ComboBoxInput || !ComboBoxInput.value.trim()) {
                mostrarError(
                  ComboBoxInputError,
                  `El Campo Opción ${index + 1} no puede estar vacío.`
                );
                isValid = false;
              }
            });
          });

        }
      }


      // === VALIDACIÓN DE SUBCAMPOS (AUTOEVALUACIÓN) ===
      const subcampos = campo.querySelectorAll('.fs-subcampo');

      subcampos.forEach((subcampo, indexSub) => {

        const inputPreguntaSub = subcampo.querySelector('.inputPreguntaSubcampo');
        const errorPreguntaSub = subcampo.querySelector('.errorPreguntaSubcampo');

        const tipoSub = subcampo.querySelector('.tipo-subcampo');
        const errorTipoSub = subcampo.querySelector('.errorTipoSubcampo');

        const tienePO = subcampo.querySelector('.checkbox_pregunta_orientadora_subcampo');
        const descripcionPO = subcampo.querySelector('.inputDescripcionSubcampo');
        const errorPO = subcampo.querySelector('.errorSubcampo');

        // limpiar errores visibles (si existen)
        if (errorPreguntaSub) limpiarErrores(errorPreguntaSub);
        if (errorTipoSub) limpiarErrores(errorTipoSub);
        if (errorPO) limpiarErrores(errorPO);

        // Pregunta del subcampo
        if (!inputPreguntaSub || !inputPreguntaSub.value.trim()) {
          mostrarError(
            errorPreguntaSub,
            `La "Pregunta del Subcampo ${indexSub + 1}" no puede estar vacía.`
          );
          isValid = false;
        }

        // Tipo de subcampo
        if (!tipoSub || tipoSub.value === "0") {
          mostrarError(
            errorTipoSub,
            `Debes seleccionar un "Tipo de Campo" para el Subcampo ${indexSub + 1}.`
          );
          isValid = false;
        }

        // Pregunta orientadora
        if (tienePO && tienePO.checked && (!descripcionPO || !descripcionPO.value.trim())) {
          mostrarError(
            errorPO,
            `La "Pregunta Orientadora" del subcampo ${indexSub + 1} no puede estar vacía.`
          );
          isValid = false;
        }

        // Validar opciones dinámicas si es select
        if (tipoSub && (tipoSub.value === "8" || tipoSub.value === "9")) {    // selección única o múltiple

          const opciones = subcampo.querySelectorAll('.cb-input');

          opciones.forEach((op, idxOp) => {
            const errorOp = op.closest('.long-field-4')?.querySelector('.error-cb-input');
            if (errorOp) limpiarErrores(errorOp);

            if (!op.value.trim()) {
              mostrarError(
                errorOp,
                `La opción ${idxOp + 1} del Subcampo ${indexSub + 1} no puede estar vacía.`
              );
              isValid = false;
            }
          });

        }

      });



    });


    return isValid;
  }


// Función para mostrar errores
function mostrarError(contenedor, mensaje) {
    const errorMensaje = document.createElement('p');
    errorMensaje.className = 'error-message';
    errorMensaje.textContent = mensaje;
    contenedor.appendChild(errorMensaje);
  }



  // Función para limpiar errores
  function limpiarErrores(contenedor) {
    contenedor.innerHTML = '';
  }



  // Escuchar el evento del botón
  document.addEventListener('DOMContentLoaded', function () {
    const submitButton = document.querySelector('#inputSubmit');
    if (!submitButton) return; // 🛡️ si no hay botón, no hacemos nada

    submitButton.addEventListener('click', function (event) {
      const isValid = validarNuevoComponente(event);

      if (!isValid) {
        event.preventDefault();
        console.log('Formulario no válido.');
      } else {
        console.log('Formulario válido. Enviando...');
      }
    });
  });
