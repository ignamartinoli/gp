// Función para validar el formato de la "Resolución"
// Función para validar el formato de la "Resolución"
function validarResolucion() {
  const resolucion = document.getElementById('inputResolucion');
  const errorCont = document.querySelector('.errorResolucion');
  limpiarErrores(errorCont);

  let value = resolucion.value;

  // limpiar caracteres inválidos
  value = value.replace(/[^0-9/]/g, '');

  if (value.length > 6 && value.indexOf('/') === -1) {
    value = value.slice(0, 6) + '/' + value.slice(6);
  }

  if (value.indexOf('/') !== 6) {
    value = value.replace('/', '');
  }

  if (value.length > 9) {
    value = value.slice(0, 9);
  }

  resolucion.value = value;

  // Validación de formato
  if (!/^\d{6}\/\d{2}$/.test(value)) {
    mostrarError(errorCont, 'Debe tener formato XXXXXX/XX');
    return false;
  }

  // Validación del año
  const partes = value.split("/");
  const añoIngresado = parseInt(partes[1], 10);
  const añoActual = new Date().getFullYear() % 100;

  if (añoIngresado < añoActual) {
    mostrarError(errorCont, `El año no puede ser menor a ${añoActual}`);
    return false;
  }

  return true;
}






// Función para validar la convocatoria
function validarNuevaConvocatoria(event) {
  let isValid = true;

  // Campos
  const resolucion = document.querySelector('#inputResolucion');
  const nombre = document.querySelector('#inputNombre');
  const titulacion = document.querySelector('#convocatoria_titulaciones');
  const fechaInicio = document.querySelector('#convocatoria_fecha_inicio');
  const fechaHasta = document.querySelector('#convocatoria_fecha_hasta');
  const checkboxesDimensiones = document.querySelectorAll('#tableDimensiones tbody input[type="checkbox"]');
  const checkboxesSedes = document.querySelectorAll('#tableSedes tbody input[type="checkbox"]');
  const checkboxesEspecialidades = document.querySelectorAll('#tableEspecialidades tbody input[type="checkbox"]');

  // Contenedores error
  const errorResolucion = document.querySelector('.errorResolucion');
  const errorNombre = document.querySelector('.errorNombre');
  const errorTitulacion = document.querySelector('.errorTitulacion');
  const errorFechaInicio = document.querySelector('.errorFechaInicio');
  const errorFechaHasta = document.querySelector('.errorFechaHasta');
  const errorDimensiones = document.querySelector('.errorDimensiones');
  const errorSedes = document.querySelector('.errorSedes');
  const errorEspecialidades = document.querySelector('.errorEspecialidades');

  // Limpiar errores
  [
    errorResolucion, errorNombre, errorTitulacion,
    errorFechaInicio, errorFechaHasta,
    errorDimensiones, errorSedes, errorEspecialidades
  ].forEach(e => limpiarErrores(e));

  // ---- VALIDACIÓN RESOLUCIÓN ----
  if (!validarResolucion()) {
    const añoActual = new Date().getFullYear() % 100;
    if (/^\d{6}\/\d{2}$/.test(resolucion.value)) {
      const partes = resolucion.value.split("/");
      const añoIngresado = parseInt(partes[1], 10);
      if (añoIngresado < añoActual) {
        mostrarError(errorResolucion, `El año de la resolución no puede ser menor a ${añoActual}.`);
      }
    } else {
      mostrarError(errorResolucion, 'El campo "Resolución" debe tener el formato "XXXXXX/XX".');
    }
    return false; // CORTA, no muestra otros errores
  }

  // ---- RESTO DE VALIDACIONES ----
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

  const inicio = new Date(fechaInicio.value);
  const hasta = new Date(fechaHasta.value);
  if (inicio > hasta) {
    mostrarError(errorFechaInicio, 'La fecha de inicio no puede ser posterior a la fecha de finalización.');
    isValid = false;
  }

  if (!Array.from(checkboxesDimensiones).some(ch => ch.checked)) {
    mostrarError(errorDimensiones, 'Debe seleccionar al menos una dimensión.');
    isValid = false;
  }

  if (!Array.from(checkboxesSedes).some(ch => ch.checked)) {
    mostrarError(errorSedes, 'Debe seleccionar al menos una sede.');
    isValid = false;
  }

  if (!Array.from(checkboxesEspecialidades).some(ch => ch.checked)) {
    mostrarError(errorEspecialidades, 'Debe seleccionar al menos una especialidad.');
    isValid = false;
  }

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
 
