// =========================
// BUSCAR DOCENTE POR CUIT
// =========================
function buscarDocentePorCuit(cuit) {
  return fetch(`/siac/docentes/buscar?cuil=${cuit}`)
    .then(r => r.json());
}

// =========================
// CARGAR DATOS DOCENTE
// =========================
function cargarDatosDocente(cuit) {
  return fetch(`/siac/docentes/datos?cuil=${cuit}`)
    .then(r => r.json());
}

// =========================
// CARGAR CATÁLOGOS
// =========================
function cargarCatalogosDocente() {
  return fetch('/siac/docentes/catalogos')
    .then(r => r.json());
}

// =========================
// GUARDAR DOCENTE
// =========================
function guardarDocente(payload) {
  return fetch('/siac/docentes/guardar', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
    },
    body: JSON.stringify(payload)
  }).then(r => r.json());
}

document.addEventListener('change', function (e) {
  if (e.target.id !== 'tipo_rol_select') return;

  const cargoSelect = document.getElementById('cargo_select');
  if (!cargoSelect) return;

  const cargosData = JSON.parse(cargoSelect.dataset.cargos || '{}');
  const tipo = e.target.value;

  cargoSelect.innerHTML = '<option value="">Seleccione cargo</option>';

  if (!tipo || !cargosData[tipo]) return;

  cargosData[tipo].forEach(cargo => {
    const opt = document.createElement('option');
    opt.value = cargo.id_cargo;
    opt.textContent = cargo.nombre;
    cargoSelect.appendChild(opt);
  });
});
