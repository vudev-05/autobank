(function () {
  "use strict";

  function shotWebp(base) {
    return base;
  }

  function shotPng(base) {
    return base;
  }

  var shots = [
    {
      src: "assets/images/1c4dffe8-47b5-4db7-9f23-85eb3cf388ac.png",
      title: "Đọc to số tiền",
      caption: "App nói to, rõ số tiền mỗi khi khách chuyển khoản — không cần nhìn điện thoại.",
      tag: "Báo tiền tức thì",
      highlights: [
        "Báo âm thanh tức thì < 0.5s ngay khi có thông báo tiền vào tài khoản",
        "Đọc to, chuẩn xác từng nghìn đồng theo giọng tiếng Việt tự nhiên",
        "Chống 100% rủi ro bị kẻ gian lừa đảo bằng hình ảnh bill giả mạo"
      ]
    },
    {
      src: "assets/images/4ec0cf8e-2001-49f5-bea9-e0edd5cc5615.png",
      title: "Chế độ bán hàng",
      caption: "Biến điện thoại thành loa thông báo và màn hình QR nhận tiền tại quầy.",
      tag: "Trưng bày quầy thu ngân",
      highlights: [
        "Hiển thị mã QR ngân hàng sắc nét toàn màn hình cho khách quét thanh toán",
        "Tự động phát âm thanh xác nhận ngay tại quầy thanh toán không độ trễ",
        "Tiết kiệm chi phí đầu tư máy POS đắt tiền hay thuê thiết bị phát thanh"
      ]
    },
    {
      src: "assets/images/581d3195-5bab-47e4-93b0-5b4df35fa8c8.png",
      title: "Thống kê giao dịch",
      caption: "Theo dõi thu chi, top ngân hàng và giờ cao điểm nhận tiền.",
      tag: "Quản lý doanh thu",
      highlights: [
        "Báo cáo tổng kết dòng tiền thu vào chi tiết theo ngày, tuần và tháng",
        "Biểu đồ trực quan ngân hàng nào khách chuyển về nhiều nhất trong ngày",
        "Lưu trữ lịch sử giao dịch rõ ràng, hỗ trợ đối soát sổ sách cuối ngày"
      ]
    },
    {
      src: "assets/images/2a9a34c5-09d1-482a-97e1-1ecc6c4cd1e4.png",
      title: "Tính năng giải trí",
      caption: "Mini game thư giãn sau giờ bán — pet, 2048, Tetris và nhiều hơn.",
      tag: "Thư giãn tiện ích",
      highlights: [
        "Kho mini game giải trí nhẹ nhàng ngay trong lúc chờ khách hàng ghé quán",
        "Ứng dụng hoạt động mượt mà, tối ưu pin không gây nóng máy khi chạy ngầm",
        "Hệ thống loa đọc tiền vẫn hoạt động liên tục 24/7 ngay cả khi đang chơi"
      ]
    },
    {
      src: "assets/images/25706eba-2d8c-47ea-ab29-4612607b64b7.png",
      title: "Kiếm tiền giới thiệu",
      caption: "Chia sẻ mã giới thiệu, nhận hoa hồng khi người được mời mua gói.",
      tag: "Thu nhập hoa hồng",
      highlights: [
        "Mỗi chủ tài khoản sở hữu 1 mã giới thiệu 6 số độc quyền chia sẻ",
        "Nhận hoa hồng tức thì vào tài khoản khi người quen kích hoạt gói",
        "Thống kê chi tiết số lượt giới thiệu và lịch sử nhận tiền minh bạch"
      ]
    },
    {
      src: "assets/images/ed22a994-3e29-47d4-a07d-5ee499dbbe7c.png",
      title: "Video hướng dẫn",
      caption: "8 video hướng dẫn cài đặt và sử dụng ngay trong app.",
      tag: "Chỉ dẫn từng bước",
      highlights: [
        "Video clip ngắn gọn, chỉ dẫn từng thao tác cài đặt trên màn hình điện thoại",
        "Hướng dẫn cấp quyền pin và chạy nền cho Xiaomi, Samsung, Oppo, Vivo...",
        "Dễ hiểu cho mọi lứa tuổi, chỉ cần xem và làm theo là dùng được ngay"
      ]
    },
    {
      src: "assets/images/6c5bfa32-58eb-490d-8fbb-3f3df031caa2.png",
      title: "Hỗ trợ 24/7",
      caption: "Đội ngũ CSKH sẵn sàng giải đáp qua Zalo và yêu cầu hỗ trợ trong app.",
      tag: "Hỗ trợ kỹ thuật",
      highlights: [
        "Kênh kết nối kỹ thuật trực tiếp qua Zalo và hotline phản hồi nhanh chóng",
        "Hỗ trợ cài đặt từ xa qua UltraView khi khách hàng cần trợ giúp tận tình",
        "Cập nhật mẫu thông báo ngân hàng mới và tính năng tiện ích trọn đời"
      ]
    },
    {
      src: "assets/images/8457c58b-abb8-43df-ba18-aedc1a1b18b1.png",
      title: "Báo chuyển tiền bằng giọng nói",
      caption: "Khách chuyển tiền — shop nghe liền. Tải ngay trên Google Play.",
      tag: "Giọng đọc đa dạng",
      highlights: [
        "Đa dạng tùy chọn giọng đọc Bắc, Trung, Nam và trợ lý ảo AI sắc nét",
        "Hỗ trợ kết nối loa ngoài Bluetooth, loa thùng, loa kéo công suất lớn",
        "Tương thích hơn 65+ ngân hàng và ví điện tử phổ biến tại Việt Nam"
      ]
    },
  ];

  var stage = document.getElementById("seo-screenshot-stage");
  var mainImg = document.getElementById("seo-screenshot-main");
  var titleEl = document.getElementById("seo-screenshot-title");
  var captionEl = document.getElementById("seo-screenshot-caption");
  var counterEl = document.getElementById("seo-screenshot-counter");
  var tagEl = document.getElementById("seo-screenshot-tag");
  var highlightsEl = document.getElementById("seo-screenshot-highlights");
  var track = document.getElementById("seo-screenshots-track");
  var dots = document.getElementById("seo-screenshots-dots");
  var prev = document.getElementById("seo-screenshots-prev");
  var next = document.getElementById("seo-screenshots-next");

  if (!stage || !mainImg || !track) return;

  var current = 0;
  var touchStartX = 0;

  function scrollThumbIntoTrack(activeThumb, smooth) {
    if (!activeThumb || !track) return;
    var maxScroll = track.scrollWidth - track.clientWidth;
    if (maxScroll <= 0) return;
    var left =
      activeThumb.offsetLeft -
      track.clientWidth / 2 +
      activeThumb.offsetWidth / 2;
    left = Math.max(0, Math.min(left, maxScroll));
    if (smooth) {
      track.scrollTo({ left: left, behavior: "smooth" });
    } else {
      track.scrollLeft = left;
    }
  }

  function setSlide(index, options) {
    options = options || {};
    current = (index + shots.length) % shots.length;
    var shot = shots[current];

    // Transition image
    mainImg.classList.add("seo-img-fade");
    setTimeout(function () {
      mainImg.src = shotWebp(shot.src);
      mainImg.alt = shot.title + " — ảnh Google Play";
      mainImg.classList.remove("seo-img-fade");
    }, 120);

    mainImg.onerror = function () {
      mainImg.onerror = null;
      mainImg.src = shot.src;
    };

    if (titleEl) titleEl.textContent = shot.title;
    if (captionEl) captionEl.textContent = shot.caption;
    if (counterEl) {
      counterEl.textContent = current + 1 + " / " + shots.length;
    }
    if (tagEl && shot.tag) {
      tagEl.textContent = shot.tag;
    }

    if (highlightsEl && shot.highlights) {
      highlightsEl.innerHTML = shot.highlights
        .map(function (item) {
          return (
            '<div class="seo-showcase-highlight-item">' +
            '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>' +
            "<span>" +
            item +
            "</span>" +
            "</div>"
          );
        })
        .join("");
    }

    track.querySelectorAll(".seo-screenshot-thumb").forEach(function (btn, i) {
      var active = i === current;
      btn.classList.toggle("active", active);
      btn.setAttribute("aria-current", active ? "true" : "false");
    });

    if (dots) {
      dots.querySelectorAll(".seo-screenshot-dot").forEach(function (btn, i) {
        var active = i === current;
        btn.classList.toggle("active", active);
        btn.setAttribute("aria-current", active ? "true" : "false");
      });
    }

    if (options.scrollThumb) {
      var activeThumb = track.querySelector(".seo-screenshot-thumb.active");
      window.requestAnimationFrame(function () {
        scrollThumbIntoTrack(activeThumb, options.smoothThumb !== false);
      });
    }
  }

  shots.forEach(function (shot, i) {
    var thumb = document.createElement("button");
    thumb.type = "button";
    thumb.className = "seo-screenshot-thumb" + (i === 0 ? " active" : "");
    thumb.setAttribute("aria-label", "Xem tính năng: " + shot.title);
    thumb.setAttribute("aria-current", i === 0 ? "true" : "false");
    var numPad = (i + 1 < 10 ? "0" : "") + (i + 1);

    thumb.innerHTML =
      '<div class="seo-thumb-top-row">' +
      '<span class="seo-thumb-badge">' +
      numPad +
      "</span>" +
      '<span class="seo-thumb-status-dot"></span>' +
      "</div>" +
      '<div class="seo-thumb-img-wrap">' +
      '<img src="' +
      shot.src +
      '" alt="" loading="lazy" decoding="async" width="80" height="142" />' +
      "</div>" +
      '<span class="seo-thumb-title">' +
      shot.title +
      "</span>";

    var imgEl = thumb.querySelector("img");
    if (imgEl) {
      imgEl.onerror = function () {
        imgEl.onerror = null;
        imgEl.src = shot.src;
      };
    }

    thumb.addEventListener("click", function () {
      setSlide(i, { scrollThumb: true, smoothThumb: true });
    });
    track.appendChild(thumb);

    if (dots) {
      var dot = document.createElement("button");
      dot.type = "button";
      dot.className = "seo-screenshot-dot" + (i === 0 ? " active" : "");
      dot.setAttribute("aria-label", "Ảnh " + (i + 1) + ": " + shot.title);
      dot.setAttribute("aria-current", i === 0 ? "true" : "false");
      dot.addEventListener("click", function () {
        setSlide(i, { scrollThumb: true, smoothThumb: true });
      });
      dots.appendChild(dot);
    }
  });

  if (prev) {
    prev.addEventListener("click", function () {
      setSlide(current - 1, { scrollThumb: true, smoothThumb: true });
    });
  }
  if (next) {
    next.addEventListener("click", function () {
      setSlide(current + 1, { scrollThumb: true, smoothThumb: true });
    });
  }

  var phone = document.getElementById("seo-showcase-phone") || stage;
  var visual = document.getElementById("seo-showcase-visual") || stage;

  var touchStartX = 0;
  var touchStartY = 0;
  var touchDeltaX = 0;
  var touchDeltaY = 0;
  var isTouchActive = false;

  function handleTouchStart(e) {
    if (!e.touches || e.touches.length !== 1) return;
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
    touchDeltaX = 0;
    touchDeltaY = 0;
    isTouchActive = true;
  }

  function handleTouchMove(e) {
    if (!isTouchActive || !e.touches || e.touches.length !== 1) return;
    touchDeltaX = e.touches[0].clientX - touchStartX;
    touchDeltaY = e.touches[0].clientY - touchStartY;
  }

  function handleTouchEnd() {
    if (!isTouchActive) return;
    isTouchActive = false;
    // Check if horizontal intent is dominant and exceeds threshold
    if (Math.abs(touchDeltaX) >= 35 && Math.abs(touchDeltaX) > Math.abs(touchDeltaY) * 1.1) {
      if (touchDeltaX < 0) {
        setSlide(current + 1, { scrollThumb: true, smoothThumb: true });
      } else {
        setSlide(current - 1, { scrollThumb: true, smoothThumb: true });
      }
    }
  }

  // Attach touch listeners to phone, visual container and stage
  [phone, visual, stage].forEach(function (el) {
    if (!el) return;
    el.addEventListener("touchstart", handleTouchStart, { passive: true });
    el.addEventListener("touchmove", handleTouchMove, { passive: true });
    el.addEventListener("touchend", handleTouchEnd, { passive: true });
    el.addEventListener("touchcancel", function () { isTouchActive = false; }, { passive: true });
  });

  // Pointer drag support for desktop/mouse
  var isMouseDown = false;
  var mouseStartX = 0;
  var mouseDeltaX = 0;

  if (phone) {
    phone.addEventListener("mousedown", function (e) {
      isMouseDown = true;
      mouseStartX = e.clientX;
      mouseDeltaX = 0;
    });

    window.addEventListener("mousemove", function (e) {
      if (!isMouseDown) return;
      mouseDeltaX = e.clientX - mouseStartX;
    });

    window.addEventListener("mouseup", function () {
      if (!isMouseDown) return;
      isMouseDown = false;
      if (Math.abs(mouseDeltaX) >= 40) {
        if (mouseDeltaX < 0) {
          setSlide(current + 1, { scrollThumb: true, smoothThumb: true });
        } else {
          setSlide(current - 1, { scrollThumb: true, smoothThumb: true });
        }
      }
    });
  }

  document.addEventListener("keydown", function (e) {
    if (!stage.matches(":hover") && document.activeElement !== prev && document.activeElement !== next) {
      return;
    }
    if (e.key === "ArrowLeft") setSlide(current - 1, { scrollThumb: true, smoothThumb: true });
    if (e.key === "ArrowRight") setSlide(current + 1, { scrollThumb: true, smoothThumb: true });
  });

  setSlide(0, { scrollThumb: false });
})();
