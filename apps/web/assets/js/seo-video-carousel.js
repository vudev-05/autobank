(function () {
  "use strict";

  var PLAYLIST = "PL16vcFDZc8utCkBJbkwmcKJdgsMlmZfla";
  var videos = [
    { id: "_IvoKRSEMWY", title: "Hướng dẫn sử dụng ứng dụng", sub: "Tổng quan cách dùng Báo chuyển tiền bằng giọng nói" },
    { id: "PErb06AsIjM", title: "Hướng dẫn bật thông báo", sub: "Các bước bật quyền nghe thông báo chuyển khoản" },
    { id: "R-A6ZdmbGag", title: "Bật thông báo theo từng hãng máy", sub: "Xiaomi, Samsung, Oppo, Vivo và các dòng máy khác" },
    { id: "G897yLGVhVk", title: "Luôn mở Chế độ bán hàng", sub: "Giúp nhận thông báo ngân hàng nhanh và ổn định hơn" },
    { id: "Bm4GdffAZgM", title: "Hướng dẫn chia sẻ thông báo", sub: "Chia sẻ quyền nghe cho người thân, nhân viên" },
    { id: "GdOjhAuql7k", title: "Nguyên lý hoạt động", sub: "Cách app đọc và phát thông báo chuyển khoản" },
    { id: "6PcptWgXo-A", title: "Lưu ý khi sử dụng", sub: "Những điều cần biết để app chạy ổn định" },
    { id: "Q6rp8lextFY", title: "Hướng dẫn cập nhật hạn sử dụng", sub: "Gia hạn gói và kiểm tra ngày hết hạn" },
  ];

  function applyConfig(cfg) {
    if (!cfg) return;
    var yt = cfg.youtubeLink || cfg.youtubeUrl;
    if (!yt) return;

    var listMatch = yt.match(/[?&]list=([^#&?]+)/);
    if (listMatch && listMatch[1]) {
      PLAYLIST = listMatch[1];
    }

    var vMatch = yt.match(/(?:youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#&?]+)/);
    if (vMatch && vMatch[1]) {
      var newId = vMatch[1];
      var existingIndex = -1;
      for (var idx = 0; idx < videos.length; idx++) {
        if (videos[idx].id === newId) {
          existingIndex = idx;
          break;
        }
      }

      if (existingIndex >= 0) {
        setActive(existingIndex);
      } else {
        videos.unshift({
          id: newId,
          title: "Video hướng dẫn mới nhất từ Admin",
          sub: "Cập nhật trực tiếp từ hệ thống quản trị",
        });
        renderCarousel();
        setActive(0);
      }
    }
  }

  // Initial config check
  try {
    var raw = localStorage.getItem('autobank_system_config');
    if (raw) {
      applyConfig(JSON.parse(raw));
    }
  } catch (_) {}

  var player = document.getElementById("seo-yt-player");
  var facade = document.getElementById("seo-yt-facade");
  var track = document.getElementById("seo-video-track");
  if (!player || !track) return;

  var current = 0;
  var playerReady = false;

  function embedUrl(id) {
    return (
      "https://www.youtube-nocookie.com/embed/" +
      id +
      "?rel=0&modestbranding=1&autoplay=1&list=" +
      PLAYLIST
    );
  }

  function showPlayer() {
    if (playerReady) return;
    playerReady = true;
    if (facade) facade.hidden = true;
    player.hidden = false;
  }

  function loadVideo(index) {
    if (!videos[index]) return;
    current = index;
    showPlayer();
    player.src = embedUrl(videos[index].id);
    player.title = videos[index].title;

    // Also update facade image in case player is reset
    if (facade) {
      var img = facade.querySelector("img");
      if (img) img.src = "https://img.youtube.com/vi/" + videos[index].id + "/hqdefault.jpg";
    }
  }

  function setActive(index) {
    if (!track) return;
    var cards = track.querySelectorAll(".seo-video-card");
    cards.forEach(function (c, i) {
      c.classList.toggle("active", i === index);
      c.setAttribute("aria-current", i === index ? "true" : "false");
    });
    loadVideo(index);
    var card = cards[index];
    if (card && track) {
      var maxScroll = track.scrollWidth - track.clientWidth;
      if (maxScroll > 0) {
        var left =
          card.offsetLeft - track.clientWidth / 2 + card.offsetWidth / 2;
        track.scrollTo({
          left: Math.max(0, Math.min(left, maxScroll)),
          behavior: "smooth",
        });
      }
    }
  }

  function renderCarousel() {
    if (!track) return;
    track.innerHTML = "";
    videos.forEach(function (v, i) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "seo-video-card" + (i === current ? " active" : "");
      btn.setAttribute("aria-current", i === current ? "true" : "false");
      btn.innerHTML =
        '<img src="https://img.youtube.com/vi/' +
        v.id +
        '/mqdefault.jpg" alt="" loading="lazy" width="320" height="180" decoding="async" />' +
        '<div class="seo-video-card-body"><strong>' +
        v.title +
        "</strong><span>" +
        v.sub +
        "</span></div>";
      btn.addEventListener("click", function () {
        setActive(i);
      });
      track.appendChild(btn);
    });
  }

  renderCarousel();

  if (facade) {
    facade.addEventListener("click", function () {
      setActive(current);
    });
  }

  var prev = document.getElementById("seo-carousel-prev");
  var next = document.getElementById("seo-carousel-next");

  if (prev) {
    prev.addEventListener("click", function () {
      if (!playerReady) {
        setActive((current - 1 + videos.length) % videos.length);
        return;
      }
      current = (current - 1 + videos.length) % videos.length;
      setActive(current);
    });
  }
  if (next) {
    next.addEventListener("click", function () {
      if (!playerReady) {
        setActive((current + 1) % videos.length);
        return;
      }
      current = (current + 1) % videos.length;
      setActive(current);
    });
  }

  track.addEventListener("click", function () {
    var active = track.querySelector(".seo-video-card.active");
    if (active) {
      current = Array.prototype.indexOf.call(track.children, active);
    }
  });

  // Listen to live config events
  window.addEventListener("autobank_config_updated", function (e) {
    if (e.detail) applyConfig(e.detail);
  });

  window.addEventListener("storage", function (e) {
    if (e.key === "autobank_system_config" && e.newValue) {
      try {
        applyConfig(JSON.parse(e.newValue));
      } catch (_) {}
    }
  });

  try {
    var chan = new BroadcastChannel("autobank_live_channel");
    chan.onmessage = function (e) {
      if (e.data && e.data.type === "CONFIG_UPDATED" && e.data.config) {
        applyConfig(e.data.config);
      }
    };
  } catch (_) {}

  window.autobankUpdateYouTube = applyConfig;
})();
