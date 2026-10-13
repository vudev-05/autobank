/** Fixed nav: spacer, scroll shadow, active section, mobile sidebar */
(function () {
  var shell = document.getElementById("seo-header");
  var spacer = document.getElementById("seo-header-spacer");
  var toggle = document.getElementById("seo-pillnav-toggle");
  var closeBtn = document.getElementById("seo-pillnav-close");
  var drawer = document.getElementById("seo-pillnav-drawer");
  var backdrop = document.getElementById("seo-pillnav-backdrop");
  var scrollLinks = document.querySelectorAll(
    "#seo-header .seo-pillnav-link.page-scroll, #seo-pillnav-drawer .page-scroll"
  );
  if (!shell) return;

  var navHeight = 72;
  var sectionAnchors = [];
  var scrollRaf = 0;
  var activeHref = null;

  function mountDrawerPortal() {
    if (backdrop && backdrop.parentElement !== document.body) {
      document.body.appendChild(backdrop);
    }
    if (drawer && drawer.parentElement !== document.body) {
      document.body.appendChild(drawer);
    }
  }
  mountDrawerPortal();

  function measureNav() {
    navHeight = shell.offsetHeight || navHeight;
    var extra = window.innerWidth <= 991 ? 0 : 4;
    if (spacer) spacer.style.setProperty("height", (navHeight + extra) + "px", "important");
  }
  measureNav();
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", measureNav);
  }

  function rebuildSections() {
    sectionAnchors = [];
    scrollLinks.forEach(function (a) {
      var id = (a.getAttribute("href") || "").replace(/^#/, "");
      var el = id ? document.getElementById(id) : null;
      if (el) sectionAnchors.push({ href: a.getAttribute("href"), top: el.offsetTop });
    });
    sectionAnchors.sort(function (x, y) {
      return x.top - y.top;
    });
  }

  function setDrawerOpen(open) {
    if (!drawer || !toggle) return;
    shell.classList.toggle("is-drawer-open", open);
    drawer.classList.toggle("is-open", open);
    drawer.setAttribute("aria-hidden", open ? "false" : "true");
    if (open) {
      drawer.removeAttribute("inert");
    } else {
      drawer.setAttribute("inert", "");
    }
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
    toggle.setAttribute("aria-label", open ? "Đóng menu" : "Mở menu");
    document.body.classList.toggle("seo-nav-open", open);
    if (backdrop) {
      backdrop.hidden = !open;
      backdrop.setAttribute("aria-hidden", open ? "false" : "true");
    }
  }

  function closeDrawer() {
    setDrawerOpen(false);
  }

  function openDrawer() {
    setDrawerOpen(true);
  }

  function applyActiveNav(href) {
    if (href === activeHref) return;
    activeHref = href;
    scrollLinks.forEach(function (a) {
      a.classList.toggle("active", href && a.getAttribute("href") === href);
    });
  }

  function onScroll() {
    if (scrollRaf) return;
    scrollRaf = window.requestAnimationFrame(function () {
      scrollRaf = 0;
      shell.classList.toggle("is-scrolled", window.scrollY > 8);
      if (!sectionAnchors.length) return;
      var y = window.scrollY + navHeight + 48;
      var href = null;
      for (var i = 0; i < sectionAnchors.length; i++) {
        if (sectionAnchors[i].top <= y) href = sectionAnchors[i].href;
      }
      applyActiveNav(href);
    });
  }

  if (toggle) {
    toggle.addEventListener("click", function () {
      if (drawer && drawer.classList.contains("is-open")) closeDrawer();
      else openDrawer();
    });
  }
  if (closeBtn) closeBtn.addEventListener("click", closeDrawer);
  if (backdrop) backdrop.addEventListener("click", closeDrawer);

  scrollLinks.forEach(function (a) {
    a.addEventListener("click", function () {
      if (window.matchMedia("(max-width: 991px)").matches) closeDrawer();
    });
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeDrawer();
  });

  function onLayoutChange() {
    measureNav();
    rebuildSections();
    onScroll();
    if (window.matchMedia("(min-width: 992px)").matches) closeDrawer();
  }

  window.addEventListener("resize", onLayoutChange, { passive: true });

  function boot() {
    measureNav();
    rebuildSections();
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    setDrawerOpen(false);
    if (window.ResizeObserver) {
      new ResizeObserver(onLayoutChange).observe(shell);
    }
    window.addEventListener("load", function () {
      rebuildSections();
      onScroll();
    });
  }

  // Mobile Collapsible Footer Accordions
  function initFooterAccordions() {
    document.querySelectorAll(".footer-widget-toggle").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var widget = btn.closest(".footer-accordion-widget");
        if (widget) {
          var isOpen = widget.classList.contains("is-open");
          widget.classList.toggle("is-open", !isOpen);
          btn.setAttribute("aria-expanded", !isOpen ? "true" : "false");
        }
      });
      btn.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          btn.click();
        }
      });
    });
  }

  requestAnimationFrame(function () {
    initFooterAccordions();
    if (window.requestIdleCallback) {
      requestIdleCallback(boot, { timeout: 2200 });
    } else {
      setTimeout(boot, 80);
    }
  });
})();
