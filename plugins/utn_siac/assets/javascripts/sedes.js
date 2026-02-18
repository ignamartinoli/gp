document.addEventListener('DOMContentLoaded', function () {
  const tableEspecialidades = document.getElementById('tableEspecialidades');

  if (!tableEspecialidades) return;

  tableEspecialidades.addEventListener('change', function (event) {
    if (event.target.type !== 'checkbox') return;

    const especialidadesSeleccionadas = Array.from(
      tableEspecialidades.querySelectorAll('tbody input[name="especialidad_ids[]"]:checked')
    ).map(cb => cb.value);

    console.log('Especialidades seleccionadas:', especialidadesSeleccionadas);

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    fetch(`/convocatorias/cargar_sedes`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: JSON.stringify({ especialidades: especialidadesSeleccionadas })
    })
      .then(r => r.text())
      .then(html => {
        const sedesContainer = document.getElementById('sedes-container');
        if (sedesContainer) sedesContainer.innerHTML = html;
      })
      .catch(err => console.error('Error al cargar las sedes:', err));
  });
});
