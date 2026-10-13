(function () {
  "use strict";

  var shots = {
    "01": { title: "Đọc to số tiền", webp: "assets/images/1c4dffe8-47b5-4db7-9f23-85eb3cf388ac.png", png: "assets/images/1c4dffe8-47b5-4db7-9f23-85eb3cf388ac.png" },
    "02": { title: "Chế độ bán hàng", webp: "assets/images/4ec0cf8e-2001-49f5-bea9-e0edd5cc5615.png", png: "assets/images/4ec0cf8e-2001-49f5-bea9-e0edd5cc5615.png" },
    "03": { title: "Thống kê giao dịch", webp: "assets/images/581d3195-5bab-47e4-93b0-5b4df35fa8c8.png", png: "assets/images/581d3195-5bab-47e4-93b0-5b4df35fa8c8.png" },
    "04": { title: "Tính năng giải trí", webp: "assets/images/2a9a34c5-09d1-482a-97e1-1ecc6c4cd1e4.png", png: "assets/images/2a9a34c5-09d1-482a-97e1-1ecc6c4cd1e4.png" },
    "05": { title: "Kiếm tiền giới thiệu", webp: "assets/images/25706eba-2d8c-47ea-ab29-4612607b64b7.png", png: "assets/images/25706eba-2d8c-47ea-ab29-4612607b64b7.png" },
    "06": { title: "Video hướng dẫn", webp: "assets/images/ed22a994-3e29-47d4-a07d-5ee499dbbe7c.png", png: "assets/images/ed22a994-3e29-47d4-a07d-5ee499dbbe7c.png" },
    "07": { title: "Hỗ trợ 24/7", webp: "assets/images/6c5bfa32-58eb-490d-8fbb-3f3df031caa2.png", png: "assets/images/6c5bfa32-58eb-490d-8fbb-3f3df031caa2.png" },
    "08": { title: "Báo chuyển tiền bằng giọng nói", webp: "assets/images/8457c58b-abb8-43df-ba18-aedc1a1b18b1.png", png: "assets/images/8457c58b-abb8-43df-ba18-aedc1a1b18b1.png" },
  };

  function init() {
    var modal = document.getElementById("seo-hero-lightbox");
    var img = document.getElementById("seo-hero-lightbox-img");
    var caption = document.getElementById("seo-hero-lightbox-caption");
    var closeBtn = document.getElementById("seo-hero-lightbox-close");
    var backdrop = document.getElementById("seo-hero-lightbox-backdrop");

    if (!modal || !img) return;

    var lastFocus = null;

    function openLightbox(shotId) {
      var shot = shots[shotId];
      if (!shot) return;

      lastFocus = document.activeElement;
      img.onload = null;
      img.onerror = function () {
        img.onerror = null;
        img.src = shot.png;
      };
      img.src = shot.webp;
      img.alt = shot.title + " — ảnh Google Play";
      if (caption) caption.textContent = shot.title;

      modal.classList.add("is-open");
      modal.setAttribute("aria-hidden", "false");
      document.body.classList.add("seo-lightbox-open");
      if (closeBtn) closeBtn.focus();
    }

    function closeLightbox() {
      modal.classList.remove("is-open");
      modal.setAttribute("aria-hidden", "true");
      img.removeAttribute("src");
      document.body.classList.remove("seo-lightbox-open");
      if (lastFocus && lastFocus.focus) lastFocus.focus();
    }

    document.querySelectorAll("[data-hero-shot]").forEach(function (btn) {
      btn.addEventListener("click", function (e) {
        e.preventDefault();
        openLightbox(btn.getAttribute("data-hero-shot"));
      });
    });

    if (closeBtn) closeBtn.addEventListener("click", closeLightbox);
    if (backdrop) backdrop.addEventListener("click", closeLightbox);

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && modal.classList.contains("is-open")) {
        closeLightbox();
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
