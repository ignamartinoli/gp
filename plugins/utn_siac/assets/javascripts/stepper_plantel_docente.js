document.addEventListener('DOMContentLoaded', function () {

  // Buscar todos los modales de docentes (por si hay más de uno)
  document.querySelectorAll('[id^="modal_docente_"]').forEach(function(modal) {

    const steps = modal.querySelectorAll('.step');
    const contents = modal.querySelectorAll('.step-content');
    const btnNext = modal.querySelector('.step-btn.next');
    const btnPrev = modal.querySelector('.step-btn.prev');

    let currentStep = 0;

    function showStep(index) {
      // bounds
      if (index < 0 || index >= contents.length) return;

      // ocultar todos
      steps.forEach(s => s.classList.remove('active'));
      contents.forEach(c => c.classList.remove('active'));

      // activar actual
      steps[index].classList.add('active');
      contents[index].classList.add('active');

      // botones
      btnPrev.style.display = index === 0 ? 'none' : 'inline-block';
      btnNext.textContent = index === contents.length - 1 ? 'Agregar docente' : 'Siguiente';

      currentStep = index;
    }

    // eventos
    btnNext.addEventListener('click', function () {
      if (currentStep < contents.length - 1) {
        showStep(currentStep + 1);
      } else {
        // último paso → submit lógico
        console.log('Agregar docente (hook futuro)');
        // acá después:
        // - validar
        // - cerrar modal
        // - insertar docente en la tabla
      }
    });

    btnPrev.addEventListener('click', function () {
      showStep(currentStep - 1);
    });

    // init
    showStep(0);
  });

});
