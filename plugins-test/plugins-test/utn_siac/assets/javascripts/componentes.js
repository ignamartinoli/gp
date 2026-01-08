document.addEventListener("DOMContentLoaded", function() {
  const camposContainer = document.getElementById("campos");
  const camposAutoevalContainer = document.getElementById("campos-autoeval");
  const botonAgregar = document.getElementById("add_field");
  const botonAgregarAutoeval = document.getElementById("add_field_autoeval");

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
    // Recorremos cada contenedor de subcampos
    document.querySelectorAll(".subcampos-container").forEach((subcamposContainer) => {
      const subcampos = subcamposContainer.querySelectorAll(".subcampo");
  
      subcampos.forEach((subcampo, index) => {
        // Buscar el legend dentro del fieldset del subcampo
        const legend = subcampo.querySelector("fieldset > legend");
        if (legend) {
          legend.textContent = `Subcampo ${index + 1}`;
        }
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

  // Eventos para agregar nuevos campos
  botonAgregar.addEventListener("click", function(e) {
    e.preventDefault();

    // Obtener todos los campos actuales
    const allFields = document.querySelectorAll(".nested-fields");
    if (allFields.length === 0) {
      console.log("No hay campos para clonar.");
      return;
    }

    // Clonar el último campo
    const lastField = allFields[allFields.length - 1];
    const newField = lastField.cloneNode(true);

    // Nuevo índice será el tamaño actual de la colección
    const newIndex = allFields.length;
    newField.dataset.index = newIndex;

    // Actualizar el texto del número del campo
    const campoIndexElement = newField.querySelector(".campo-index");
    if (campoIndexElement) {
      campoIndexElement.textContent = newIndex + 1;
    }

    // Actualizar atributos name, id y limpiar valores en el nuevo campo
    newField.querySelectorAll("input, textarea, select").forEach(input => {
      if (input.name) {
        // Reemplaza el número entre corchetes por el nuevo índice.
        input.name = input.name.replace(/\[\d+\]/, `[${newIndex}]`);
      }
      if (input.id) {
        // Si el id termina en _<número>, actualízalo también.
        input.id = input.id.replace(/_\d+$/, `_${newIndex}`);
      }
      // Limpiar el valor del input
      input.value = "";
      // Si es checkbox, desmarcarlo
      if (input.type === "checkbox") {
        input.checked = false;
      }

      if (input.tagName === "SELECT") {
            input.selectedIndex = 0; // Reiniciar a la opción por defecto
        } else {
            input.value = "";
        }
    });

    // Vaciar el contenido del div .tipo-campo-container
    const tipoCampoContainer = newField.querySelector(".tipo-campo-container");
    if (tipoCampoContainer) {
        tipoCampoContainer.innerHTML = ""; // Vacía el contenido
    }

    // Vaciar el contenido del div .subcampos-container
    const subCamposContainer = newField.querySelector(".subcampos-container");
    if (subCamposContainer) {
        subCamposContainer.innerHTML = ""; // Vacía el contenido
    }

    // Limpiar los errores asociados con el nuevo campo
    const errorContenedor = newField.querySelector('.errorCampo');
    if (errorContenedor) {
      errorContenedor.innerHTML = '';
      errorContenedor.classList.remove('error');
    }

    // Agregar el nuevo campo al contenedor
    camposContainer.appendChild(newField);

    // Actualizar la numeración de todos los campos
    actualizarNumerosCampos();
    actualizarNumerosCamposAutoeval();

    // Llamar a la función para asegurarnos que la visibilidad del textarea se ajuste al estado del checkbox en el nuevo campo
    togglePreguntaOrientadora.call(newField.querySelector(".checkbox_pregunta_orientadora"));
  });


  botonAgregarAutoeval.addEventListener("click", function(e) {
    e.preventDefault();

    // Obtener todos los campos actuales
    const allFields = document.querySelectorAll(".nested-fields-autoeval");
    if (allFields.length === 0) {
      console.log("No hay campos para clonar.");
      return;
    }

    // Clonar el último campo
    const lastField = allFields[allFields.length - 1];
    const newField = lastField.cloneNode(true);

    // Nuevo índice será el tamaño actual de la colección
    const newIndex = allFields.length;
    newField.dataset.index = newIndex;

    // Actualizar el texto del número del campo
    const campoIndexElement = newField.querySelector(".campo-index");
    if (campoIndexElement) {
      campoIndexElement.textContent = newIndex + 1;
    }

    // Actualizar atributos name, id y limpiar valores en el nuevo campo
    newField.querySelectorAll("input, textarea, select").forEach(input => {
      if (input.name) {
        // Reemplaza el número entre corchetes por el nuevo índice.
        input.name = input.name.replace(/\[\d+\]/, `[${newIndex}]`);
      }
      if (input.id) {
        // Si el id termina en _<número>, actualízalo también.
        input.id = input.id.replace(/_\d+$/, `_${newIndex}`);
      }
      // Limpiar el valor del input
      input.value = "";
      // Si es checkbox, desmarcarlo
      if (input.type === "checkbox") {
        input.checked = false;
      }

      if (input.tagName === "SELECT") {
            input.selectedIndex = 0; // Reiniciar a la opción por defecto
        } else {
            input.value = "";
        }
    });

    // Vaciar el contenido del div .tipo-campo-container
    const tipoCampoContainer = newField.querySelector(".tipo-campo-container");
    if (tipoCampoContainer) {
        tipoCampoContainer.innerHTML = ""; // Vacía el contenido
    }

    // Vaciar el contenido del div .subcampos-container
    const subCamposContainer = newField.querySelector(".subcampos-container");
    if (subCamposContainer) {
        subCamposContainer.innerHTML = ""; // Vacía el contenido
    }


    // Limpiar los errores asociados con el nuevo campo
    const errorContenedor = newField.querySelector('.errorCampo');
    if (errorContenedor) {
      errorContenedor.innerHTML = '';
      errorContenedor.classList.remove('error');
    }

    // Agregar el nuevo campo al contenedor
    camposAutoevalContainer.appendChild(newField);

    // Actualizar la numeración de todos los campos
    actualizarNumerosCampos();
    actualizarNumerosCamposAutoeval();

    // Llamar a la función para asegurarnos que la visibilidad del textarea se ajuste al estado del checkbox en el nuevo campo
    togglePreguntaOrientadora.call(newField.querySelector(".checkbox_pregunta_orientadora"));
  });


  function generarSubcampo(e) {
    const campoContainer = e.target.closest('.campo');
    const subcamposContainer = campoContainer.querySelector('.subcampos-container');
    const nuevoSubcampo = document.createElement('div');

    const numeroSubcampo = subcamposContainer.querySelectorAll('.subcampo').length + 1;
    
    nuevoSubcampo.classList.add('subcampo');
    nuevoSubcampo.innerHTML = `
      <fieldset class='fs-subcampo'>
        <legend>Subcampo ${numeroSubcampo}</legend>
        <div class="fs-container">
          <div class="long-field-4">
            <div class="lf4c1">
              <label>Pregunta:</label>
            </div>
            <div class="lf4c2">
            <span class="tooltip">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2"/>
              </svg>
              <span class="tooltiptext">Pregunta tal cual figurara en el formulario.</span>
            </span>
            </div>
            <div class="lf4c3">
            <input type="text" class="inputSubcampo">
            </div>
            <div class="lf4c4 errorSubcampo">
            </div>
          </div>
          <div class="long-field-4">
              <div class="lf4c1">
                <label>Tipo de Campo:</label>
              </div>          
              <div class="lf4c2">
                <span class="tooltip">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                    <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2"/>
                  </svg>
                  <span class="tooltiptext">Tipo de campo habilitado para la respuesta a la pregunta</span>
                </span>
              </div>          
              <div class="lf4c3">
                <select class="tipo-subcampo">
                  <option value="0">Seleccione una Opción</option>
                  <option value="1">Texto corto</option>
                  <option value="2">Texto largo (2000 caracteres)</option>
                  <option value="3">Número</option>
                  <option value="4">Dos opciones</option>
                  <option value="5">Dos opciones con Justificación</option>
                  <option value="6">ComboBox</option>
                </select>
              </div>          
              <div class="lf4c4 errorSubcampo">
              </div>          
            </div>
            <div class="tipo-subcampo-container">
            </div>
            <div class="buttonera-1-c">
              <button class="remove_subfields siac_button">Eliminar Subcampo</button>
            </div>
          </div>
      </fieldset>
    `;

    // Lo agrega al contenedor correspondiente
    subcamposContainer.appendChild(nuevoSubcampo);
  }

  // Eventos para eliminar campos y crear subcampos
  camposContainer.addEventListener("click", function(e) {
    if (e.target.classList.contains("remove_fields")) {
      e.preventDefault();
      const allFields = document.querySelectorAll(".nested-fields");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".nested-fields").remove();
        actualizarNumerosCampos();
      }
    }

    if (e.target.classList.contains("add_subfield")) {
      e.preventDefault();
      generarSubcampo(e);
    }

    if (e.target.classList.contains("remove_subfields")) {
      e.preventDefault();
      const allFields = document.querySelectorAll(".subcampos-container");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".subcampo").remove();
        actualizarNumerosSubcampos();
      }
    }
  });

  camposAutoevalContainer.addEventListener("click", function(e) {
    if (e.target.classList.contains("remove_fields")) {
      e.preventDefault();
      const allFields = document.querySelectorAll(".nested-fields-autoeval");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".nested-fields-autoeval").remove();
        actualizarNumerosCampos();
      }
    }

    if (e.target.classList.contains("add_subfield")) {
      e.preventDefault();
      generarSubcampo(e);
    }

    if (e.target.classList.contains("remove_subfields")) {
      e.preventDefault();
      const allFields = document.querySelectorAll(".subcampos-container");
      // Evitar eliminar el primer campo
      if (allFields.length > 1) {
        e.target.closest(".subcampo").remove();
        actualizarNumerosSubcampos();
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
            case "6":
                container.innerHTML = generarCamposComboBox();
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
                      <div class="lf4c4 error-cb-input"></div>
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
            default:
                container.innerHTML = "";
        }
    }

    function actualizarContenidoSubcampo (select) {
      // Buscar el contenedor de campo subiendo en el DOM
      let subcampo = select;
      while (subcampo && !subcampo.classList.contains("subcampo")) {
          subcampo = subcampo.parentElement; // Subimos en la jerarquía
      }
  
      if (!subcampo) {
          console.error("No se encontró el contenedor '.subcampo' para el select", select);
          return; // Salir si no se encuentra el contenedor
      }
  
      const container = subcampo.querySelector(".tipo-subcampo-container");
  
      if (!container) {
          console.error("No se encontró el contenedor '.tipo-subcampo-container' dentro del subcampo", subcampo);
          return; // Salir si no se encuentra el div de destino
      }
  
      switch (select.value) {
          case "6":
              container.innerHTML = generarCamposComboBox();
              break;
          case "5":
              container.innerHTML = `
              <div class="combo-box-container">
                <div class="long-field-2">
                    <div class="lf2c1"><label>Opciones para el ComboBox:</label></div>
                </div>
                <div class="long-field-4">
                    <div class="lf4c1"><label> Opción 1: </label></div>
                    <div class="lf4c2"></div>
                    <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 1"></div>
                    <div class="lf4c4 error-cb-input"></div>
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
          case "4":
              container.innerHTML = `
              <div class="combo-box-container">
                <div class="long-field-2">
                    <div class="lf2c1"><label>Opciones para el ComboBox:</label></div>
                </div>
                <div class="long-field-4">
                    <div class="lf4c1"><label> Opción 1: </label></div>
                    <div class="lf4c2"></div>
                    <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 1"></div>
                    <div class="lf4c4 error-cb-input"></div>
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
    function generarCamposComboBox() {
        return `
            <div class="combo-box-container">
                <div class="long-field-2">
                    <div class="lf2c1"><label>Opciones para el ComboBox:</label></div>
                </div>
                <div class="long-field-4">
                    <div class="lf4c1"><label> Opción 1: </label></div>
                    <div class="lf4c2"></div>
                    <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 1"></div>
                    <div class="lf4c4 error-cb-input"></div>
                  </div>
                <div class="long-field-4">
                    <div class="lf4c1"><label> Opción 2: </label></div>
                    <div class="lf4c2"></div>
                    <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción 2"></div>
                    <div class="lf4c4 error-cb-input"></div>
                </div>
                <div class="opciones-dinamicas"></div>
                <div class="long-field-2">
                    <div class="lf2c1">
                        <button type="button" class="agregar-opcion siac_button">Agregar opción</button>
                    </div>
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
    
    function agregarOpcion(boton) {
        // Buscar el contenedor más cercano al botón
        const comboContainer = boton.closest(".combo-box-container");
        if (!comboContainer) return;
    
        // Buscar el div donde se agregan las opciones dinámicas
        const contenedor = comboContainer.querySelector(".opciones-dinamicas");
        if (!contenedor) return;
    
        // Verificar si esta función ya se ejecutó para evitar dobles inserciones
        if (boton.dataset.clicked === "true") return;
        boton.dataset.clicked = "true"; // Marcar como ejecutado para evitar doble ejecución
    
        setTimeout(() => { boton.dataset.clicked = "false"; }, 100); // Resetea el flag después de un breve tiempo
    
        // Contar cuántas opciones hay para numerarlas correctamente
        const cantidadOpciones = contenedor.querySelectorAll(".long-field-4").length;
        const nuevoNumero = cantidadOpciones + 3; // Comienza en Opción 3
    
        // Crear la nueva opción con su número correspondiente
        const nuevaOpcion = document.createElement("div");
        nuevaOpcion.classList.add("long-field-4");
        nuevaOpcion.innerHTML = `
            <div class="lf4c1"><label> Opción ${nuevoNumero}: </label></div>
            <div class="lf4c2"><button type="button" class="eliminar-opcion siac_button">❌</button></div>
            <div class="lf4c3"><input type="text" class="cb-input" placeholder="Opción ${nuevoNumero}"></div>
            <div class="lf4c4 error-cb-input"></div>

            `;
    
        // Agregar la nueva opción solo al combo correcto
        contenedor.appendChild(nuevaOpcion);
    }
    
    function eliminarOpcion(boton) {
        const opcion = boton.closest(".long-field-4");
        if (!opcion) return;
    
        // Encontrar el contenedor del combo para renumerar correctamente
        const contenedor = opcion.closest(".opciones-dinamicas");
        if (!contenedor) return;
    
        // Eliminar la opción seleccionada
        opcion.remove();
    
        // Renumerar opciones después de eliminar
        renumerarOpciones(contenedor);
    }

    function renumerarOpciones(contenedor) {
        const opciones = contenedor.querySelectorAll(".long-field-4");
    
        opciones.forEach((opcion, index) => {
            const nuevoNumero = index + 3; // Comienza en Opción 3
            const label = opcion.querySelector(".lf4c1 label");
            const input = opcion.querySelector(".lf4c3 input");
    
            if (label) label.textContent = ` Opción ${nuevoNumero}: `;
            if (input) input.placeholder = `Opción ${nuevoNumero}`;
        });
    }
    

});

    
  
  // Llamar a la función al inicio
  actualizarNumerosCampos();
  actualizarNumerosCamposAutoeval();
});
