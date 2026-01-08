function getNombreTitulacion(num) {
	var titulacion = parseInt(num);
	switch (titulacion) {
		case 1:
			return "Licenciaturas";
		case 2:
			return "Ingenierías";
		case 3:
			return "Terciarios";
		case 4:
			return "Tecnicaturas";
		case 5:
			return "Maestrías";
		case 6:
			return "Doctorados";
		default:
			return "-";
	}
}

// --- BÚSQUEDA EN INDEX DE CONVOCATORIAS ---
document.addEventListener('DOMContentLoaded', function () {
	const input = document.getElementById('searchBar');
	const ul = document.getElementById('search-results');
	if (!input || !ul) return;

	// Tabla de convocatorias (tbody)
	const tableBody = document.querySelector('.table.custom-table tbody');
	let dataRows = [];
	if (tableBody) {
		// Todas las filas, menos la de paginación
		dataRows = Array.from(tableBody.querySelectorAll('tr')).filter(function (tr) {
			return !tr.classList.contains('paginationTr');
		});
	}

	// Lee si el toggle "Mostrar cerradas" está activo en la URL
	const params = new URLSearchParams(window.location.search);
	const mostrarCerradas = params.get('mostrar_cerradas') === 'true';

	// Quita acentos y pasa a minúsculas (para búsqueda más amigable)
	function stripAccents(str) {
		return (str || '')
			.toString()
			.normalize('NFD')
			.replace(/\p{Diacritic}/gu, '')
			.toLowerCase();
	}

	// --- FILTRO EN TIEMPO REAL SOBRE LA TABLA ---
	function filterConvocatorias() {
		if (!dataRows.length) return;
		const term = stripAccents(input.value.trim());

		dataRows.forEach(function (tr) {
			const tds = tr.getElementsByTagName('td');
			if (tds.length < 6) return;

			// Columnas:
			// 0: Resolución
			// 1: Nombre
			// 2: Fecha de Inicio
			// 3: Fecha de Fin
			// 4: Titulaciones Afectadas
			// 5: Etapa Actual
			const resolucion = stripAccents(tds[0].textContent);
			const nombre = stripAccents(tds[1].textContent);
			const fechaInicio = stripAccents(tds[2].textContent);
			const fechaFin = stripAccents(tds[3].textContent);
			const titulacion = stripAccents(tds[4].textContent);
			const etapa = stripAccents(tds[5].textContent);

			const hayMatch =
				term === '' ||
				resolucion.indexOf(term) !== -1 ||
				nombre.indexOf(term) !== -1 ||
				fechaInicio.indexOf(term) !== -1 ||
				fechaFin.indexOf(term) !== -1 ||
				titulacion.indexOf(term) !== -1 ||
				etapa.indexOf(term) !== -1;

			tr.style.display = hayMatch ? '' : 'none';
		});
	}

	// --- AUTOCOMPLETADO (como ya tenías) ---
	let t = null;
	const debounce = (fn, ms) => (...args) => {
		clearTimeout(t);
		t = setTimeout(() => fn(...args), ms);
	};

	function renderResults(items) {
		ul.innerHTML = '';
		if (!items || items.length === 0) {
			ul.style.display = 'none';
			return;
		}
		items.forEach(it => {
			const li = document.createElement('li');
			li.style.padding = '6px 8px';
			li.style.cursor = 'pointer';
			li.textContent = `${it.resolucion || '-'} — ${it.nombre || '-'}`;
			li.addEventListener('mousedown', function () {
				// Redirige al index con ?q=<texto> para aplicar filtro server-side
				const q = (input.value || '').trim();
				const qs = new URLSearchParams();
				if (q) qs.set('q', q);
				if (mostrarCerradas) qs.set('mostrar_cerradas', 'true');
				window.location.href = `/convocatorias?${qs.toString()}`;
			});
			ul.appendChild(li);
		});
		ul.style.display = 'block';
	}

	const doSearch = debounce(function () {
		const q = (input.value || '').trim();
		if (!q) {
			ul.style.display = 'none';
			ul.innerHTML = '';
			return;
		}
		const qs = new URLSearchParams({ query: q });
		if (mostrarCerradas) qs.set('mostrar_cerradas', 'true');

		fetch(`/convocatorias/buscar?${qs.toString()}`, { headers: { 'Accept': 'application/json' } })
			.then(r => r.ok ? r.json() : Promise.reject())
			.then(data => renderResults(data.convocatorias || []))
			.catch(() => { ul.style.display = 'none'; });
	}, 200);

	// 🔥 Aquí unimos ambas cosas:
	// - Filtrado en vivo en la tabla
	// - Autocompletar con AJAX
	input.addEventListener('input', function () {
		filterConvocatorias();
		doSearch();
	});

	// Enter: aplicar filtro directo en el index (server-side)
	input.addEventListener('keydown', function (e) {
		if (e.key === 'Enter') {
			e.preventDefault();
			const q = (input.value || '').trim();
			const qs = new URLSearchParams();
			if (q) qs.set('q', q);
			if (mostrarCerradas) qs.set('mostrar_cerradas', 'true');
			window.location.href = `/convocatorias?${qs.toString()}`;
		}
	});

	// Cerrar la lista al perder foco
	document.addEventListener('click', function (e) {
		if (!ul.contains(e.target) && e.target !== input) {
			ul.style.display = 'none';
		}
	});

	// Si el input ya viene con algo (por ?q=...), filtramos una vez
	filterConvocatorias();
});
