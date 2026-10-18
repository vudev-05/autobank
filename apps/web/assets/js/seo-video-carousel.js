(function () {
  "use strict";

  var player = document.getElementById("seo-yt-player");
  var facade = document.getElementById("seo-yt-facade");
  var track = document.getElementById("seo-video-track");
  var videoSection = document.getElementById("video");
  var carouselWrap = document.querySelector(".seo-video-carousel-wrap");

  var currentVideos = [];
  var currentPlaylistId = "";
  var current = 0;
  var playerReady = false;

  function setVideoVisibility(visible) {
    if (videoSection) {
      videoSection.style.display = visible ? "" : "none";
    }
    document.querySelectorAll('a[href="#video"]').forEach(function (link) {
      link.style.display = visible ? "" : "none";
    });
  }

  function extractYouTubeInfo(url) {
    if (!url || typeof url !== "string") return null;
    var trimmed = url.trim();
    if (!trimmed) return null;

    var playlistId = "";
    var listMatch = trimmed.match(/[?&]list=([^#&?]+)/);
    if (listMatch && listMatch[1]) {
      playlistId = listMatch[1];
    }

    // Check for multiple URLs separated by comma, semicolon or newline
    var rawItems = trimmed.split(/[\r\n,;]+/).map(function (s) { return s.trim(); }).filter(Boolean);
    var videoList = [];

    rawItems.forEach(function (item, idx) {
      var vMatch = item.match(/(?:youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\?v=)([^#&?]+)/);
      var vid = vMatch ? vMatch[1] : (item.length === 11 && !item.includes('/') ? item : null);
      if (vid) {
        videoList.push({
          id: vid,
          title: "Video hướng dẫn " + (videoList.length + 1),
          sub: "Xem chi tiết hướng dẫn thao tác trên app",
        });
      }
    });

    return {
      playlistId: playlistId,
      videos: videoList,
      rawUrl: trimmed,
    };
  }

  function embedUrl(id, playlistId) {
    var base = "https://www.youtube-nocookie.com/embed/" + id + "?rel=0&modestbranding=1&autoplay=1";
    if (playlistId) {
      base += "&list=" + playlistId;
    }
    return base;
  }

  function showPlayer() {
    if (playerReady) return;
    playerReady = true;
    if (facade) facade.hidden = true;
    if (player) player.hidden = false;
  }

  function loadVideo(index) {
    if (!currentVideos[index] || !player) return;
    current = index;
    showPlayer();
    player.src = embedUrl(currentVideos[index].id, currentPlaylistId);
    player.title = currentVideos[index].title;

    if (facade) {
      var img = facade.querySelector("img");
      if (img) {
        img.src = "https://img.youtube.com/vi/" + currentVideos[index].id + "/hqdefault.jpg";
      }
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
        var left = card.offsetLeft - track.clientWidth / 2 + card.offsetWidth / 2;
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

    if (currentVideos.length <= 1) {
      if (carouselWrap) carouselWrap.style.display = "none";
      return;
    }

    if (carouselWrap) carouselWrap.style.display = "";
    currentVideos.forEach(function (v, i) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "seo-video-card" + (i === current ? " active" : "");
      btn.setAttribute("aria-current", i === current ? "true" : "false");
      btn.innerHTML =
        '<img src="https://img.youtube.com/vi/' +
        v.id +
        '/mqdefault.jpg" alt="' + v.title + '" loading="lazy" width="320" height="180" decoding="async" />' +
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

  function applyConfig(cfg) {
    var yt = (cfg && (cfg.youtubeLink || cfg.youtubeUrl || "")) || "";
    yt = yt.trim();

    // 1. If admin did not enter YouTube URL -> HIDE THE ENTIRE VIDEO SECTION
    if (!yt) {
      setVideoVisibility(false);
      return;
    }

    // 2. Admin entered a link -> SHOW THE VIDEO SECTION WITH GIVEN VIDEOS
    var parsed = extractYouTubeInfo(yt);
    if (!parsed) {
      setVideoVisibility(false);
      return;
    }

    setVideoVisibility(true);
    currentPlaylistId = parsed.playlistId;

    if (parsed.videos.length > 0) {
      currentVideos = parsed.videos;
    } else if (parsed.playlistId) {
      // Playlist only link
      currentVideos = [
        {
          id: "",
          title: "Playlist hướng dẫn sử dụng",
          sub: "Xem toàn bộ chuỗi video hướng dẫn trên YouTube",
        },
      ];
    } else {
      currentVideos = [];
    }

    // Update main facade image
    if (facade && currentVideos[0] && currentVideos[0].id) {
      var fImg = facade.querySelector("img");
      if (fImg) {
        fImg.src = "https://img.youtube.com/vi/" + currentVideos[0].id + "/hqdefault.jpg";
      }
      facade.hidden = false;
      if (player) {
        player.hidden = true;
        playerReady = false;
      }
    } else if (parsed.playlistId && player) {
      showPlayer();
      player.src = "https://www.youtube-nocookie.com/embed/videoseries?list=" + parsed.playlistId;
    }

    // Update bottom channel and playlist links
    var playlistLink = document.getElementById("yt-playlist-link");
    if (playlistLink) {
      if (parsed.playlistId) {
        playlistLink.href = "https://www.youtube.com/playlist?list=" + parsed.playlistId;
        playlistLink.style.display = "";
      } else {
        playlistLink.style.display = "none";
      }
    }

    var channelLink = document.getElementById("yt-channel-link");
    if (channelLink) {
      channelLink.href = yt;
      var handleMatch = yt.match(/@([a-zA-Z0-9_\-]+)/);
      if (handleMatch) {
        channelLink.textContent = "@" + handleMatch[1];
        channelLink.style.display = "";
      } else {
        channelLink.textContent = "Kênh YouTube hướng dẫn";
        channelLink.style.display = "";
      }
    }

    renderCarousel();
  }

  // Initial setup: hide by default until valid config confirms youtubeLink
  setVideoVisibility(false);

  // Check cached config if present
  try {
    var raw = localStorage.getItem("autobank_system_config");
    if (raw) {
      applyConfig(JSON.parse(raw));
    }
  } catch (_) {}

  if (facade) {
    facade.addEventListener("click", function () {
      if (currentVideos.length > 0) {
        setActive(current);
      }
    });
  }

  var prev = document.getElementById("seo-carousel-prev");
  var next = document.getElementById("seo-carousel-next");

  if (prev) {
    prev.addEventListener("click", function () {
      if (currentVideos.length === 0) return;
      current = (current - 1 + currentVideos.length) % currentVideos.length;
      setActive(current);
    });
  }
  if (next) {
    next.addEventListener("click", function () {
      if (currentVideos.length === 0) return;
      current = (current + 1) % currentVideos.length;
      setActive(current);
    });
  }

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
