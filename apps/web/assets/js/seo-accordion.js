/** Lightweight FAQ/feature accordion — replaces Bootstrap collapse JS. */
(function () {
  "use strict";

  function togglePanel(btn) {
    var targetSel = btn.getAttribute("data-bs-target");
    if (!targetSel) return;
    var panel = document.querySelector(targetSel);
    if (!panel) return;

    var accordion = btn.closest(".accordion");
    var willOpen = !panel.classList.contains("show");

    if (accordion && willOpen) {
      accordion.querySelectorAll(".collapse.show").forEach(function (openPanel) {
        if (openPanel === panel) return;
        openPanel.classList.remove("show");
        var otherBtn = accordion.querySelector('[data-bs-target="#' + openPanel.id + '"]');
        if (otherBtn) {
          otherBtn.classList.add("collapsed");
          otherBtn.setAttribute("aria-expanded", "false");
        }
      });
    }

    panel.classList.toggle("show", willOpen);
    btn.classList.toggle("collapsed", !willOpen);
    btn.setAttribute("aria-expanded", willOpen ? "true" : "false");
  }

  document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(function (btn) {
    btn.addEventListener("click", function (e) {
      e.preventDefault();
      togglePanel(btn);
    });
  });
})();
