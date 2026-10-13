/** Lightweight homepage JS — scroll restore + back-to-top. */
(function () {
  "use strict";

  if (!window.location.hash) {
    if ("scrollRestoration" in history) {
      history.scrollRestoration = "manual";
    }
    function pinTop() {
      window.scrollTo(0, 0);
    }
    pinTop();
    document.addEventListener(
      "DOMContentLoaded",
      function () {
        pinTop();
      },
      { once: true }
    );
    window.addEventListener(
      "pageshow",
      function (e) {
        if (e.persisted) pinTop();
      },
      { passive: true }
    );
  }

  var btn = document.querySelector(".back-to-top");
  if (!btn) return;

  btn.setAttribute("aria-label", "Cuộn lên đầu trang");
  btn.setAttribute("role", "button");
  btn.hidden = true;

  window.addEventListener(
    "scroll",
    function () {
      var show = window.scrollY > 80;
      btn.hidden = !show;
    },
    { passive: true }
  );

  btn.addEventListener("click", function (e) {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  });
})();
