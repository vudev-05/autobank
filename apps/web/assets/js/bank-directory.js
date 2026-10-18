import { BANKS_DATA as DEFAULT_BANKS, BANK_CATEGORIES } from '../data/banks-data.js';

function getActiveBanks() {
  try {
    const saved = localStorage.getItem('autobank_banks_custom');
    if (saved) {
      const parsed = JSON.parse(saved);
      if (Array.isArray(parsed) && parsed.length > 0) {
        return parsed.filter(b => b.status !== 'disabled');
      }
    }
  } catch (e) {
    console.warn('Cannot read autobank_banks_custom', e);
  }
  return DEFAULT_BANKS;
}

export function initBankDirectory() {
  const container = document.getElementById('ab-bank-grid');
  const searchInput = document.getElementById('ab-bank-search');
  const countBadge = document.getElementById('ab-bank-count');
  const filterTabs = document.querySelectorAll('[data-bank-tab]');

  if (!container) return;

  let currentBanks = getActiveBanks();
  let currentCategory = BANK_CATEGORIES.ALL;
  let currentQuery = '';

  const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:3000';
  fetch(`${API_BASE}/admin/banks`)
    .then(res => res.json())
    .then(list => {
      if (Array.isArray(list) && list.length > 0) {
        currentBanks = list.filter(b => b.isActive !== false);
        render();
      }
    })
    .catch(() => {});


  function getCategoryLabel(cat) {
    switch (cat) {
      case BANK_CATEGORIES.COMMERCIAL: return 'Thương mại';
      case BANK_CATEGORIES.NEOBANK: return 'Ngân hàng số';
      case BANK_CATEGORIES.EWALLET: return 'Ví điện tử';
      case BANK_CATEGORIES.BUSINESS: return 'Doanh nghiệp';
      default: return 'Ngân hàng';
    }
  }

  function getCategoryColor(cat) {
    switch (cat) {
      case BANK_CATEGORIES.NEOBANK: return 'badge-neobank';
      case BANK_CATEGORIES.EWALLET: return 'badge-ewallet';
      case BANK_CATEGORIES.BUSINESS: return 'badge-business';
      default: return 'badge-commercial';
    }
  }

  function render() {
    const q = currentQuery.trim().toLowerCase();
    const filtered = currentBanks.filter(bank => {
      const matchCat = (currentCategory === BANK_CATEGORIES.ALL) || (bank.category === currentCategory);
      if (!matchCat) return false;
      if (!q) return true;
      return (
        bank.name.toLowerCase().includes(q) ||
        bank.app.toLowerCase().includes(q) ||
        bank.code.toLowerCase().includes(q) ||
        bank.pkg.toLowerCase().includes(q)
      );
    });

    if (countBadge) {
      countBadge.textContent = `Hiển thị ${filtered.length} / ${currentBanks.length} ứng dụng`;
    }

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="ab-bank-empty">
          <div style="display: flex; justify-content: center; margin-bottom: 14px;">
            <span style="display: inline-flex; align-items: center; justify-content: center; width: 56px; height: 56px; border-radius: 16px; background: #0f172a; color: #ffffff;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
            </span>
          </div>
          <h4 style="font-size: 1.15rem; font-weight: 700; color: #0f172a; margin-bottom: 6px;">Không tìm thấy kết quả phù hợp</h4>
          <p style="color: #64748b; font-size: 0.9rem;">Thử tìm theo từ khóa khác hoặc bấm nút "Tất cả".</p>
        </div>
      `;
      return;
    }

    container.innerHTML = filtered.map(bank => `
      <div class="ab-bank-card" data-bank-id="${bank.id}">
        <div class="ab-bank-card__top">
          <div class="ab-bank-card__logo-wrap">
            <img
              src="${bank.logo}"
              alt="${bank.name}"
              class="ab-bank-card__logo"
              loading="lazy"
              onerror="this.onerror=null;this.src='https://cdn.vietqr.io/img/VCB.png'"
            />
          </div>
          <span class="ab-bank-card__tag ${getCategoryColor(bank.category)}">
            ${getCategoryLabel(bank.category)}
          </span>
        </div>
        <div class="ab-bank-card__info">
          <h4 class="ab-bank-card__name">${bank.name}</h4>
          <span class="ab-bank-card__app">Ứng dụng: <strong>${bank.app}</strong></span>
        </div>
        <button type="button" class="ab-bank-card__btn" data-guide-id="${bank.id}">
          Hướng dẫn cài đặt &rsaquo;
        </button>
      </div>
    `).join('');

    // Attach click for guide modal
    container.querySelectorAll('[data-guide-id]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = btn.getAttribute('data-guide-id');
        const b = currentBanks.find(x => x.id === id);
        if (b) openGuideModal(b);
      });
    });

    container.querySelectorAll('.ab-bank-card').forEach(card => {
      card.addEventListener('click', () => {
        const id = card.getAttribute('data-bank-id');
        const b = currentBanks.find(x => x.id === id);
        if (b) openGuideModal(b);
      });
    });
  }

  // Filter Tabs
  filterTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      filterTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentCategory = tab.getAttribute('data-bank-tab');
      render();
    });
  });

  // Search input
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      currentQuery = e.target.value;
      render();
    });
  }

  // Guide Modal
  function openGuideModal(bank) {
    let guideModal = document.getElementById('ab-guide-modal');
    if (!guideModal) {
      const html = `
        <div id="ab-guide-modal" class="ab-modal" aria-hidden="true" role="dialog">
          <div class="ab-modal-backdrop" id="ab-guide-backdrop"></div>
          <div class="ab-modal-dialog">
            <div class="ab-modal-header">
              <div style="display: flex; align-items: center; gap: 14px;">
                <img id="ab-guide-logo" src="" alt="" style="width: 48px; height: 48px; border-radius: 12px; padding: 4px; background: #f8fafc; border: 1px solid #e2e8f0; object-fit: contain;" />
                <div>
                  <h3 class="ab-modal-title" id="ab-guide-title">Hướng dẫn cài đặt</h3>
                  <span id="ab-guide-subtitle" style="font-size: 0.85rem; color: #64748b; font-weight: 600;"></span>
                </div>
              </div>
              <button type="button" class="ab-modal-close" id="ab-guide-close">&times;</button>
            </div>
            <div class="ab-modal-body" id="ab-guide-body"></div>
          </div>
        </div>
      `;
      document.body.insertAdjacentHTML('beforeend', html);
      guideModal = document.getElementById('ab-guide-modal');

      const closeGuide = () => {
        guideModal.classList.remove('is-open');
        document.body.classList.remove('seo-lightbox-open');
      };

      document.getElementById('ab-guide-close').addEventListener('click', closeGuide);
      document.getElementById('ab-guide-backdrop').addEventListener('click', closeGuide);
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && guideModal.classList.contains('is-open')) {
          closeGuide();
        }
      });
    }

    document.getElementById('ab-guide-logo').src = bank.logo;
    document.getElementById('ab-guide-title').textContent = bank.name;
    document.getElementById('ab-guide-subtitle').textContent = `Ứng dụng: ${bank.app} (Gói: ${bank.pkg})`;

    document.getElementById('ab-guide-body').innerHTML = `
      <div style="background: #f8fafc; border: 1px solid #e2e8f0; padding: 14px 18px; border-radius: 14px; margin-bottom: 20px;">
        <strong style="color: #0f172a; font-size: 0.95rem; display: flex; align-items: center; gap: 6px; margin-bottom: 4px;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
          Đã kiểm thử tương thích 100%
        </strong>
        <p style="color: #475569; font-size: 0.88rem; margin: 0; line-height: 1.5;">
          Hệ thống <strong>Đọc thông báo nhận tiền</strong> đọc trực tiếp thông báo push của ${bank.name} ngay khi tiền về, không cần API ngân hàng, không lo lộ mật khẩu.
        </p>
      </div>

      <div style="display: flex; flex-direction: column; gap: 14px; margin-bottom: 24px;">
        <div style="display: flex; gap: 12px; align-items: flex-start;">
          <span style="display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; border-radius: 8px; background: #0f172a; color: #fff; font-weight: 800; font-size: 0.85rem; flex-shrink: 0;">1</span>
          <div>
            <strong style="color: #0f172a; font-size: 0.92rem; display: block;">Bật thông báo trong ${bank.app}:</strong>
            <p style="color: #475569; font-size: 0.88rem; margin: 4px 0 0; line-height: 1.5;">${bank.guide}</p>
          </div>
        </div>

        <div style="display: flex; gap: 12px; align-items: flex-start;">
          <span style="display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; border-radius: 8px; background: #0f172a; color: #fff; font-weight: 800; font-size: 0.85rem; flex-shrink: 0;">2</span>
          <div>
            <strong style="color: #0f172a; font-size: 0.92rem; display: block;">Cấp quyền Truy cập thông báo:</strong>
            <p style="color: #475569; font-size: 0.88rem; margin: 4px 0 0; line-height: 1.5;">Mở app Đọc thông báo nhận tiền → Bấm Cài đặt → Cho phép ứng dụng lắng nghe thông báo trên Android.</p>
          </div>
        </div>

        <div style="display: flex; gap: 12px; align-items: flex-start;">
          <span style="display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; border-radius: 8px; background: #0f172a; color: #fff; font-weight: 800; font-size: 0.85rem; flex-shrink: 0;">3</span>
          <div>
            <strong style="color: #0f172a; font-size: 0.92rem; display: block;">Bỏ hạn chế pin & Tự khởi chạy:</strong>
            <p style="color: #475569; font-size: 0.88rem; margin: 4px 0 0; line-height: 1.5;">Vào Cài đặt máy (Xiaomi, Samsung, Oppo...) → Đọc thông báo nhận tiền → Tiết kiệm pin chọn "Không hạn chế" để không bao giờ bị tắt ngầm khi khóa màn hình.</p>
          </div>
        </div>
      </div>

      <a href="https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn" class="main-btn btn-hover" target="_blank" rel="noopener" style="display: inline-flex; align-items: center; justify-content: center; gap: 8px; width: 100%; text-align: center; border-radius: 12px; padding: 14px; font-weight: 700; background: #0f172a; color: #fff;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        Tải App "Đọc Thông Báo Nhận Tiền" trên Google Play
      </a>
    `;

    guideModal.classList.add('is-open');
    document.body.classList.add('seo-lightbox-open');
  }

  // Initial render
  render();
}
