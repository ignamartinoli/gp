// Función para validar el formato de la "Resolución"
function validarResolucion() {
  const resolucion = document.getElementById('inputResolucion');
  let value = resolucion.value;



  // Eliminar cualquier carácter no numérico ni '/'
  value = value.replace(/[^0-9/]/g, '');



  // Si el valor ya tiene 6 caracteres numéricos, asegurarse de que el '/' esté en la posición correcta
  if (value.length > 6 && value.indexOf('/') === -1) {
    value = value.slice(0, 6) + '/' + value.slice(6);
  }



  // Verificar que solo haya un '/' y que esté en la posición correcta (en la posición 7)
  if (value.indexOf('/') !== 6) {
    value = value.replace('/', ''); // Eliminar cualquier '/' fuera de lugar
  }



  // Limitar la longitud a 9 caracteres (6 números + '/' + 2 números)
  if (value.length > 9) {
    value = value.slice(0, 9);
  }



  resolucion.value = value;



  // Retornar si la resolución tiene el formato adecuado
  return /^\d{6}\/\d{2}$/.test(value); // Expresión regular para validar el formato XXXXXX/XX
}



// Función para validar la convocatoria
function validarNuevaConvocatoria(event) {
  let isValid = true;



  // Selección de los campos y contenedores de error
  const resolucion = document.querySelector('#inputResolucion');
  const nombre = document.querySelector('#inputNombre');
  const titulacion = document.querySelector('#convocatoria_titulaciones');
  const fechaInicio = document.querySelector('#convocatoria_fecha_inicio');
  const fechaHasta = document.querySelector('#convocatoria_fecha_hasta');
  const checkboxesDimensiones = document.querySelectorAll('#tableDimensiones tbody input[type="checkbox"]');
  const checkboxesSedes = document.querySelectorAll('#tableSedes tbody input[type="checkbox"]');
  const checkboxesEspecialidades = document.querySelectorAll('#tableEspecialidades tbody input[type="checkbox"]');



  const errorResolucion = document.querySelector('.errorResolucion');
  const errorNombre = document.querySelector('.errorNombre');
  const errorTitulacion = document.querySelector('.errorTitulacion');
  const errorFechaInicio = document.querySelector('.errorFechaInicio');
  const errorFechaHasta = document.querySelector('.errorFechaHasta');
  const errorDimensiones = document.querySelector('.errorDimensiones');
  const errorSedes = document.querySelector('.errorSedes');
  const errorEspecialidades = document.querySelector('.errorEspecialidades');



  // Limpiar errores previos
  limpiarErrores(errorResolucion);
  limpiarErrores(errorNombre);
  limpiarErrores(errorTitulacion);
  limpiarErrores(errorFechaInicio);
  limpiarErrores(errorFechaHasta);
  limpiarErrores(errorDimensiones);
  limpiarErrores(errorSedes);
  limpiarErrores(errorEspecialidades);



  // Validar el campo de Resolución (formato XXXXXX/XX)
  const resolucionValue = resolucion.value.trim();
  const resolucionPattern = /^\d{6}\/\d{2}$/; // Expresión regular para el formato "XXXXXX/XX"
  if (!resolucionPattern.test(resolucionValue)) {
    mostrarError(errorResolucion, 'El campo "Resolución" debe tener el formato correcto ("XXXXXX/XX").');
    isValid = false;
  }



  // Validar los campos
  if (!nombre.value.trim()) {
    mostrarError(errorNombre, 'El campo "Nombre" no puede estar vacío.');
    isValid = false;
  }



  if (!titulacion.value.trim()) {
    mostrarError(errorTitulacion, 'Debe seleccionar una opción válida en "Titulación".');
    isValid = false;
  }



  if (!fechaInicio.value.trim()) {
    mostrarError(errorFechaInicio, 'El campo "Fecha Inicio" no puede estar vacío.');
    isValid = false;
  }



  if (!fechaHasta.value.trim()) {
    mostrarError(errorFechaHasta, 'El campo "Fecha Hasta" no puede estar vacío.');
    isValid = false;
  }



  // Validar la fecha de inicio vs fecha de finalización
  const inicio = new Date(fechaInicio.value);
  const hasta = new Date(fechaHasta.value);
  if (inicio > hasta) {
    mostrarError(errorFechaInicio, 'La fecha de inicio no puede ser posterior a la fecha de finalización.');
    isValid = false;
  }



  // Validar checkboxes
  if (!Array.from(checkboxesDimensiones).some(checkbox => checkbox.checked)) {
    mostrarError(errorDimensiones, 'Debe seleccionar al menos una dimensión.');
    isValid = false;
  }



  if (!Array.from(checkboxesSedes).some(checkbox => checkbox.checked)) {
    mostrarError(errorSedes, 'Debe seleccionar al menos una sede.');
    isValid = false;
  }



  if (!Array.from(checkboxesEspecialidades).some(checkbox => checkbox.checked)) {
    mostrarError(errorEspecialidades, 'Debe seleccionar al menos una especialidad.');
    isValid = false;
  }



  // Si todas las validaciones pasaron, retornar true, de lo contrario false
  return isValid;
}


// Función para validar la creación de un componente
function validarNuevoComponente(event) {
  let isValid = true;

  // Selección de los campos y contenedores de error
  const nombre = document.querySelector('#inputNombreComponente');
  const descripcion = document.querySelector('#inputDescripcionComponente');
  const dimension = document.querySelector('#componente_dimension_id');

  const errorNombre = document.querySelector('.errorNombreComponente');
  const errorDescripcion = document.querySelector('.errorDescripcionComponente');
  const errorDimension = document.querySelector('.errorDimensionComponente');
  const errorCampos = document.querySelector('.errorCampos');

  // Limpiar errores previos
  limpiarErrores(errorNombre);
  limpiarErrores(errorDescripcion);
  limpiarErrores(errorDimension);
  limpiarErrores(errorCampos);

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
      const pregunta = campo.querySelector('.inputPregunta');
      const tipoCampo = campo.querySelector('select');

      if (!preguntaOrientadora.value.trim()) {
          mostrarError(errorCampos, `La "Pregunta Orientadora" del campo ${index + 1} no puede estar vacía.`);
          isValid = false;
      }

      if (!pregunta.value.trim()) {
          mostrarError(errorCampos, `La "Pregunta" del campo ${index + 1} no puede estar vacía.`);
          isValid = false;
      }

      if (!tipoCampo.value.trim()) {
          mostrarError(errorCampos, `Debe seleccionar un "Tipo de Campo" para el campo ${index + 1}.`);
          isValid = false;
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
  const form = document.querySelector('form');



  submitButton.addEventListener('click', function (event) {
    // Llamar a la función de validación
    const isValid = validarNuevaConvocatoria();



    // Si es válido, permitir que se envíe el formulario, de lo contrario, prevenir el envío
    if (!isValid) {
      event.preventDefault(); // Evitar el envío del formulario si no es válido
      console.log('Formulario no válido.');
    } else {
      console.log('Formulario válido. Enviando...');
    }
  });
});
 
