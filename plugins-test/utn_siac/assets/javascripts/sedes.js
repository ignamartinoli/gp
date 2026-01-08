document.addEventListener('DOMContentLoaded', function () {
  const tableEspecialidades = document.getElementById('tableEspecialidades');
  const tableSedes = document.getElementById('tableSedes');

  if (tableEspecialidades) {
    tableEspecialidades.addEventListener('change', function (event) {
      if (event.target.type === 'checkbox') {
        const especialidadesSeleccionadas = Array.from(
          tableEspecialidades.querySelectorAll('tbody input[type="checkbox"]:checked')
        ).map(checkbox => checkbox.closest('tr').id);

        console.log('Especialidades seleccionadas:', especialidadesSeleccionadas);

        // Obtener el token CSRF desde el meta tag
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        fetch(`/convocatorias/cargar_sedes`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken // Incluir el token CSRF
          },
          body: JSON.stringify({ especialidades: especialidadesSeleccionadas }),
        })
          .then(response => response.text())
          .then(data => {
            document.querySelector('#tableSedes tbody').innerHTML = data;
          })
          .catch(error => console.error('Error al cargar las sedes:', error));
      }
    });
  }
});
