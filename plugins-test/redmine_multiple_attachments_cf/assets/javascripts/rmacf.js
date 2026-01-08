// assets/javascripts/rmacf.js
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".rmacf-input").forEach(function (root) {
    const csv    = root.querySelector('input[type="hidden"][id^="issue_custom_field_values_"]');
    const removed= root.querySelector('input[type="hidden"][id^="rmacf-remove-"]');
    if (!csv || !removed) return;

    root.addEventListener("click", function (ev) {
      if (!ev.target.classList.contains("rmacf-remove")) return;
      const li = ev.target.closest(".rmacf-item--persisted");
      if (!li) return;
      const id = li.dataset.attachmentId;

      // quitar del CSV
      let ids = csv.value.split(",").map(s => s.trim()).filter(Boolean);
      ids = ids.filter(x => x !== id);
      csv.value = ids.join(",");

      // acumular en removed
      let rem = removed.value.split(",").map(s => s.trim()).filter(Boolean);
      if (!rem.includes(id)) rem.push(id);
      removed.value = rem.join(",");

      // feedback visual
      li.classList.add("rmacf-item--to-delete");
      ev.target.remove();
    });
  });

  // Validación de tipos y tope
  document.querySelectorAll(".rmacf-input").forEach(function (root) {
    const drop     = root.querySelector(".rmacf-drop");
    const fileInput= drop && drop.querySelector('input[type="file"]');
    const list     = root.querySelector(".rmacf-list");
    const csv      = root.querySelector('input[type="hidden"][id^="issue_custom_field_values_"]');
    if (!drop || !fileInput || !csv) return;

    const allowed = (drop.dataset.allowed || ".pdf").split(",").map(s => s.trim().toLowerCase());
    const max     = parseInt(drop.dataset.max || "30", 10);

    function extOk(name, type) {
      const lower = (name || "").toLowerCase();
      const okByExt = allowed.some(a => a && lower.endsWith(a));
      if (okByExt) return true;
      const t = (type || "").toLowerCase();
      return (
        t === "application/pdf" ||
        t === "application/msword" ||
        t === "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      );
    }

    fileInput.addEventListener("change", function (ev) {
      const existingCount = list ? list.querySelectorAll("li").length : 0;
      const incoming = Array.from(ev.target.files || []);
      const bad = incoming.filter(f => !extOk(f.name, f.type));
      if (bad.length) {
        alert("Solo se permiten PDF/DOC/DOCX/ZIP/RAR.");
        fileInput.value = "";
        return;
      }
      if (existingCount + incoming.length > max) {
        alert("Podés adjuntar como máximo " + max + " archivos.");
        fileInput.value = "";
        return;
      }
      // Dejá que el submit los envíe; el patch del server se encarga.
    });
  });
});
