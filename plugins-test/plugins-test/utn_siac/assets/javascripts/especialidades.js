document.addEventListener('DOMContentLoaded', function() {
  
  // Desmarcar todos los checkboxes en las tablas
  const checkboxesTables = [
      '#tableDimensiones input[type="checkbox"]',
      '#tableSedes input[type="checkbox"]',
      '#tableEspecialidades input[type="checkbox"]'
  ];

  checkboxesTables.forEach(tableSelector => {
      const checkboxes = document.querySelectorAll(tableSelector);
      checkboxes.forEach(checkbox => {
          checkbox.checked = false; // Desmarcar el checkbox
      });
  });

  // Restablecer el select de titulacion al valor por defecto
  const selectTitulacion = document.querySelector('#convocatoria_titulaciones');
  if (selectTitulacion) {
      selectTitulacion.selectedIndex = 0; // Establecer el valor predeterminado (blank)
  }

  if (selectTitulacion) {
    selectTitulacion.addEventListener('change', function(event) {
      let titulacionValue = event.target.value;

      if (!titulacionValue) { 
        titulacionValue = 0;
      }

      // Desmarcar el checkbox del encabezado
      document.getElementById('checkBoxConv').checked = false;
      document.getElementById('checkBoxConv').indeterminate = false;

      console.log('value: ' + titulacionValue);

      // Realizamos la solicitud AJAX con la titulacion como parte de la URL
      fetch(`/convocatorias/cargar_especialidades/${titulacionValue}`, {
        method: 'GET',
      })
      .then(response => response.text())
      .then(data => {
        // Actualizamos el contenedor con las nuevas especialidades
        document.querySelector('#especialidades-container').innerHTML = data;
      })
      .catch(error => console.error('Error al cargar las especialidades:', error));
    });
  }


  // Especialidades
  const selectAllCheckbox = document.getElementById('checkBoxConv'); // checkbox "Seleccionar Todo"

  // Delegación de eventos para los checkboxes dinámicos en el tbody de la tabla "tableEspecialidades"
  document.querySelector('#tableEspecialidades').addEventListener('change', function(event) {
    // Verificamos si el evento proviene de un checkbox dentro del tbody de la tabla específica
    if (event.target.type === 'checkbox' && event.target.closest('tbody')) {
      const rowCheckboxes = document.querySelectorAll('#tableEspecialidades tbody input[type="checkbox"]');
      
      // Verificar si todos los checkboxes están seleccionados
      const allChecked = Array.from(rowCheckboxes).every(function(checkbox) {
        return checkbox.checked;
      });

      // Actualizamos el estado del checkbox "Seleccionar Todo"
      selectAllCheckbox.checked = allChecked;

      // Si no todos están seleccionados, el "Seleccionar Todo" será indeterminado
      selectAllCheckbox.indeterminate = !allChecked && Array.from(rowCheckboxes).some(function(checkbox) {
        return checkbox.checked;
      });
    }
  });

  // Cuando el checkbox "Seleccionar Todo" cambia
  selectAllCheckbox.addEventListener('change', function() {
    console.log('El checkbox "Seleccionar Todo" está ahora marcado:', selectAllCheckbox.checked);

    // Seleccionar o deseleccionar todos los checkboxes del tbody de la tabla específica
    const rowCheckboxes = document.querySelectorAll('#tableEspecialidades tbody input[type="checkbox"]');
    rowCheckboxes.forEach(function(checkbox) {
      checkbox.checked = selectAllCheckbox.checked;
      console.log('Checkbox marcado: ', checkbox.checked); // Log para ver el estado de cada checkbox
    });
  });




// Sedes
const selectAllCheckboxSedes = document.getElementById('checkBoxConvSedes'); // checkbox "Seleccionar Todo" para la tabla de Sedes

// Delegación de eventos para los checkboxes dinámicos en el tbody de la tabla "tableSedes"
document.querySelector('#tableSedes').addEventListener('change', function(event) {
  // Verificamos si el evento proviene de un checkbox dentro del tbody de la tabla específica
  if (event.target.type === 'checkbox' && event.target.closest('tbody')) {
    // Seleccionamos solo los checkboxes dentro de la tabla "tableSedes"
    const rowCheckboxesSedes = document.querySelectorAll('#tableSedes tbody input[type="checkbox"]');
    
    // Verificar si todos los checkboxes están seleccionados
    const allCheckedSedes = Array.from(rowCheckboxesSedes).every(function(checkbox) {
      return checkbox.checked;
    });

    // Actualizamos el estado del checkbox "Seleccionar Todo" de la tabla "Sedes"
    selectAllCheckboxSedes.checked = allCheckedSedes;

    // Si no todos están seleccionados, el "Seleccionar Todo" será indeterminado
    selectAllCheckboxSedes.indeterminate = !allCheckedSedes && Array.from(rowCheckboxesSedes).some(function(checkbox) {
      return checkbox.checked;
    });
  }
});

// Cuando el checkbox "Seleccionar Todo" para "Sedes" cambia
selectAllCheckboxSedes.addEventListener('change', function() {
  console.log('El checkbox "Seleccionar Todo" para Sedes está ahora marcado:', selectAllCheckboxSedes.checked);

  // Seleccionar o deseleccionar todos los checkboxes del tbody de la tabla "tableSedes"
  const rowCheckboxesSedes = document.querySelectorAll('#tableSedes tbody input[type="checkbox"]');
  rowCheckboxesSedes.forEach(function(checkbox) {
    checkbox.checked = selectAllCheckboxSedes.checked;
    console.log('Checkbox marcado: ', checkbox.checked); // Log para ver el estado de cada checkbox
  });
});


  

// Dimensiones
const selectAllCheckboxDimensiones = document.getElementById('checkBoxConvDimensiones'); // checkbox "Seleccionar Todo" para la tabla de Dimensiones

// Delegación de eventos para los checkboxes dinámicos en el tbody de la tabla "tableDimensiones"
document.querySelector('#tableDimensiones').addEventListener('change', function(event) {
  // Verificamos si el evento proviene de un checkbox dentro del tbody de la tabla específica
  if (event.target.type === 'checkbox' && event.target.closest('tbody')) {
    // Seleccionamos solo los checkboxes dentro de la tabla "tableDimensiones"
    const rowCheckboxesDimensiones = document.querySelectorAll('#tableDimensiones tbody input[type="checkbox"]');
    
    // Verificar si todos los checkboxes están seleccionados
    const allCheckedDimensiones = Array.from(rowCheckboxesDimensiones).every(function(checkbox) {
      return checkbox.checked;
    });

    // Actualizamos el estado del checkbox "Seleccionar Todo" de la tabla "Dimensiones"
    selectAllCheckboxDimensiones.checked = allCheckedDimensiones;

    // Si no todos están seleccionados, el "Seleccionar Todo" será indeterminado
    selectAllCheckboxDimensiones.indeterminate = !allCheckedDimensiones && Array.from(rowCheckboxesDimensiones).some(function(checkbox) {
      return checkbox.checked;
    });
  }
});

// Cuando el checkbox "Seleccionar Todo" para "Dimensiones" cambia
selectAllCheckboxDimensiones.addEventListener('change', function() {
  console.log('El checkbox "Seleccionar Todo" para Dimensiones está ahora marcado:', selectAllCheckboxDimensiones.checked);

  // Seleccionar o deseleccionar todos los checkboxes del tbody de la tabla "tableDimensiones"
  const rowCheckboxesDimensiones = document.querySelectorAll('#tableDimensiones tbody input[type="checkbox"]');
  rowCheckboxesDimensiones.forEach(function(checkbox) {
    checkbox.checked = selectAllCheckboxDimensiones.checked;
    console.log('Checkbox marcado: ', checkbox.checked); // Log para ver el estado de cada checkbox
  });
});



});

