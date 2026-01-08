// Función para validar la creación de un componente
function validarNuevoComponente(event) {
    let isValid = true;

    // Selección de los campos y contenedores de error
    const nombre = document.querySelector('#inputNombreComponente');
    const descripcion = document.querySelector('#inputDescripcionComponente');
    const dimension = document.querySelector('#componente_dimension_id');

    const errorNombre = document.querySelector('.errorNombre');
    const errorDescripcion = document.querySelector('.errorDescripcion');
    const errorDimension = document.querySelector('.errorDimension');
    
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
      const tipoCampoContainer = campo.querySelectorAll('.tipo-campo-container');
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

      if (!tipoCampo.value.trim()) {
        mostrarError(errorTipoCampo, `Debe seleccionar un "Tipo de Campo" para el campo ${index + 1}.`);
        isValid = false;
      }
      else {
        if (tipoCampo.value != '1') {
          tipoCampoContainer.forEach((combobox) => {
            const ComboBoxInputContainer = combobox.querySelectorAll('.long-field-4');
              ComboBoxInputContainer.forEach((container,index) => {
                const ComboBoxInput = container.querySelector('.cb-input');
                const ComboBoxInputError = container.querySelector('.error-cb-input');

                limpiarErrores(ComboBoxInputError);

                if(!ComboBoxInput.value.trim()){
                    mostrarError(ComboBoxInputError,`El Campo Opción ${index + 1} no puede estar vacío.`)
                    isValid = false;
                }

                console.log(ComboBoxInput);
              });
          });
        }
      }


      document.querySelectorAll('.subcampo').forEach((subcampo, index) => {
          const inputPregunta = subcampo.querySelector('.inputSubcampo');
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

          if (["4", "5", "6"].includes(tipoCampo.value)) {
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

      if (!tipoCampo.value.trim()) {
        mostrarError(errorTipoCampo, `Debe seleccionar un "Tipo de Campo" para el campo ${index + 1} de autoevaluación.`);
        isValid = false;
      }
      else {
        if (tipoCampo.value != '1') {
          tipoCampoContainer.forEach((combobox) => {
            const ComboBoxInputContainer = combobox.querySelectorAll('.long-field-4');
              ComboBoxInputContainer.forEach((container,index) => {
                const ComboBoxInput = container.querySelector('.cb-input');
                const ComboBoxInputError = container.querySelector('.error-cb-input');

                limpiarErrores(ComboBoxInputError);

                if(!ComboBoxInput.value.trim()){
                    mostrarError(ComboBoxInputError,`El Campo Opción ${index + 1} no puede estar vacío.`)
                    isValid = false;
                }

                console.log(ComboBoxInput);
              });
          });
        }

      }


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

    submitButton.addEventListener('click', function (event) {
      // Llamar a la función de validación
      const isValid = validarNuevoComponente();

      // Si es válido, permitir que se envíe el formulario, de lo contrario, prevenir el envío
      if (!isValid) {
        event.preventDefault(); // Evitar el envío del formulario si no es válido
        console.log('Formulario no válido.');
      } else {
        console.log('Formulario válido. Enviando...');
      }
    });
  });