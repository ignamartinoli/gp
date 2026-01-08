// 🧠 Evita múltiples inicializaciones si Turbo o Rails recarga la vista
if (!window.__siacInitialized) {
  window.__siacInitialized = true;

  document.addEventListener("turbo:load", initSiac);
  document.addEventListener("DOMContentLoaded", initSiac);
}

function initSiac() {
  if (document.body.dataset.siacInit === "1") return;
  document.body.dataset.siacInit = "1";

  console.log("✅ SIAC JS inicializado correctamente");

  // ⚙️ --- A partir de aquí copiá todo tu código tal cual ---
  const camposContainer = document.getElementById("campos");
  const camposAutoevalContainer = document.getElementById("campos-autoeval");
  const botonAgregar = document.getElementById("add_field");
  const botonAgregarAutoeval = document.getElementById("add_field_autoeval");

  if (!camposContainer || !botonAgregar) {
    console.warn("⚠️ No se encontró el contenedor de campos, abortando initSiac");
    return;
  }

    // Funciones para actualizar los números de los campos
    function actualizarNumerosCampos() {
    document.querySelectorAll(".nested-fields").forEach((field, index) => {
      field.dataset.index = index; // Puedes usar index+1 para mostrar numeración amigable
      const campoIndexElement = field.querySelector(".campo-index");
      if (campoIndexElement) {
        campoIndexElement.textContent = index + 1;
      }

      // Mostrar/Ocultar botón de eliminar
      const botonEliminar = field.querySelector(".remove_fields");
      if (botonEliminar) {
        botonEliminar.style.display = (index === 0) ? "none" : "inline";
      }

      // Vincular eventos a nuevos checkboxes
      const checkboxPreguntaOrientadora = field.querySelector(".checkbox_pregunta_orientadora");
      if (checkboxPreguntaOrientadora) {
        checkboxPreguntaOrientadora.addEventListener("change", togglePreguntaOrientadora);
      }
    });
  }

    function actualizarNumerosCamposAutoeval() {
    document.querySelectorAll(".nested-fields-autoeval").forEach((field, index) => {
      field.dataset.index = index; // Puedes usar index+1 para mostrar numeración amigable
      const campoIndexElement = field.querySelector(".campo-index");
      if (campoIndexElement) {
        campoIndexElement.textContent = index + 1;
      }

      // Mostrar/Ocultar botón de eliminar
      const botonEliminar = field.querySelector(".remove_fields");
      if (botonEliminar) {
        botonEliminar.style.display = (index === 0) ? "none" : "inline";
      }

      // Vincular eventos a nuevos checkboxes
      const checkboxPreguntaOrientadora = field.querySelector(".checkbox_pregunta_orientadora");
      if (checkboxPreguntaOrientadora) {
        checkboxPreguntaOrientadora.addEventListener("change", togglePreguntaOrientadoraAutoeval);
      }
    });
  }

  function actualizarNumerosSubcampos() {
    document.querySelectorAll(".subcampos-container").forEach(container => {
      // 🔹 Selecciona solo los visibles (no ocultos con display:none)
      const fieldsets = Array.from(container.querySelectorAll(".fs-subcampo"))
        .filter(fs => fs.style.display !== "none");

      fieldsets.forEach((fs, index) => {
        const legend = fs.querySelector("legend");
        if (legend) legend.textContent = `Subcampo ${index + 1}`;
      });
    });
  }


  


    // Funciones para controlar el estado del checkbox
    function togglePreguntaOrientadora() {
    // Aquí seleccionamos el contenedor del campo 'pregunta_orientadora_container' 
    const container = $(this).closest(".nested-fields").find(".pregunta_orientadora_container");
    if ($(this).prop('checked')) {
      container.show();  // Mostrar el div si el checkbox está marcado
    } else {
      container.hide();  // Ocultar el div si el checkbox está desmarcado
    }
  }


    function togglePreguntaOrientadoraAutoeval() {
    // Aquí seleccionamos el contenedor del campo 'pregunta_orientadora_container' 
    const container = $(this).closest(".nested-fields-autoeval").find(".pregunta_orientadora_container");
    if ($(this).prop('checked')) {
      container.show();  // Mostrar el div si el checkbox está marcado
    } else {
      container.hide();  // Ocultar el div si el checkbox está desmarcado
    }
  }

  document.addEventListener("change", function(e) {
    if (e.target.classList.contains("checkbox_pregunta_orientadora_subcampo")) {
      const cont = e.target.closest(".subcampo, .fs-subcampo")
        .querySelector(".pregunta_orientadora_container_subcampo");
      cont.style.display = e.target.checked ? "block" : "none";
    }
  });


  // 🔧 Evita que se monten dos veces los listeners de agregar campo
  if (botonAgregar) {
    const nuevoBotonAgregar = botonAgregar.cloneNode(true);
    botonAgregar.parentNode.replaceChild(nuevoBotonAgregar, botonAgregar);

    nuevoBotonAgregar.addEventListener("click", function (e) {
      e.preventDefault();
      e.stopPropagation();
      console.log("🟢 Click en agregar campo (convocatoria)");

      // 🧠 Tomamos TODOS los campos (convocatoria + autoeval) para índice global
      const allFields = document.querySelectorAll(".nested-fields, .nested-fields-autoeval");
      if (allFields.length === 0) return;

      const lastField = document.querySelectorAll(".nested-fields");
      const newField = lastField[lastField.length - 1].cloneNode(true);
      const newIndex = allFields.length; // ✅ índice global único
      console.log("Nuevo índice global (convocatoria):", newIndex);

      limpiarErroresDeCampo(newField);


      newField.dataset.index = newIndex;
      const campoIndexElement = newField.querySelector(".campo-index");
      if (campoIndexElement) campoIndexElement.textContent = newIndex + 1;

      newField.querySelectorAll("input, textarea, select").forEach(input => {
        if (input.name) input.name = input.name.replace(/\[\d+\]/, `[${newIndex}]`);
        if (input.id) input.id = input.id.replace(/_\d+$/, `_${newIndex}`);

        // ⚠️ No limpiar los hidden que acompañan checkboxes (evita borrar el value="0")
        // ❌ No tocar hidden de checkboxes

        if (input.name.includes("opciones_campos_attributes")) {
          const cont = input.closest('.tipo-campo-container');
          if (cont) cont.innerHTML = "";
          return;
        }

        if (
          input.type === "hidden" &&
          newField.querySelector(`input[type="checkbox"][name="${input.name}"]`)
        ) {
          return;
        }

        if (input.type === "checkbox") {
          input.checked = false;
        } else if (input.tagName === "SELECT") {
          input.selectedIndex = 0;
        } else {
          input.value = "";
        }
      });
      
      // ✅ Asegurar que cada checkbox tenga su hidden "0"
      newField.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
        const name = checkbox.name;
        const hasHidden = newField.querySelector(`input[type="hidden"][name="${name}"]`);

        if (!hasHidden) {
          const hidden = document.createElement("input");
          hidden.type = "hidden";
          hidden.name = name;
          hidden.value = "0";
          checkbox.parentNode.insertBefore(hidden, checkbox);
        }
      });

      // 🔒 FIX CRÍTICO: normalizar hidden vacíos de checkboxes clonados
      newField.querySelectorAll('input[type="hidden"]').forEach(hidden => {
        const checkbox = newField.querySelector(
          `input[type="checkbox"][name="${hidden.name}"]`
        );

        if (checkbox && (hidden.value === "" || hidden.value === null)) {
          hidden.value = "0";
        }
      });



      // Limpieza de contenedores dinámicos
      newField.querySelectorAll(".tipo-campo-container, .subcampos-container").forEach(c => (c.innerHTML = ""));

      // Limpieza de errores
      const errorContenedor = newField.querySelector(".errorCampo");
      if (errorContenedor) {
        errorContenedor.innerHTML = "";
        errorContenedor.classList.remove("error");
      }

      // 🟢 Forzar autoevaluacion = 0 para convocatoria
      const hiddenAutoeval = newField.querySelector('input[name*="[autoevaluacion]"]');
      if (hiddenAutoeval) hiddenAutoeval.value = 0;

      camposContainer.appendChild(newField);
      actualizarNumerosCampos();
      actualizarNumerosCamposAutoeval();

      const check = newField.querySelector(".checkbox_pregunta_orientadora");
      if (check) togglePreguntaOrientadora.call(check);
    });
  }

  if (botonAgregarAutoeval) {
    const nuevoBotonAgregarAutoeval = botonAgregarAutoeval.cloneNode(true);
    botonAgregarAutoeval.parentNode.replaceChild(nuevoBotonAgregarAutoeval, botonAgregarAutoeval);

    nuevoBotonAgregarAutoeval.addEventListener("click", function (e) {
    e.preventDefault();
    e.stopPropagation();
    console.log("🟢 Click en agregar campo (autoevaluación)");

    // 🧠 Tomamos TODOS los campos (convocatoria + autoeval) para índice global
    const allFields = document.querySelectorAll(".nested-fields, .nested-fields-autoeval");
    if (allFields.length === 0) return;

    const lastField = document.querySelectorAll(".nested-fields-autoeval");
    const newField = lastField[lastField.length - 1].cloneNode(true);
    const newIndex = allFields.length; // ✅ índice global único
    console.log("Nuevo índice global (autoevaluación):", newIndex);

    limpiarErroresDeCampo(newField);

      newField.dataset.index = newIndex;
      const campoIndexElement = newField.querySelector(".campo-index");
      if (campoIndexElement) campoIndexElement.textContent = newIndex + 1;

      newField.querySelectorAll("input, textarea, select").forEach(input => {
        if (input.name) input.name = input.name.replace(/\[\d+\]/, `[${newIndex}]`);
        if (input.id) input.id = input.id.replace(/_\d+$/, `_${newIndex}`);

        // ⚠️ No limpiar los hidden que acompañan checkboxes (evita borrar el value="0")
        // ❌ No tocar hidden de checkboxes
        if (input.name.includes("opciones_campos_attributes")) {
          const cont = input.closest('.tipo-campo-container');
          if (cont) cont.innerHTML = "";
          return;
        }


        if (
          input.type === "hidden" &&
          newField.querySelector(`input[type="checkbox"][name="${input.name}"]`)
        ) {
          return;
        }


        if (input.type === "checkbox") {
          input.checked = false;
        } else if (input.tagName === "SELECT") {
          input.selectedIndex = 0;
        } else {
          input.value = "";
        }
      });
      
      // ✅ Asegurar que cada checkbox tenga su hidden "0"
      newField.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
        const name = checkbox.name;
        const hasHidden = newField.querySelector(`input[type="hidden"][name="${name}"]`);

        if (!hasHidden) {
          const hidden = document.createElement("input");
          hidden.type = "hidden";
          hidden.name = name;
          hidden.value = "0";
          checkbox.parentNode.insertBefore(hidden, checkbox);
        }
      });

      // 🔒 FIX CRÍTICO: normalizar hidden vacíos de checkboxes clonados
      newField.querySelectorAll('input[type="hidden"]').forEach(hidden => {
        const checkbox = newField.querySelector(
          `input[type="checkbox"][name="${hidden.name}"]`
        );

        if (checkbox && (hidden.value === "" || hidden.value === null)) {
          hidden.value = "0";
        }
      });

      newField.querySelectorAll(".tipo-campo-container, .subcampos-container").forEach(c => (c.innerHTML = ""));

      const errorContenedor = newField.querySelector(".errorCampo");
      if (errorContenedor) {
        errorContenedor.innerHTML = "";
        errorContenedor.classList.remove("error");
      }

      // 🟢 Forzar autoevaluacion = 1 para autoevaluación
      const hiddenAutoeval = newField.querySelector('input[name*="[autoevaluacion]"]');
      if (hiddenAutoeval) hiddenAutoeval.value = 1;

      camposAutoevalContainer.appendChild(newField);
      actualizarNumerosCampos();
      actualizarNumerosCamposAutoeval();

      const check = newField.querySelector(".checkbox_pregunta_orientadora");
      if (check) togglePreguntaOrientadoraAutoeval.call(check);
    });
  }


  function getRealCampoIndex(campoEl) {
    // Busca el PRIMER input/select/textarea cuyo name contenga [campos_attributes][X]
    const any = campoEl.querySelector('[name*="componente[campos_attributes]"]');
    if (!any || !any.name) return null;
    const m = any.name.match(/\[campos_attributes\]\[(\d+)\]/);
    return m ? parseInt(m[1], 10) : null;
  }

  function generarSubcampo(e) {
    e.preventDefault();
    e.stopPropagation();   

    //const campoContainer = e.target.closest('.nested-fields, .nested-fields-autoeval');
    const campoContainer = e.target.closest('.nested-fields, .nested-fields-autoeval');
    if (!campoContainer) return;

    let subcamposContainer = campoContainer.querySelector('.subcampos-container');
    if (!subcamposContainer) {
      subcamposContainer = document.createElement('div');
      subcamposContainer.classList.add('subcampos-container');
      campoContainer.appendChild(subcamposContainer);
    }

    //const campoIndex = campoContainer.dataset.index;
    const campoIndex = getRealCampoIndex(campoContainer); // ⬅️ índice real

    // ✅ Contar tanto los fieldsets existentes (.fs-subcampo) como los nuevos (.subcampo)
    const existentes = subcamposContainer.querySelectorAll('.fs-subcampo, .subcampo').length;
    const subcampoIndex = existentes; // el próximo índice libre

    const nuevoSubcampo = document.createElement('div');
    nuevoSubcampo.classList.add('subcampo');
    nuevoSubcampo.innerHTML = `
      <fieldset class="fs-subcampo">
        <legend>Subcampo ${subcampoIndex + 1}</legend>

        <div class="long-field-4">
          <div class="lf4c1"><label>Pregunta del Subcampo:</label></div>
           <div class="lf4c2">
            <span class="tooltip">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2"/>
              </svg>
              <span class="tooltiptext">Pregunta tal cual figurara en el formulario.</span>
            </span>
            </div>
          <div class="lf4c3">
            <input type="text"
              name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][pregunta]"
              class="inputPreguntaSubcampo">
          </div>
          <div class="lf4c4 errorPreguntaSubcampo errorSubcampo"></div>
        </div>

        <div class="long-field-2">
          <div class="lf2c1"><label>¿Es obligatorio?</label></div>
          <div class="lf2c2">
            <div class="checkboxContainer">
              <input type="hidden"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][obligatorio]"
                value="0">
              <input type="checkbox"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][obligatorio]"
                class="checkbox"
                value="1">
            </div>
          </div>
        </div>

        <div class="long-field-2">
          <div class="lf2c1"><label>¿Tiene pregunta orientadora?</label></div>
          <div class="lf2c2">
            <div class="checkboxContainer">
              <input type="hidden"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][tiene_pregunta_orientadora]"
                value="0">
              <input type="checkbox"
                class="checkbox checkbox_pregunta_orientadora_subcampo"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][tiene_pregunta_orientadora]"
                value="1">
            </div>
          </div>
        </div>

        <div class="long-field-4 pregunta_orientadora_container_subcampo" style="display:none">
          <div class="lf4c1"><label>Pregunta orientadora:</label></div>
          <div class="lf4c3">
            <textarea
              name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][descripcion]"
              class="inputDescripcionSubcampo"
              rows="2"></textarea>
          </div>
        </div>

        <div class="long-field-2">
          <div class="lf2c1"><label>¿Permite adjuntar archivos?</label></div>
          <div class="lf2c2">
            <div class="checkboxContainer">
              <input type="hidden"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][permite_adjuntos]"
                value="0">
              <input type="checkbox"
                class="checkbox checkbox_permite_adjuntos_subcampo"
                name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][permite_adjuntos]"
                value="1">
            </div>
          </div>
        </div>

        <div class="long-field-4">
          <div class="lf4c1"><label>Tipo de Campo:</label></div>
          <div class="lf4c2">
            <span class="tooltip">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2"/>
              </svg>
              <span class="tooltiptext">Tipo de campo habilitado para la respuesta a la pregunta</span>
            </span>
          </div>      
          <div class="lf4c3">
            <select
              name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][tipo_campo_id]"
              class="tipo-subcampo">
              <option value="0">Seleccione una opción</option>
              <option value="7">Campo de Texto (2000 Caracteres)</option>
              <option value="8">Selección Única</option>
              <option value="9">Selección Múltiple</option>
              <option value="10">Campo Fecha</option>
              <option value="11">Campo Número</option>
            </select>
            <input type="hidden"
              name="componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][_destroy]"
              value="false">
          </div>
          <div class="lf4c4 errorTipoSubcampo errorSubcampo"></div>
        </div>

        <div class="tipo-subcampo-container"></div>

        <div class="buttonera-1-c">
          <button class="remove_subfields siac_button">Eliminar Subcampo</button>
        </div>

      </fieldset>
    `;



    subcamposContainer.appendChild(nuevoSubcampo);

    // ✅ Renumerar leyendas luego de agregar
    actualizarNumerosSubcampos();
  }


  // Eventos para eliminar campos y crear subcampos
  camposContainer.addEventListener("click", function(e) {
    if (e.target.classList.contains("remove_fields")) {
      e.preventDefault();
      e.stopPropagation();   
      const allFields = document.querySelectorAll(".nested-fields");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".nested-fields").remove();
        actualizarNumerosCampos();
      }
    }

    if (e.target.classList.contains("add_subfield")) {
      e.preventDefault();
      e.stopPropagation();   
      generarSubcampo(e);
    }

    if (e.target.classList.contains("remove_subfields")) {
      e.preventDefault();
      e.stopPropagation();   

      // 🔹 Buscamos el elemento contenedor del subcampo (puede ser .subcampo o directamente .fs-subcampo)
      const wrapper = e.target.closest(".subcampo, .fs-subcampo");

      if (wrapper) {
        // 🔹 Si el subcampo ya existe en base (tiene input hidden con id o destroy)
        const destroyInput = wrapper.querySelector('input[name*="_destroy"]');
        if (destroyInput) {
          // marcamos para borrar y ocultamos visualmente
          destroyInput.value = "true";
          wrapper.style.display = "none";
        } else {
          // si es un subcampo nuevo en el front, simplemente lo quitamos
          wrapper.remove();
        }

        // 🔹 Siempre renumeramos los subcampos visibles
        actualizarNumerosSubcampos();
      } else {
        console.warn("⚠️ No se encontró el contenedor del subcampo para eliminar.");
      }
    }

  });

  camposAutoevalContainer.addEventListener("click", function(e) {
    if (e.target.classList.contains("remove_fields")) {
      e.preventDefault();
      e.stopPropagation();   
      const allFields = document.querySelectorAll(".nested-fields-autoeval");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".nested-fields-autoeval").remove();
        actualizarNumerosCampos();
      }
    }

    if (e.target.classList.contains("add_subfield")) {
      e.preventDefault();
      e.stopPropagation();   
      generarSubcampo(e);
    }

    if (e.target.classList.contains("remove_subfields")) {
      e.preventDefault();
      e.stopPropagation();   

      // 🔹 Buscamos el elemento contenedor del subcampo (puede ser .subcampo o directamente .fs-subcampo)
      const wrapper = e.target.closest(".subcampo, .fs-subcampo");

      if (wrapper) {
        // 🔹 Si el subcampo ya existe en base (tiene input hidden con id o destroy)
        const destroyInput = wrapper.querySelector('input[name*="_destroy"]');
        if (destroyInput) {
          // marcamos para borrar y ocultamos visualmente
          destroyInput.value = "true";
          wrapper.style.display = "none";
        } else {
          // si es un subcampo nuevo en el front, simplemente lo quitamos
          wrapper.remove();
        }

        // 🔹 Siempre renumeramos los subcampos visibles
        actualizarNumerosSubcampos();
      } else {
        console.warn("⚠️ No se encontró el contenedor del subcampo para eliminar.");
      }
    }

  });


  // Función para modificar la carga segun el tipo de campo seleccionado
  document.addEventListener("change", function (event) {

    function actualizarContenido(select) {
        // Buscar el contenedor de campo subiendo en el DOM
        let campo = select;
        while (campo && !campo.classList.contains("campo")) {
            campo = campo.parentElement; // Subimos en la jerarquía
        }
    
        if (!campo) {
            console.error("No se encontró el contenedor '.campo' para el select", select);
            return; // Salir si no se encuentra el contenedor
        }
    
        const container = campo.querySelector(".tipo-campo-container");
    
        if (!container) {
            console.error("No se encontró el contenedor '.tipo-campo-container' dentro del campo", campo);
            return; // Salir si no se encuentra el div de destino
        }
    
        switch (select.value) {
            case "6": //Combobox
                container.innerHTML = generarCamposComboBox(select);
                break;
            case "7":
                container.innerHTML = `
                <div class="combo-box-container">
                  <div class="long-field-2">
                      <div class="lf2c1"><label>Opciones para el ComboBox:</label></div>
                  </div>
                  <div class="long-field-4">
                      <div class="lf4c1"><label> Opción 1: </label></div>
                      <div class="lf4c2"></div>
                      <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 1"></div>
                      <div class="lf4c4 error-cb-input"> AKA</div>
                  </div>
                  <div class="long-field-4">
                      <div class="lf4c1"><label> Opción 2: </label></div>
                      <div class="lf4c2"></div>
                      <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 2"></div>
                      <div class="lf4c4 error-cb-input"></div>
                  </div>
                  <div class="long-field-2">
                    <div class="lf2c1">
                      <label>Permite ingresar manualmente la respuesta si es otra distinta a las propuestas?</label>
                    </div>
                    <div class="lf2c2">
                      <div class="checkboxContainer">
                        <input type="checkbox" class="checkbox checkbox_permite_otro">
                      </div> 
                    </div>
                  </div>
              </div>
                `;
                break;
            
            case "8": //Seleccion Multiple
                container.innerHTML = generarCamposComboBox(select);
              break;
            case "9": //Seleccion Unica
                container.innerHTML = generarCamposComboBox(select);
                break;
            default: // 1 = Campo de texto
                container.innerHTML = "";
        }
    }

    function actualizarContenidoSubcampo(select) {
      // subir hasta un contenedor válido
      let cont = select.closest(".subcampo") || select.closest(".fs-subcampo");
      if (!cont) {
        // nada que hacer si ese select no pertenece a un subcampo
        return;
      }

      // asegurar el contenedor dinámico
      let container = cont.querySelector(".tipo-subcampo-container");
      if (!container) {
        container = document.createElement("div");
        container.className = "tipo-subcampo-container";
        cont.appendChild(container);
      }

      switch (select.value) {
        case "9":   // selección múltiple
          container.innerHTML = generarCamposComboBox(select);
          break;
        case "8":   // selección única
          container.innerHTML = generarCamposComboBox(select);
          break;
        case "6":   // combobox
          container.innerHTML = generarCamposComboBox(select);
          break;
        default:
          container.innerHTML = "";
      }
    }


    if (event.target.classList.contains("tipo-campo")) {
        actualizarContenido(event.target);
    }

    if (event.target.classList.contains("tipo-subcampo")) {
        actualizarContenidoSubcampo(event.target);
    }

    // Función que genera los campos por defecto y el botón de agregar
    function generarCamposComboBox(select) {
      let nameBase = "";
      const campo = select.closest(".nested-fields, .nested-fields-autoeval");
      const subcampo = select.closest(".subcampo, .fs-subcampo");

      if (subcampo) {
          const campoIndex = getRealCampoIndex(campo);
          const subcampoIndex = Array.from(
          subcampo.parentElement.querySelectorAll(".subcampo, .fs-subcampo")
        ).indexOf(subcampo);
        nameBase = `componente[campos_attributes][${campoIndex}][subcampos_attributes][${subcampoIndex}][opciones_campos_attributes]`;
      } else if (campo) {
        const campoIndex = getRealCampoIndex(campo);
        nameBase = `componente[campos_attributes][${campoIndex}][opciones_campos_attributes]`;
      }

      return `
        <div class="combo-box-container">
          <div class="long-field-2"><div class="lf2c1"><label>Opciones:</label></div></div>
          <div class="opciones-dinamicas">
            ${generarOpcionHTML(nameBase, 0, "", "")}
            ${generarOpcionHTML(nameBase, 1, "", "")}
          </div>
          <div class="long-field-2">
            <div class="lf2c1"><button type="button" class="agregar-opcion siac_button">Agregar opción</button></div>
          </div>
        </div>
      `;
    }


});

  function agregarOpcion(boton) {
    const comboContainer = boton.closest(".combo-box-container");
    if (!comboContainer) return;

    const contenedor = comboContainer.querySelector(".opciones-dinamicas");
    if (!contenedor) return;

    // Detectar la base del name usando la primera opción como referencia
    const primeraOpcion = contenedor.querySelector("input[name*='[opcion]']");
    const baseName = primeraOpcion
      ? primeraOpcion.name.replace(/\[\d+\]\[opcion\]/, "")
      : "";

    const cantidadOpciones = contenedor.querySelectorAll(".long-field-4").length;
    const nuevoNumero = cantidadOpciones + 1;

    const nuevaOpcion = document.createElement("div");
    nuevaOpcion.classList.add("long-field-4");
    nuevaOpcion.innerHTML = `
      <div class="lf4c1"><label> Opción ${nuevoNumero}: </label></div>
      <div class="lf4c2"><button type="button" class="eliminar-opcion siac_button">❌</button></div>
      <div class="lf4c3">
        <input type="text" name="${baseName}[${cantidadOpciones}][opcion]" class="cb-input" placeholder="Opción ${nuevoNumero}">
        <input type="hidden" name="${baseName}[${cantidadOpciones}][valor]" value="${nuevoNumero}">
      </div>
    `;

    contenedor.appendChild(nuevaOpcion);
  }

  
  function eliminarOpcion(boton) {
    const opcionRow = boton.closest(".long-field-4");
    if (!opcionRow) return;

    const contenedor = opcionRow.closest(".opciones-dinamicas");
    if (!contenedor) return;

    let destroyInput = opcionRow.querySelector('input[name$="[_destroy]"]');
    const idInput = opcionRow.querySelector('input[name$="[id]"]');

    if (idInput && idInput.value) {
      // Ya existe en BD → marcar para borrar
      if (!destroyInput) {
        destroyInput = document.createElement("input");
        destroyInput.type = "hidden";
        destroyInput.name = idInput.name.replace(/\[id\]$/, "[_destroy]");
        opcionRow.appendChild(destroyInput);
      }
      destroyInput.value = "1";
      opcionRow.style.display = "none";
    } else {
      // Nueva (no guardada todavía) → eliminar del DOM
      opcionRow.remove();
    }

    renumerarOpciones(contenedor);
  }



  function renumerarOpciones(contenedor) {
    // Tomamos solo las opciones visibles
    const opciones = Array.from(contenedor.querySelectorAll(".long-field-4"))
      .filter(r => r.style.display !== "none");

    opciones.forEach((opcion, index) => {
      const nuevoNumero = index + 1;
      const label = opcion.querySelector(".lf4c1 label");
      const inputOpcion = opcion.querySelector('.lf4c3 input[name$="[opcion]"]');
      const inputValor = opcion.querySelector('.lf4c3 input[name$="[valor]"]');

      // ✅ Actualizamos solo los textos visuales, no los valores de los inputs
      if (label) label.textContent = ` Opción ${nuevoNumero}: `;
      if (inputOpcion && !inputOpcion.value.trim()) {
        inputOpcion.placeholder = `Opción ${nuevoNumero}`;
      }
      if (inputValor && !inputValor.value.trim()) {
        inputValor.value = `${nuevoNumero}`;
      }
    });
  }

  

  document.addEventListener("click", function(event) {
    // Si el botón presionado es "Agregar opción"
    if (event.target.classList.contains("agregar-opcion")) {
        event.preventDefault(); // Evita comportamientos extraños
        event.stopImmediatePropagation(); // Asegura que solo se ejecuta una vez
        agregarOpcion(event.target);
    }

    // Si el botón presionado es "Eliminar opción"
    if (event.target.classList.contains("eliminar-opcion")) {
        eliminarOpcion(event.target);
    }
  }); 

  // 🧠 Al cargar la página, aseguramos que todos los subcampos existentes tengan contenedor dinámico
  document.querySelectorAll(".subcampo, .fs-subcampo").forEach(sub => {
    if (!sub.querySelector(".tipo-subcampo-container")) {
      const contenedor = document.createElement("div");
      contenedor.classList.add("tipo-subcampo-container");
      sub.appendChild(contenedor);
    }
  });

  // 🪄 Generar dinámicamente las opciones complementarias para subcampos ya existentes
  document.querySelectorAll(".subcampo select.tipo-subcampo, .fs-subcampo select.tipo-subcampo").forEach(select => {
    if (["8", "9", "6"].includes(select.value)) {
      const event = new Event("change");
      select.dispatchEvent(event);
    }
  });



  document.querySelectorAll(".opciones-existentes").forEach((container) => {
    // ⚠️ Si ya existen inputs de opciones_campos, NO recrear
    const yaTieneInputs = container.querySelector(
      'input[name*="opciones_campos_attributes"]'
    );

    if (yaTieneInputs) {
      console.log("⛔ Evitado: opciones existentes ya renderizadas por Rails.");
      return;
    }

    const opciones = JSON.parse(container.dataset.opciones || "[]");
    const campoIndex = container.dataset.campoIndex;
    const nameBase = `componente[campos_attributes][${campoIndex}][opciones_campos_attributes]`;

    if (opciones.length > 0) {
      const opcionesHTML = opciones
        .map((op, i) => generarOpcionHTML(nameBase, i, op.opcion, op.valor, op.id))
        .join("");
      container.innerHTML = generarComboBoxHTML(nameBase, opcionesHTML);
    }
  });




  // Llamar a la función al inicio
  actualizarNumerosCampos();
  actualizarNumerosCamposAutoeval();

  // Para opciones existentes (desde la DB) pasa el opcionId
  function generarOpcionHTML(nameBase, index, opcionValue = "", valorValue = "", opcionId = null) {
    return `
      <div class="long-field-4">
        <div class="lf4c1"><label>Opción ${index + 1}:</label></div>
        <div class="lf4c2">
          <button type="button" class="eliminar-opcion siac_button">❌</button>
        </div>
        <div class="lf4c3">
          ${opcionId ? `<input type="hidden" name="${nameBase}[${index}][id]" value="${opcionId}">` : ""}
          <input type="text"  name="${nameBase}[${index}][opcion]" value="${opcionValue}" class="cb-input" placeholder="Opción ${index + 1}">
          <input type="hidden" name="${nameBase}[${index}][valor]"  value="${valorValue || index + 1}">
          <input type="hidden" name="${nameBase}[${index}][_destroy]" value="0">
        </div>
        <div class="lf4c4 error-cb-input"></div>
      </div>
    `;
  }




  function generarComboBoxHTML(nameBase, opcionesHTML) {
    return `
      <div class="combo-box-container">
        <div class="long-field-2">
          <div class="lf2c1"><label>Opciones:</label></div>
        </div>

        <div class="opciones-dinamicas">
          ${opcionesHTML}
        </div>

        <div class="long-field-2">
          <div class="lf2c1">
            <button type="button" class="agregar-opcion siac_button">Agregar opción</button>
          </div>
        </div>

        <div class="long-field-2">
          <div class="lf2c1">
            <label>¿Permite ingresar manualmente otra respuesta?</label>
          </div>
          <div class="lf2c2">
            <div class="checkboxContainer">
              <input type="checkbox" class="checkbox checkbox_permite_otro">
            </div>
          </div>
        </div>
      </div>
    `;
  }

  function limpiarErroresDeCampo(field) {
    if (!field) return;

    // Remueve mensajes de error
    field.querySelectorAll(".error-message").forEach(e => e.remove());

    // Limpia contenedores de error
    field.querySelectorAll(`
      .errorNombre,
      .errorDescripcion,
      .errorDimension,
      .errorPreguntaCampo,
      .errorPreguntaOrientadora,
      .errorTipoCampo,
      .errorSubcampo,
      .error-cb-input
    `).forEach(c => c.innerHTML = "");
  }


  document.querySelectorAll(".checkbox_pregunta_orientadora").forEach(ch => {
    if (ch.checked) togglePreguntaOrientadora.call(ch);
  });
  

}


