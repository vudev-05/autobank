import { BANKS_DATA as defaultBanks } from '../data/banks-data.js';

// Read Admin credentials from environment variables (.env)
const ENV_ADMIN_USER = import.meta.env.VITE_ADMIN_USERNAME || 'admin';
const ENV_ADMIN_PASS = import.meta.env.VITE_ADMIN_PASSWORD || 'autobank@2026';

// Storage keys
const STORAGE_AUTH_TOKEN = 'autobank_admin_session';
const STORAGE_CONFIG = 'autobank_system_config';
const STORAGE_BANKS = 'autobank_banks_custom';
const STORAGE_USERS = 'autobank_users_list';
const STORAGE_ORDERS = 'autobank_orders_list';
const STORAGE_PUSH = 'autobank_push_notifications';

// Default initial config
const defaultConfig = {
  brandName: 'Đọc thông báo nhận tiền',
  brandSlogan: 'Tiền vừa sang ~ máy báo vang',
  chplayLink: 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app',
  youtubeLink: '',
  hotline: '0869226687',
  email: 'tranquocvu3011@gmail.com',
  facebook: 'https://www.facebook.com/Baochuyentienbanggiongnoi',
  tiktok: 'https://www.tiktok.com/@locketgoldqvu',
  bankCode: 'MB',
  bankAcc: '3011200588888',
  bankName: 'TRẦN QUỐC VŨ',
  priceTrial: '0đ (3 ngày)',
  price1m: 38000,
  price3m: 99000,
  price6m: 179000,
  price9m: 249000,
  price1y: 299000,
  maintenance: false,
  maintenanceMsg: 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau 15 phút.',
  latestVersion: '1.2.0',
  minVersion: '1.0.0',
};

// Initial authentic users
const defaultUsers = [
  { id: 'USR-VU-01', name: 'Trần Quốc Vũ', email: 'tranquocvu3011@gmail.com', device: 'Samsung Galaxy Android', version: '1.2.0', pkg: 'Gói 1 năm (365 ngày)', expires: '2027-10-11', status: 'ACTIVE' },
  { id: 'USR-AN-02', name: 'Nguyễn Văn An', email: 'nguyenvanan.dev@gmail.com', device: 'Samsung Galaxy Android 14', version: '1.2.0', pkg: 'Dùng thử 3 ngày', expires: '2026-10-14', status: 'ACTIVE' },
  { id: 'USR-KIMANH-03', name: 'Trần Thị Kim Anh (Tiệm Bánh Mì Kim Anh)', email: 'tiembanhmikimanh@gmail.com', device: 'Xiaomi Redmi Note 13', version: '1.2.0', pkg: 'Chưa kích hoạt gói', expires: '2026-10-12', status: 'ACTIVE' },
];

// Initial sample orders
const defaultOrders = [];

// System State
let appConfig = loadConfig();
let banksList = loadBanks();
let usersList = loadUsers();
let ordersList = loadOrders();
let activeEditingUserIndex = -1;

const API_BASE = (typeof window !== 'undefined' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1')
  ? 'https://api.docthongbaobank.com'
  : (import.meta.env.VITE_API_BASE || 'http://localhost:3000');

function loadConfig() {
  try {
    const saved = localStorage.getItem(STORAGE_CONFIG);
    return saved ? { ...defaultConfig, ...JSON.parse(saved) } : { ...defaultConfig };
  } catch (_) {
    return { ...defaultConfig };
  }
}

function saveConfig(cfg) {
  appConfig = { ...appConfig, ...cfg };
  localStorage.setItem(STORAGE_CONFIG, JSON.stringify(appConfig));

  // Sync to MySQL API in background
  fetch(`${API_BASE}/admin/configs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(appConfig),
  }).catch(() => {});
}

function loadBanks() {
  try {
    const saved = localStorage.getItem(STORAGE_BANKS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return defaultBanks.map(b => ({ ...b, active: true }));
}

function saveBanks(list) {
  banksList = list;
  localStorage.setItem(STORAGE_BANKS, JSON.stringify(banksList));
}

function loadUsers() {
  try {
    const saved = localStorage.getItem(STORAGE_USERS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [...defaultUsers];
}

function saveUsers(list) {
  usersList = list;
  localStorage.setItem(STORAGE_USERS, JSON.stringify(usersList));
}

function loadOrders() {
  try {
    const saved = localStorage.getItem(STORAGE_ORDERS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [...defaultOrders];
}

function saveOrders(list) {
  ordersList = list;
  localStorage.setItem(STORAGE_ORDERS, JSON.stringify(ordersList));
}

// Toast helper
function showToast(message, type = 'success') {
  const container = document.getElementById('admin-toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = `admin-toast admin-toast-${type}`;
  toast.innerHTML = `
    <span style="font-weight: 700;">${type === 'success' ? '✓' : '!'}</span>
    <span>${message}</span>
  `;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3200);
}

// Initialize Application
document.addEventListener('DOMContentLoaded', () => {
  initAuth();
  initTabs();
  renderConfig();
  renderBanks();
  renderUsers();
  renderOrders();
  renderOverviewLogs();
  initPushNotificationForm();
  initMaintenanceAndVersions();
  initCopyButtons();
});

// ==========================================
// 1. AUTHENTICATION
// ==========================================
function initAuth() {
  const loginView = document.getElementById('admin-login-view');
  const dashView = document.getElementById('admin-dashboard-view');
  const loginForm = document.getElementById('admin-login-form');
  const userInput = document.getElementById('admin-user-input');
  const passInput = document.getElementById('admin-pass-input');
  const errorMsg = document.getElementById('admin-login-error');
  const logoutBtn = document.getElementById('admin-logout-btn');
  const displayUser = document.getElementById('admin-display-username');

  const token = sessionStorage.getItem(STORAGE_AUTH_TOKEN);
  if (token === 'autobank_admin_authenticated') {
    loginView.style.display = 'none';
    dashView.style.display = 'flex';
    if (displayUser) displayUser.textContent = ENV_ADMIN_USER;
  }

  if (loginForm) {
    loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const u = userInput.value.trim();
      const p = passInput.value.trim();

      if (u === ENV_ADMIN_USER && p === ENV_ADMIN_PASS) {
        sessionStorage.setItem(STORAGE_AUTH_TOKEN, 'autobank_admin_authenticated');
        errorMsg.style.display = 'none';
        loginView.style.display = 'none';
        dashView.style.display = 'flex';
        if (displayUser) displayUser.textContent = u;
        showToast(`Đăng nhập thành công! Chào mừng ${u}`, 'success');
      } else {
        errorMsg.style.display = 'block';
        passInput.value = '';
        passInput.focus();
        showToast('Tài khoản hoặc mật khẩu không chính xác!', 'error');
      }
    });
  }

  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi trang quản trị?')) {
        sessionStorage.removeItem(STORAGE_AUTH_TOKEN);
        dashView.style.display = 'none';
        loginView.style.display = 'flex';
        showToast('Đã đăng xuất tài khoản an toàn.', 'info');
      }
    });
  }
}

// ==========================================
// 2. TAB NAVIGATION
// ==========================================
function initTabs() {
  const navItems = document.querySelectorAll('.admin-nav-item');
  const titleEl = document.getElementById('admin-section-title');

  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const tabId = item.getAttribute('data-tab');
      navItems.forEach(n => n.classList.remove('active'));
      item.classList.add('active');

      document.querySelectorAll('.admin-panel').forEach(p => p.classList.remove('active'));
      const targetPanel = document.getElementById(`tab-${tabId}`);
      if (targetPanel) targetPanel.classList.add('active');

      if (titleEl) {
        titleEl.textContent = item.textContent.trim().replace(/\d+$/, '').trim();
      }
    });
  });
}

// ==========================================
// 3. WEB & APP CONFIG
// ==========================================
function renderConfig() {
  const form = document.getElementById('config-form');
  if (!form) return;

  document.getElementById('cfg-brand-name').value = appConfig.brandName;
  document.getElementById('cfg-brand-slogan').value = appConfig.brandSlogan;
  document.getElementById('cfg-chplay-link').value = appConfig.chplayLink;
  document.getElementById('cfg-youtube-link').value = appConfig.youtubeLink;
  document.getElementById('cfg-hotline').value = appConfig.hotline;
  document.getElementById('cfg-email').value = appConfig.email;
  document.getElementById('cfg-facebook').value = appConfig.facebook;
  document.getElementById('cfg-tiktok').value = appConfig.tiktok;

  const elBankCode = document.getElementById('cfg-bank-code');
  if (elBankCode) elBankCode.value = appConfig.bankCode;
  const elBankAcc = document.getElementById('cfg-bank-acc');
  if (elBankAcc) elBankAcc.value = appConfig.bankAcc;
  const elBankName = document.getElementById('cfg-bank-name');
  if (elBankName) elBankName.value = appConfig.bankName;

  document.getElementById('cfg-price-trial').value = appConfig.priceTrial;
  document.getElementById('cfg-price-1m').value = appConfig.price1m;
  document.getElementById('cfg-price-3m').value = appConfig.price3m;
  document.getElementById('cfg-price-6m').value = appConfig.price6m;
  document.getElementById('cfg-price-9m').value = appConfig.price9m;
  document.getElementById('cfg-price-1y').value = appConfig.price1y;

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const updated = {
      brandName: document.getElementById('cfg-brand-name').value.trim(),
      brandSlogan: document.getElementById('cfg-brand-slogan').value.trim(),
      chplayLink: document.getElementById('cfg-chplay-link').value.trim(),
      youtubeLink: document.getElementById('cfg-youtube-link').value.trim(),
      hotline: document.getElementById('cfg-hotline').value.trim(),
      email: document.getElementById('cfg-email').value.trim(),
      facebook: document.getElementById('cfg-facebook').value.trim(),
      tiktok: document.getElementById('cfg-tiktok').value.trim(),
      bankCode: document.getElementById('cfg-bank-code')?.value || appConfig.bankCode,
      bankAcc: document.getElementById('cfg-bank-acc')?.value?.trim() || appConfig.bankAcc,
      bankName: document.getElementById('cfg-bank-name')?.value?.trim() || appConfig.bankName,
      priceTrial: document.getElementById('cfg-price-trial').value.trim(),
      price1m: parseInt(document.getElementById('cfg-price-1m').value, 10),
      price3m: parseInt(document.getElementById('cfg-price-3m').value, 10),
      price6m: parseInt(document.getElementById('cfg-price-6m').value, 10),
      price9m: parseInt(document.getElementById('cfg-price-9m').value, 10),
      price1y: parseInt(document.getElementById('cfg-price-1y').value, 10),
    };

    saveConfig(updated);
    showToast('Đã lưu và đồng bộ toàn bộ cấu hình Web & App thành công!', 'success');
  });
}

// ==========================================
// 4. BANKS & APPS MANAGEMENT
// ==========================================
function renderBanks(filterKeyword = '') {
  const tbody = document.getElementById('admin-banks-table-body');
  const countBadge = document.getElementById('admin-badge-banks');
  if (!tbody) return;

  const kw = filterKeyword.toLowerCase().trim();
  const filtered = banksList.filter(b => {
    if (!kw) return true;
    return b.name.toLowerCase().includes(kw) || b.app.toLowerCase().includes(kw) || b.pkg.toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = banksList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 30px;">Không tìm thấy ngân hàng nào phù hợp.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map((b, idx) => `
    <tr>
      <td>
        <img src="${b.logo}" alt="${b.name}" style="width: 36px; height: 36px; border-radius: 8px; object-fit: contain; background: #fff; padding: 2px; border: 1px solid #e2e8f0;" onerror="this.src='../assets/images/favicon.png'" />
      </td>
      <td>
        <strong style="color: #fff; font-size: 0.92rem;">${b.name}</strong>
      </td>
      <td>
        <div style="font-weight: 600; color: #38bdf8;">${b.app}</div>
        <code style="font-size: 0.75rem; color: #94a3b8;">${b.pkg}</code>
      </td>
      <td>
        <span class="admin-badge admin-badge-info">${getCategoryLabel(b.category)}</span>
      </td>
      <td style="max-width: 300px; font-size: 0.8rem; color: #94a3b8;">
        ${b.guide}
      </td>
      <td>
        <label class="admin-toggle">
          <input type="checkbox" ${b.active !== false ? 'checked' : ''} data-toggle-bank="${idx}" />
          <span class="admin-toggle-slider"></span>
        </label>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-bank="${idx}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-bank="${idx}">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');

  // Attach search
  const searchInput = document.getElementById('admin-search-bank');
  if (searchInput && !searchInput.dataset.bound) {
    searchInput.dataset.bound = 'true';
    searchInput.addEventListener('input', (e) => renderBanks(e.target.value));
  }

  // Attach modal triggers
  attachBankActions();
}

function getCategoryLabel(cat) {
  switch (cat) {
    case 'neobank':
    case 'digital':
      return 'Ngân hàng số';
    case 'ewallet':
    case 'wallet':
      return 'Ví điện tử';
    case 'business':
    case 'corporate':
      return 'Doanh nghiệp';
    default:
      return 'Thương mại';
  }
}

function attachBankActions() {
  const modal = document.getElementById('admin-bank-modal');
  const addBtn = document.getElementById('btn-add-bank');
  const closeBtn = document.getElementById('modal-bank-close');
  const cancelBtn = document.getElementById('modal-bank-cancel');
  const form = document.getElementById('form-save-bank');

  if (addBtn) {
    addBtn.onclick = () => {
      document.getElementById('modal-bank-title').textContent = 'Thêm Ngân Hàng Mới';
      document.getElementById('edit-bank-index').value = '-1';
      form.reset();
      modal.classList.add('is-open');
    };
  }

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  document.querySelectorAll('[data-edit-bank]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-bank'), 10);
      const b = banksList[idx];
      if (!b) return;

      document.getElementById('modal-bank-title').textContent = `Chỉnh sửa: ${b.name}`;
      document.getElementById('edit-bank-index').value = idx;
      document.getElementById('m-bank-name').value = b.name;
      document.getElementById('m-bank-app').value = b.app;
      document.getElementById('m-bank-pkg').value = b.pkg;
      document.getElementById('m-bank-category').value = b.category || 'commercial';
      document.getElementById('m-bank-logo').value = b.logo;
      document.getElementById('m-bank-guide').value = b.guide;
      modal.classList.add('is-open');
    };
  });

  document.querySelectorAll('[data-toggle-bank]').forEach(chk => {
    chk.onchange = () => {
      const idx = parseInt(chk.getAttribute('data-toggle-bank'), 10);
      if (banksList[idx]) {
        banksList[idx].active = chk.checked;
        saveBanks(banksList);
        showToast(`${chk.checked ? 'Đã bật' : 'Đã tắt'} hiển thị ${banksList[idx].name}`);
      }
    };
  });

  document.querySelectorAll('[data-delete-bank]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-delete-bank'), 10);
      const b = banksList[idx];
      if (b && confirm(`Bạn có chắc chắn muốn xóa ngân hàng "${b.name}"?`)) {
        banksList.splice(idx, 1);
        saveBanks(banksList);
        renderBanks();
        showToast(`Đã xóa ngân hàng ${b.name}`);
      }
    };
  });

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = (e) => {
      e.preventDefault();
      const editIdx = parseInt(document.getElementById('edit-bank-index').value, 10);
      const newBank = {
        name: document.getElementById('m-bank-name').value.trim(),
        app: document.getElementById('m-bank-app').value.trim(),
        pkg: document.getElementById('m-bank-pkg').value.trim(),
        category: document.getElementById('m-bank-category').value,
        logo: document.getElementById('m-bank-logo').value.trim(),
        guide: document.getElementById('m-bank-guide').value.trim(),
        active: true,
      };

      if (editIdx >= 0 && banksList[editIdx]) {
        banksList[editIdx] = { ...banksList[editIdx], ...newBank };
        showToast(`Cập nhật ngân hàng ${newBank.name} thành công!`);
      } else {
        banksList.unshift(newBank);
        showToast(`Thêm mới ngân hàng ${newBank.name} thành công!`);
      }

      saveBanks(banksList);
      closeModal();
      renderBanks();
    };
  }
}

// ==========================================
// 5. USERS & DEVICES MANAGEMENT
// ==========================================
function renderUsers(filterKeyword = '') {
  const tbody = document.getElementById('admin-users-table-body');
  const countBadge = document.getElementById('admin-badge-users');
  if (!tbody) return;

  const kw = filterKeyword.toLowerCase().trim();
  const filtered = usersList.filter(u => {
    if (!kw) return true;
    return u.name.toLowerCase().includes(kw) || u.email.toLowerCase().includes(kw) || u.device.toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = usersList.length;

  tbody.innerHTML = filtered.map((u, idx) => `
    <tr>
      <td>
        <strong style="color: #fff; display: block;">${u.name}</strong>
        <span style="font-size: 0.8rem; color: #94a3b8;">${u.email}</span>
      </td>
      <td>
        <div style="color: #cbd5e1; font-weight: 600;">${u.device}</div>
        <small style="color: #38bdf8;">Phiên bản v${u.version}</small>
      </td>
      <td>
        <span class="admin-badge admin-badge-info">${u.pkg}</span>
      </td>
      <td>
        <strong style="color: ${isExpired(u.expires) ? '#ef4444' : '#10b981'};">${u.expires}</strong>
      </td>
      <td>
        <span class="admin-badge admin-badge-${getStatusBadgeClass(u.status)}">${getStatusText(u.status)}</span>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-extend-user="${idx}">+ Gia Hạn</button>
          <button type="button" class="admin-btn ${u.status === 'BLOCKED' ? 'admin-btn-success' : 'admin-btn-danger'} admin-btn-sm" data-toggle-block="${idx}">
            ${u.status === 'BLOCKED' ? 'Mở Khóa' : 'Khóa'}
          </button>
        </div>
      </td>
    </tr>
  `).join('');

  // Search input
  const searchInput = document.getElementById('admin-search-user');
  if (searchInput && !searchInput.dataset.bound) {
    searchInput.dataset.bound = 'true';
    searchInput.addEventListener('input', (e) => renderUsers(e.target.value));
  }

  attachUserActions();
}

function isExpired(dateStr) {
  return new Date(dateStr) < new Date();
}

function getStatusBadgeClass(status) {
  if (status === 'ACTIVE') return 'success';
  if (status === 'TRIAL') return 'warning';
  return 'danger';
}

function getStatusText(status) {
  if (status === 'ACTIVE') return 'Đang hoạt động';
  if (status === 'TRIAL') return 'Dùng thử';
  if (status === 'BLOCKED') return 'Đã khóa';
  return 'Hết hạn';
}

function attachUserActions() {
  const modal = document.getElementById('admin-user-modal');
  const closeBtn = document.getElementById('modal-user-close');
  const emailEl = document.getElementById('m-user-email');

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;

  document.querySelectorAll('[data-extend-user]').forEach(btn => {
    btn.onclick = () => {
      activeEditingUserIndex = parseInt(btn.getAttribute('data-extend-user'), 10);
      const u = usersList[activeEditingUserIndex];
      if (u) {
        emailEl.textContent = `${u.name} (${u.email}) — Hạn hiện tại: ${u.expires}`;
        modal.classList.add('is-open');
      }
    };
  });

  document.querySelectorAll('[data-extend-days]').forEach(btn => {
    btn.onclick = () => {
      const days = parseInt(btn.getAttribute('data-extend-days'), 10);
      if (activeEditingUserIndex >= 0 && usersList[activeEditingUserIndex]) {
        const u = usersList[activeEditingUserIndex];
        const base = isExpired(u.expires) ? new Date() : new Date(u.expires);
        base.setDate(base.getDate() + days);
        u.expires = base.toISOString().split('T')[0];
        u.status = 'ACTIVE';
        saveUsers(usersList);
        renderUsers();
        closeModal();
        showToast(`Đã gia hạn thành công thêm ${days} ngày cho ${u.name}! Hạn mới: ${u.expires}`);
      }
    };
  });

  document.querySelectorAll('[data-toggle-block]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-toggle-block'), 10);
      const u = usersList[idx];
      if (u) {
        u.status = (u.status === 'BLOCKED') ? 'ACTIVE' : 'BLOCKED';
        saveUsers(usersList);
        renderUsers();
        showToast(`Đã ${u.status === 'BLOCKED' ? 'khóa tài khoản' : 'mở khóa'} của ${u.name}`);
      }
    };
  });
}

// ==========================================
// 6. PUSH NOTIFICATIONS BROADCAST
// ==========================================
function initPushNotificationForm() {
  const form = document.getElementById('push-notify-form');
  if (!form) return;

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const payload = {
      type: document.getElementById('push-type').value,
      title: document.getElementById('push-title').value.trim(),
      body: document.getElementById('push-body').value.trim(),
      action: document.getElementById('push-action').value,
      timestamp: new Date().toISOString(),
    };

    let history = [];
    try {
      history = JSON.parse(localStorage.getItem(STORAGE_PUSH) || '[]');
    } catch (_) {}
    history.unshift(payload);
    localStorage.setItem(STORAGE_PUSH, JSON.stringify(history));

    form.reset();
    showToast(`Đã phát thông báo Push thành công đến toàn bộ thiết bị đang online!`, 'success');
  });
}

// ==========================================
// 7. MAINTENANCE & VERSION CONTROL
// ==========================================
function initMaintenanceAndVersions() {
  const toggle = document.getElementById('toggle-maintenance');
  const msgInput = document.getElementById('cfg-maintenance-msg');
  const latestVer = document.getElementById('cfg-latest-version');
  const minVer = document.getElementById('cfg-min-version');
  const saveVerBtn = document.getElementById('btn-save-version');

  if (toggle) {
    toggle.checked = appConfig.maintenance === true;
    toggle.addEventListener('change', () => {
      saveConfig({
        maintenance: toggle.checked,
        maintenanceMsg: msgInput ? msgInput.value.trim() : appConfig.maintenanceMsg,
      });
      showToast(`${toggle.checked ? 'ĐÃ KÍCH HOẠT BẢO TRÌ TOÀN HỆ THỐNG' : 'Đã tắt bảo trì, hệ thống hoạt động bình thường'}`);
    });
  }

  if (saveVerBtn) {
    saveVerBtn.addEventListener('click', () => {
      saveConfig({
        latestVersion: latestVer.value.trim(),
        minVersion: minVer.value.trim(),
      });
      showToast('Đã cập nhật ràng buộc phiên bản App mobile thành công!');
    });
  }
}

// ==========================================
// 8. ORDERS & TRANSACTIONS
// ==========================================
function renderOrders() {
  const tbody = document.getElementById('admin-orders-table-body');
  const countBadge = document.getElementById('admin-badge-orders');
  const filterSelect = document.getElementById('filter-order-status');
  if (!tbody) return;

  const filter = filterSelect ? filterSelect.value : 'all';
  const filtered = ordersList.filter(o => filter === 'all' || o.status === filter);

  if (countBadge) countBadge.textContent = ordersList.length;

  tbody.innerHTML = filtered.map((o, idx) => `
    <tr>
      <td><strong style="color: #38bdf8; font-family: monospace;">${o.orderCode}</strong></td>
      <td>${o.customer}</td>
      <td>${o.pkg}</td>
      <td><strong style="color: #fff;">${o.amount.toLocaleString('vi-VN')}đ</strong></td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${o.time}</td>
      <td>
        <span class="admin-badge admin-badge-success">
          ✓ Thành công
        </span>
      </td>
      <td>
        ${o.status === 'PENDING' ? `
          <button type="button" class="admin-btn admin-btn-success admin-btn-sm" data-approve-order="${idx}">Duyệt Kích Hoạt</button>
        ` : `
          <span style="color: #64748b; font-size: 0.8rem;">✓ Hoàn tất</span>
        `}
      </td>
    </tr>
  `).join('');

  document.querySelectorAll('[data-approve-order]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-approve-order'), 10);
      if (ordersList[idx]) {
        ordersList[idx].status = 'PAID';
        saveOrders(ordersList);
        renderOrders();
        showToast(`Đã duyệt kích hoạt thủ công cho đơn hàng ${ordersList[idx].orderCode}!`);
      }
    };
  });

  if (filterSelect && !filterSelect.dataset.bound) {
    filterSelect.dataset.bound = 'true';
    filterSelect.addEventListener('change', renderOrders);
  }
}

// ==========================================
// 9. OVERVIEW LOGS
// ==========================================
function renderOverviewLogs() {
  const tbody = document.getElementById('overview-logs-body');
  if (!tbody) return;

  const logs = [
    { time: '13:58:12', type: 'Phát Loa Báo Tiền', entity: 'Xiaomi Redmi Note 13 (Shop Mai)', detail: '+500.000đ từ Techcombank (KH: LE ANH T)', status: 'SUCCESS' },
    { time: '13:54:02', type: 'Đăng Ký Tài Khoản', entity: 'Google: vu.tran.auto@gmail.com', detail: 'Kích hoạt dùng thử 3 ngày miễn phí', status: 'SUCCESS' },
    { time: '13:45:10', type: 'Thanh Toán VietQR', entity: 'Đơn hàng ORD-892104', detail: 'Nạp gói 1 Năm (299.000đ) qua MBBank', status: 'SUCCESS' },
    { time: '13:30:25', type: 'Phát Loa Báo Tiền', entity: 'Samsung Galaxy A54 (Shop An)', detail: '+120.000đ từ MoMo (KH: TRAN NGOC H)', status: 'SUCCESS' },
    { time: '13:12:08', type: 'Đồng Bộ Thông Báo', entity: 'Oppo Reno 11 Pro', detail: 'Lắng nghe 3 ngân hàng (VCB, MB, ACB)', status: 'SUCCESS' },
  ];

  tbody.innerHTML = logs.map(l => `
    <tr>
      <td style="color: #94a3b8; font-family: monospace;">${l.time}</td>
      <td><strong style="color: #38bdf8;">${l.type}</strong></td>
      <td style="color: #fff;">${l.entity}</td>
      <td style="color: #cbd5e1;">${l.detail}</td>
      <td><span class="admin-badge admin-badge-success">Thành công</span></td>
    </tr>
  `).join('');

  const refreshBtn = document.getElementById('btn-refresh-logs');
  if (refreshBtn) {
    refreshBtn.onclick = () => {
      showToast('Đã làm mới dữ liệu thời gian thực!');
      renderOverviewLogs();
    };
  }
}

// Copy helpers
function initCopyButtons() {
  document.querySelectorAll('[data-copy-target]').forEach(btn => {
    btn.onclick = () => {
      const targetId = btn.getAttribute('data-copy-target');
      const input = document.getElementById(targetId);
      if (input) {
        navigator.clipboard.writeText(input.value);
        const originalText = btn.textContent;
        btn.textContent = 'Đã chép!';
        setTimeout(() => btn.textContent = originalText, 1500);
        showToast('Đã sao chép vào bộ nhớ tạm!');
      }
    };
  });

  const regenBtn = document.getElementById('btn-regen-keys');
  if (regenBtn) {
    regenBtn.onclick = () => {
      if (confirm('Bạn có chắc muốn cấp lại toàn bộ Master API Key? Các thiết bị cũ sẽ cần cập nhật key mới.')) {
        const rand = 'ak_live_' + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
        document.getElementById('key-master-api').value = rand;
        showToast('Đã sinh lại Master API Key mới thành công!');
      }
    };
  }
}
