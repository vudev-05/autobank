/**
 * Autobank Interactive VietQR Payment Modal
 * Connects Landing Page to NestJS Backend API (localhost:3000)
 */
(function () {
  'use strict';

  let API_BASE = 'http://localhost:3000';
  let BANK_ID = 'MB';
  let ACCOUNT_NO = '3011200588888';
  let ACCOUNT_NAME = 'TRẦN QUỐC VŨ';

  const packages = {
    'trial': { name: 'Dùng thử 3 ngày', price: 0, text: 'Miễn phí 3 ngày' },
    '1month': { name: 'Gói 1 Tháng', price: 39000, text: '39.000đ' },
    '3month': { name: 'Gói 3 Tháng', price: 99000, text: '99.000đ' },
    '6month': { name: 'Gói 6 Tháng', price: 179000, text: '179.000đ' },
    '9month': { name: 'Gói 9 Tháng', price: 249000, text: '249.000đ' },
    '1year': { name: 'Gói 1 Năm (Tiết kiệm nhất)', price: 299000, text: '299.000đ' },
  };

  function applyCfg(cfg) {
    if (!cfg) return;
    if (cfg.bankCode || cfg.vietqrBank) BANK_ID = cfg.bankCode || cfg.vietqrBank;
    if (cfg.bankAcc || cfg.vietqrAccount) ACCOUNT_NO = cfg.bankAcc || cfg.vietqrAccount;
    if (cfg.bankName || cfg.vietqrName) ACCOUNT_NAME = cfg.bankName || cfg.vietqrName;
    const cleanNum = (v, def) => {
      if (!v) return def;
      const n = parseInt(String(v).replace(/\D/g, ''), 10);
      return isNaN(n) ? def : n;
    };
    const p1 = cleanNum(cfg.price1m, 39000);
    const p3 = cleanNum(cfg.price3m, 99000);
    const p6 = cleanNum(cfg.price6m, 179000);
    const p9 = cleanNum(cfg.price9m, 249000);
    const py = cleanNum(cfg.price1y, 299000);
    packages['1month'] = { name: 'Gói 1 Tháng', price: p1, text: p1.toLocaleString('vi-VN') + 'đ' };
    packages['3month'] = { name: 'Gói 3 Tháng', price: p3, text: p3.toLocaleString('vi-VN') + 'đ' };
    packages['6month'] = { name: 'Gói 6 Tháng', price: p6, text: p6.toLocaleString('vi-VN') + 'đ' };
    packages['9month'] = { name: 'Gói 9 Tháng', price: p9, text: p9.toLocaleString('vi-VN') + 'đ' };
    packages['1year'] = { name: 'Gói 1 Năm (Tiết kiệm nhất)', price: py, text: py.toLocaleString('vi-VN') + 'đ' };

    if (Array.isArray(cfg.packages) && cfg.packages.length > 0) {
      cfg.packages.forEach(pkg => {
        if (pkg.isActive !== false) {
          const k = pkg.key || 'pkg_' + pkg.durationDays;
          packages[k] = {
            name: pkg.name,
            price: Number(pkg.price || 0),
            text: Number(pkg.price || 0).toLocaleString('vi-VN') + 'đ',
            badge: pkg.badge || '',
            days: pkg.durationDays,
            desc: pkg.description || '',
          };
          if (k === '1m') packages['1month'] = packages[k];
          if (k === '3m') packages['3month'] = packages[k];
          if (k === '6m') packages['6month'] = packages[k];
          if (k === '9m') packages['9month'] = packages[k];
          if (k === '1y') packages['1year'] = packages[k];
          if (k === 'lifetime') packages['lifetime'] = packages[k];
        }
      });
    }

    // Đồng bộ giá hiển thị trực tiếp trên Landing Page HTML
    const updateCardPrice = (key, text) => {
      const btn = document.querySelector(`[data-package="${key}"]`);
      if (btn) {
        const card = btn.closest('.single-price');
        if (card) {
          const priceEl = card.querySelector('.package-price');
          if (priceEl) priceEl.textContent = text;
        }
      }
    };
    if (packages['1month']) updateCardPrice('1month', packages['1month'].text);
    if (packages['3month']) updateCardPrice('3month', packages['3month'].text);
    if (packages['6month']) updateCardPrice('6month', packages['6month'].text);
    if (packages['9month']) updateCardPrice('9month', packages['9month'].text);
    if (packages['1year']) updateCardPrice('1year', packages['1year'].text);

    // Đồng bộ hotline & Zalo trên Landing Page
    if (cfg.hotline) {
      document.querySelectorAll('a[href^="tel:"]').forEach(a => {
        a.href = `tel:${cfg.hotline}`;
        if (/^0\d+/.test(a.textContent.trim())) {
          a.textContent = cfg.hotline;
        }
      });
      document.querySelectorAll('a[href*="zalo.me"]').forEach(a => {
        a.href = `https://zalo.me/${cfg.hotline}`;
      });
      document.querySelectorAll('.seo-contact-card__value').forEach(el => {
        if (/^0\d+/.test(el.textContent.trim())) {
          el.textContent = cfg.hotline;
        } else if (el.textContent.includes('zalo.me')) {
          el.textContent = `zalo.me/${cfg.hotline}`;
        }
      });
    }

    // Hiển thị Marketing Banner nếu admin cấu hình trong MySQL
    if (cfg.marketingBanner && cfg.marketingBanner.trim()) {
      let banner = document.getElementById('autobank-live-banner');
      if (!banner) {
        banner = document.createElement('div');
        banner.id = 'autobank-live-banner';
        banner.style.cssText = 'background: linear-gradient(90deg, #1e3a8a, #2563eb); color: #fff; text-align: center; padding: 10px 16px; font-size: 13.5px; font-weight: 600; position: sticky; top: 0; z-index: 9999; box-shadow: 0 2px 10px rgba(0,0,0,0.15); display: flex; align-items: center; justify-content: center; gap: 8px;';
        document.body.prepend(banner);
      }
      banner.innerHTML = `<span>📢</span> <span>${cfg.marketingBanner}</span>`;
    }
  }

  function refreshConfigFromAdmin() {
    try {
      const raw = localStorage.getItem('autobank_system_config');
      if (raw) {
        applyCfg(JSON.parse(raw));
      }
      fetch(`${API_BASE}/admin/configs`)
        .then(res => res.json())
        .then(data => {
          if (data && (data.bankAcc || data.hotline)) {
            applyCfg(data);
          }
        })
        .catch(() => {});
      fetch(`${API_BASE}/admin/thueapi/config`)
        .then(res => res.json())
        .then(data => {
          if (data && data.bankAcc) {
            applyCfg(data);
          }
        })
        .catch(() => {});
    } catch (e) {
      console.warn('Cannot read admin config in payment modal', e);
    }
  }

  let activePollInterval = null;
  let countdownTimer = null;

  function createModalDOM() {
    if (document.getElementById('autobank-payment-modal')) return;

    const modalHTML = `
      <div id="autobank-payment-modal" class="ab-modal" aria-hidden="true" role="dialog">
        <div class="ab-modal-backdrop" id="ab-modal-backdrop"></div>
        <div class="ab-modal-dialog">
          <div class="ab-modal-header">
            <div>
              <span class="ab-badge">Thanh toán VietQR 24/7</span>
              <h3 class="ab-modal-title" id="ab-pkg-title">Kích hoạt gói dịch vụ</h3>
            </div>
            <button type="button" class="ab-modal-close" id="ab-modal-close" aria-label="Đóng">&times;</button>
          </div>

          <div class="ab-modal-body" id="ab-modal-body">
            <!-- Content will be injected dynamically -->
          </div>
        </div>
      </div>
    `;

    document.body.insertAdjacentHTML('beforeend', modalHTML);

    const style = document.createElement('style');
    style.textContent = `
      .ab-modal {
        position: fixed;
        inset: 0;
        z-index: 100099;
        display: none;
        align-items: center;
        justify-content: center;
        padding: 16px;
      }
      .ab-modal.is-open {
        display: flex;
      }
      .ab-modal-backdrop {
        position: absolute;
        inset: 0;
        background: rgba(15, 23, 42, 0.78);
        backdrop-filter: blur(6px);
      }
      .ab-modal-dialog {
        position: relative;
        z-index: 1;
        background: #ffffff;
        border-radius: 24px;
        max-width: 540px;
        width: 100%;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 25px 60px rgba(0, 0, 0, 0.25);
        border: 1px solid #e2e8f0;
      }
      .ab-modal-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        padding: 24px 28px 16px;
        border-bottom: 1px solid #f1f5f9;
      }
      .ab-badge {
        display: inline-block;
        background: #e0f2fe;
        color: #0284c7;
        font-size: 0.75rem;
        font-weight: 800;
        text-transform: uppercase;
        padding: 4px 10px;
        border-radius: 999px;
        margin-bottom: 6px;
      }
      .ab-modal-title {
        font-size: 1.35rem;
        font-weight: 800;
        color: #0f172a;
        margin: 0;
      }
      .ab-modal-close {
        background: #f1f5f9;
        border: none;
        width: 36px;
        height: 36px;
        border-radius: 50%;
        font-size: 1.5rem;
        line-height: 1;
        cursor: pointer;
        color: #64748b;
        transition: all 0.2s;
      }
      .ab-modal-close:hover {
        background: #e2e8f0;
        color: #0f172a;
      }
      .ab-modal-body {
        padding: 24px 28px 28px;
      }
      .ab-qr-container {
        text-align: center;
        background: #f8fafc;
        border-radius: 18px;
        padding: 20px;
        border: 2px dashed #cbd5e1;
        margin-bottom: 20px;
      }
      .ab-qr-img {
        max-width: 260px;
        width: 100%;
        height: auto;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0,0,0,0.08);
        background: #fff;
      }
      .ab-timer {
        font-size: 0.88rem;
        color: #e11d48;
        font-weight: 700;
        margin-top: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
      }
      .ab-info-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 10px;
        margin-bottom: 24px;
        background: #f8fafc;
        padding: 16px;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
      }
      .ab-info-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-size: 0.92rem;
      }
      .ab-info-label {
        color: #64748b;
      }
      .ab-info-val {
        font-weight: 700;
        color: #0f172a;
        display: flex;
        align-items: center;
        gap: 6px;
      }
      .ab-copy-btn {
        background: #e2e8f0;
        border: none;
        padding: 2px 8px;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 700;
        color: #0369a1;
        cursor: pointer;
      }
      .ab-copy-btn:hover {
        background: #cbd5e1;
      }
      .ab-status-box {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 16px;
        border-radius: 12px;
        background: #f0fdf4;
        border: 1px solid #bbf7d0;
        color: #166534;
        font-size: 0.9rem;
        font-weight: 600;
        margin-bottom: 16px;
      }
      .ab-pulse {
        width: 10px;
        height: 10px;
        background: #22c55e;
        border-radius: 50%;
        box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.7);
        animation: ab-pulse-ring 1.5s infinite;
      }
      @keyframes ab-pulse-ring {
        0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.7); }
        70% { transform: scale(1); box-shadow: 0 0 0 8px rgba(34, 197, 94, 0); }
        100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); }
      }
      .ab-action-group {
        display: flex;
        gap: 10px;
      }
      .ab-btn-test {
        flex: 1;
        padding: 12px;
        border-radius: 12px;
        border: 1px solid #cbd5e1;
        background: #fff;
        color: #334155;
        font-weight: 700;
        font-size: 0.88rem;
        cursor: pointer;
      }
      .ab-btn-test:hover {
        background: #f1f5f9;
      }
      .ab-btn-app {
        flex: 1;
        padding: 12px;
        border-radius: 12px;
        background: linear-gradient(135deg, #0369a1, #0284c7);
        color: #fff;
        text-align: center;
        text-decoration: none;
        font-weight: 700;
        font-size: 0.88rem;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .ab-success-card {
        text-align: center;
        padding: 30px 10px;
      }
      .ab-success-icon {
        width: 64px;
        height: 64px;
        border-radius: 50%;
        background: #22c55e;
        color: #fff;
        font-size: 2rem;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 16px;
      }
    `;
    document.head.appendChild(style);

    document.getElementById('ab-modal-close').addEventListener('click', closeModal);
    document.getElementById('ab-modal-backdrop').addEventListener('click', closeModal);
  }

  function openModal(pkgKey) {
    refreshConfigFromAdmin();
    createModalDOM();
    const pkg = packages[pkgKey] || packages['1year'];
    const modal = document.getElementById('autobank-payment-modal');
    const titleEl = document.getElementById('ab-pkg-title');
    const bodyEl = document.getElementById('ab-modal-body');

    titleEl.textContent = pkg.name;

    if (pkg.price === 0) {
      bodyEl.innerHTML = `
        <div class="ab-success-card">
          <div class="ab-success-icon" style="background: #0f172a; color: #ffffff;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
          </div>
          <h4 style="font-size: 1.25rem; font-weight: 800; color: #0f172a; margin-bottom: 8px;">Kích hoạt dùng thử 3 ngày</h4>
          <p style="color: #64748b; font-size: 0.95rem; margin-bottom: 24px;">
            Đăng nhập tài khoản Google trên ứng dụng Android để nhận ngay 3 ngày trải nghiệm không giới hạn tính năng đọc thông báo biến động số dư.
          </p>
          <a href="https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn" class="main-btn btn-hover" style="display: block; width: 100%; border-radius: 12px; padding: 14px; background: #0f172a;">Tải ứng dụng trên Google Play</a>
        </div>
      `;
      modal.classList.add('is-open');
      return;
    }

    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const orderCode = `AB${Date.now().toString().slice(-4)}${randomSuffix}`;
    const qrUrl = `https://img.vietqr.io/image/${BANK_ID}-${ACCOUNT_NO}-compact2.png?amount=${pkg.price}&addInfo=${orderCode}&accountName=${encodeURIComponent(ACCOUNT_NAME)}`;

    // Sync order to MySQL backend API
    fetch(`${API_BASE}/admin/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        orderCode,
        totalAmount: pkg.price,
        description: pkg.name,
        customerName: 'Khách hàng Website VietQR',
        customerPhone: '0869226687',
        status: 'PENDING',
      }),
    }).catch(() => {});

      const appDeepLink = `autobank://subscribe?plan=${encodeURIComponent(pkgKey)}`;

      bodyEl.innerHTML = `
        <div class="ab-status-box">
          <span class="ab-pulse"></span>
          <span id="ab-status-text">Đang chờ thanh toán gói ${pkg.name}... Mở App hoặc quét QR</span>
        </div>

        <div style="margin-bottom: 20px;">
          <a href="${appDeepLink}" class="ab-btn-app" style="width: 100%; padding: 14px 18px; font-size: 1rem; border-radius: 14px; font-weight: 800; display: flex; align-items: center; justify-content: center; gap: 8px; text-decoration: none; box-shadow: 0 6px 20px rgba(2, 132, 199, 0.35); margin-bottom: 12px; background: linear-gradient(135deg, #0284c7, #0369a1);">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>
            Mở App AutoBank để thanh toán gói này
          </a>
        </div>

        <div class="ab-qr-container">
          <img class="ab-qr-img" src="${qrUrl}" alt="VietQR Thanh toán ${pkg.name}" />
          <div class="ab-timer" id="ab-timer">
            Thời gian giữ mã: <span id="ab-countdown">14:59</span>
          </div>
        </div>

        <!-- MÃ GIẢM GIÁ VOUCHER -->
        <div style="margin-bottom: 16px; background: #f8fafc; padding: 12px 14px; border-radius: 12px; border: 1px dashed #cbd5e1;">
          <div style="display: flex; gap: 8px;">
            <input type="text" id="ab-coupon-input" placeholder="Mã giảm giá (ví dụ: WELCOME10)" style="flex: 1; padding: 8px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 0.88rem; text-transform: uppercase; font-family: monospace; font-weight: 700;" />
            <button type="button" id="ab-coupon-btn" style="padding: 8px 14px; background: #0284c7; color: #fff; border: none; border-radius: 8px; font-size: 0.85rem; font-weight: 700; cursor: pointer; white-space: nowrap;">Áp dụng</button>
          </div>
          <div id="ab-coupon-msg" style="margin-top: 6px; font-size: 0.82rem; font-weight: 600; display: none;"></div>
        </div>

        <div class="ab-info-grid">
          <div class="ab-info-row">
            <span class="ab-info-label">Ngân hàng:</span>
            <span class="ab-info-val">${BANK_ID}</span>
          </div>
          <div class="ab-info-row">
            <span class="ab-info-label">Số tài khoản:</span>
            <span class="ab-info-val">${ACCOUNT_NO} <button type="button" class="ab-copy-btn" data-copy="${ACCOUNT_NO}">Sao chép</button></span>
          </div>
          <div class="ab-info-row">
            <span class="ab-info-label">Chủ tài khoản:</span>
            <span class="ab-info-val">${ACCOUNT_NAME}</span>
          </div>
          <div class="ab-info-row">
            <span class="ab-info-label">Số tiền:</span>
            <span class="ab-info-val" id="ab-price-val" style="color: #0284c7; font-size: 1.05rem;">${pkg.text} <button type="button" class="ab-copy-btn" data-copy="${pkg.price}">Sao chép</button></span>
          </div>
          <div class="ab-info-row">
            <span class="ab-info-label">Nội dung CK:</span>
            <span class="ab-info-val" style="color: #e11d48; font-weight: 800;">${orderCode} <button type="button" class="ab-copy-btn" data-copy="${orderCode}">Sao chép</button></span>
          </div>
        </div>

        <div class="ab-action-group" style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
          <a href="https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn" class="ab-btn-test" target="_blank" rel="noopener" style="text-align: center; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 6px; font-weight: 700; color: #0284c7;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            Tải App CH Play
          </a>
          <button type="button" class="ab-btn-test" data-copy="${appDeepLink}" style="font-weight: 700;">Sao chép link mở App</button>
        </div>
      `;

      // Handle Coupon Code Validation & Dynamic QR Update
      let currentPrice = pkg.price;
      const couponInput = document.getElementById('ab-coupon-input');
      const couponBtn = document.getElementById('ab-coupon-btn');
      const couponMsg = document.getElementById('ab-coupon-msg');
      const qrImg = document.querySelector('.ab-qr-img');
      const priceVal = document.getElementById('ab-price-val');

      if (couponBtn && couponInput) {
        couponBtn.onclick = async () => {
          const code = couponInput.value.trim().toUpperCase();
          if (!code) {
            couponMsg.style.display = 'block';
            couponMsg.style.color = '#ef4444';
            couponMsg.textContent = 'Vui lòng nhập mã giảm giá!';
            return;
          }
          couponBtn.disabled = true;
          couponBtn.textContent = '...';
          try {
            const res = await fetch(`${API_BASE}/admin/coupons/validate`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ code, amount: pkg.price }),
            });
            const data = await res.json();
            if (res.ok && data.valid) {
              currentPrice = data.finalAmount;
              couponMsg.style.display = 'block';
              couponMsg.style.color = '#16a34a';
              couponMsg.textContent = `✓ Đã áp dụng mã "${data.code}": Giảm ${Number(data.discount).toLocaleString('vi-VN')}đ!`;
              const updatedQr = `https://img.vietqr.io/image/${BANK_ID}-${ACCOUNT_NO}-compact2.png?amount=${currentPrice}&addInfo=${orderCode}&accountName=${encodeURIComponent(ACCOUNT_NAME)}`;
              if (qrImg) qrImg.src = updatedQr;
              if (priceVal) {
                priceVal.innerHTML = `<span style="text-decoration: line-through; color: #94a3b8; font-size: 0.9rem; margin-right: 6px;">${pkg.text}</span> ${currentPrice.toLocaleString('vi-VN')}đ <button type="button" class="ab-copy-btn" data-copy="${currentPrice}">Sao chép</button>`;
              }
            } else {
              couponMsg.style.display = 'block';
              couponMsg.style.color = '#ef4444';
              couponMsg.textContent = data.message || 'Mã giảm giá không hợp lệ hoặc đã hết hạn.';
            }
          } catch (_) {
            couponMsg.style.display = 'block';
            couponMsg.style.color = '#ef4444';
            couponMsg.textContent = 'Lỗi kết nối máy chủ khi kiểm tra mã.';
          } finally {
            couponBtn.disabled = false;
            couponBtn.textContent = 'Áp dụng';
          }
        };
      }

      // Auto-trigger deep link on mobile devices
      if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        setTimeout(() => {
          window.location.href = appDeepLink;
        }, 500);
      }
  }

  function showSuccess(pkg, orderCode) {
    clearInterval(activePollInterval);
    clearInterval(countdownTimer);

    // Update status to paid in localStorage
    try {
      const orders = JSON.parse(localStorage.getItem('autobank_orders_list') || '[]');
      const target = orders.find(x => x.code === orderCode);
      if (target) {
        target.status = 'paid';
        localStorage.setItem('autobank_orders_list', JSON.stringify(orders));
      }
    } catch (_) {}

    const bodyEl = document.getElementById('ab-modal-body');
    if (!bodyEl) return;

    bodyEl.innerHTML = `
      <div class="ab-success-card">
        <div class="ab-success-icon" style="background: #0f172a; color: #ffffff;">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
        </div>
        <h4 style="font-size: 1.35rem; font-weight: 800; color: #166534; margin-bottom: 8px;">Thanh toán thành công!</h4>
        <p style="color: #475569; font-size: 0.95rem; line-height: 1.6; margin-bottom: 20px;">
          Hệ thống AutoBank đã nhận thành công <strong>${pkg.text}</strong> cho mã đơn <strong>${orderCode}</strong>.<br>
          Gói <strong>${pkg.name}</strong> đã được kích hoạt trên hệ thống!
        </p>
        <div style="background: #f1f5f9; padding: 14px; border-radius: 12px; margin-bottom: 24px; font-size: 0.88rem; color: #475569;">
          Mở ứng dụng <strong>Báo chuyển tiền</strong> trên điện thoại để đồng bộ hạn sử dụng ngay lập tức.
        </div>
        <button type="button" class="main-btn btn-hover" id="ab-btn-done" style="width: 100%; border-radius: 12px; padding: 14px;">Hoàn tất</button>
      </div>
    `;

    document.getElementById('ab-btn-done').addEventListener('click', closeModal);
  }

  function closeModal() {
    clearInterval(activePollInterval);
    clearInterval(countdownTimer);
    const modal = document.getElementById('autobank-payment-modal');
    if (modal) modal.classList.remove('is-open');
    document.body.classList.remove('seo-lightbox-open');
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const modal = document.getElementById('autobank-payment-modal');
      if (modal && modal.classList.contains('is-open')) {
        closeModal();
      }
    }
  });

  // Listen to cross-tab & reactive events
  window.addEventListener('autobank_config_updated', refreshConfigFromAdmin);
  window.addEventListener('storage', (e) => {
    if (e.key === 'autobank_system_config') refreshConfigFromAdmin();
  });
  try {
    const channel = new BroadcastChannel('autobank_live_channel');
    channel.onmessage = (e) => {
      if (e.data && e.data.type === 'CONFIG_UPDATED') refreshConfigFromAdmin();
    };
  } catch (_) {}

  // Bind to pricing buttons
  function attachPricingButtons() {
    const pricingButtons = document.querySelectorAll('#pricing .price-btn, #pricing a[data-package]');
    pricingButtons.forEach((btn, index) => {
      if (btn.dataset.paymentBound) return;
      btn.dataset.paymentBound = 'true';
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const pkgKey = btn.getAttribute('data-package');
        const defaultKeys = ['trial', '1month', '3month', '6month', '9month', '1year'];
        openModal(pkgKey || defaultKeys[index] || '1year');
      });
    });
  }

  window.attachPricingButtons = attachPricingButtons;
  window.autobankPaymentModal = { open: openModal, attachPricingButtons };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', attachPricingButtons);
  } else {
    attachPricingButtons();
  }
})();
