import { BANKS_DATA as defaultBanks } from '../data/banks-data.js';

// Environment variables
export const ENV_ADMIN_USER = import.meta.env.VITE_ADMIN_USERNAME || 'admin';
export const ENV_ADMIN_PASS = import.meta.env.VITE_ADMIN_PASSWORD || 'autobank@2026';
export const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:3000';

// Storage keys
export const STORAGE_AUTH_TOKEN = 'autobank_admin_session';
export const STORAGE_CONFIG = 'autobank_system_config';
export const STORAGE_BANKS = 'autobank_banks_custom';
export const STORAGE_USERS = 'autobank_users_list';
export const STORAGE_ORDERS = 'autobank_orders_list';
export const STORAGE_PUSH = 'autobank_push_notifications';

// Default initial config
export const defaultConfig = {
  brandName: 'Đọc thông báo nhận tiền',
  brandSlogan: 'Tiền vừa sang ~ máy báo vang',
  chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
  youtubeLink: 'https://www.youtube.com/@vudev05',
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

export const defaultUsers = [
  { id: 'USR-VU-01', name: 'Trần Quốc Vũ', email: 'tranquocvu3011@gmail.com', device: 'Samsung Galaxy Android', version: '1.2.0', pkg: 'Gói 1 năm (365 ngày)', expires: '2027-10-11', status: 'ACTIVE' },
  { id: 'USR-AN-02', name: 'Nguyễn Văn An', email: 'nguyenvanan.dev@gmail.com', device: 'Samsung Galaxy Android 14', version: '1.2.0', pkg: 'Dùng thử 3 ngày', expires: '2026-10-14', status: 'ACTIVE' },
  { id: 'USR-KIMANH-03', name: 'Trần Thị Kim Anh (Tiệm Bánh Mì Kim Anh)', email: 'tiembanhmikimanh@gmail.com', device: 'Xiaomi Redmi Note 13', version: '1.2.0', pkg: 'Chưa kích hoạt gói', expires: '2026-10-12', status: 'ACTIVE' },
];

export const defaultOrders = [];

// Auth Guard
export function checkAuth() {
  const token = sessionStorage.getItem(STORAGE_AUTH_TOKEN);
  if (token !== 'autobank_admin_authenticated') {
    window.location.href = 'login.html';
    return false;
  }
  return true;
}

// Sidebar Setup
export function initSidebar(activePageKey = 'overview') {
  const links = document.querySelectorAll('.admin-nav-item');
  links.forEach(a => {
    if (a.getAttribute('data-page') === activePageKey) {
      a.classList.add('active');
    } else {
      a.classList.remove('active');
    }
  });

  // Display username
  const userEl = document.getElementById('admin-display-username');
  if (userEl) userEl.textContent = ENV_ADMIN_USER;

  // Setup Mobile Off-canvas Drawer Toggle & Overlay
  let overlay = document.querySelector('.admin-sidebar-overlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.className = 'admin-sidebar-overlay';
    document.body.appendChild(overlay);
  }
  overlay.onclick = () => document.body.classList.remove('sidebar-open');

  const brand = document.querySelector('.admin-sidebar-brand');
  if (brand && !document.getElementById('admin-sidebar-close')) {
    const closeBtn = document.createElement('button');
    closeBtn.id = 'admin-sidebar-close';
    closeBtn.className = 'admin-sidebar-close';
    closeBtn.type = 'button';
    closeBtn.title = 'Đóng Menu Quản Trị';
    closeBtn.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>';
    closeBtn.onclick = () => document.body.classList.remove('sidebar-open');
    brand.appendChild(closeBtn);
  }

  // Ensure hamburger toggle button exists in topbar
  const topbar = document.querySelector('.admin-topbar');
  if (topbar && !document.getElementById('admin-menu-toggle')) {
    const toggleBtn = document.createElement('button');
    toggleBtn.id = 'admin-menu-toggle';
    toggleBtn.className = 'admin-menu-toggle';
    toggleBtn.type = 'button';
    toggleBtn.title = 'Mở Menu Sidebar';
    toggleBtn.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>';
    toggleBtn.onclick = () => document.body.classList.toggle('sidebar-open');
    topbar.insertBefore(toggleBtn, topbar.firstChild);
  } else {
    const toggleBtn = document.getElementById('admin-menu-toggle');
    if (toggleBtn) toggleBtn.onclick = () => document.body.classList.toggle('sidebar-open');
  }

  // Close drawer on mobile when clicking nav links
  links.forEach(a => {
    a.addEventListener('click', () => {
      if (window.innerWidth <= 992) {
        document.body.classList.remove('sidebar-open');
      }
    });
  });

  // Logout button
  const logoutBtn = document.getElementById('admin-logout-btn');
  if (logoutBtn) {
    logoutBtn.onclick = () => {
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi trang quản trị?')) {
        sessionStorage.removeItem(STORAGE_AUTH_TOKEN);
        window.location.href = 'login.html';
      }
    };
  }

  // Update badges
  const banksBadge = document.getElementById('admin-badge-banks');
  if (banksBadge) banksBadge.textContent = loadBanks().length;

  const usersBadge = document.getElementById('admin-badge-users');
  const cachedUsers = loadUsers();
  if (usersBadge) usersBadge.textContent = cachedUsers.length;

  const ordersBadge = document.getElementById('admin-badge-orders');
  const cachedOrders = loadOrders();
  if (ordersBadge) ordersBadge.textContent = cachedOrders.length;

  // Asynchronously sync live counts from real MySQL database
  fetchUsers().then(users => {
    if (usersBadge && Array.isArray(users)) usersBadge.textContent = users.length;
  }).catch(() => {});

  fetchOrders().then(orders => {
    if (ordersBadge && Array.isArray(orders)) ordersBadge.textContent = orders.length;
  }).catch(() => {});
}

// Toast helper
export function showToast(message, type = 'success') {
  let container = document.getElementById('admin-toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'admin-toast-container';
    container.className = 'admin-toast-container';
    document.body.appendChild(container);
  }
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

// Data loaders and savers with dual MySQL + localStorage sync
export function loadConfig() {
  try {
    const saved = localStorage.getItem(STORAGE_CONFIG);
    return saved ? { ...defaultConfig, ...JSON.parse(saved) } : { ...defaultConfig };
  } catch (_) {
    return { ...defaultConfig };
  }
}

export function saveConfig(cfg) {
  const merged = { ...loadConfig(), ...cfg };
  localStorage.setItem(STORAGE_CONFIG, JSON.stringify(merged));

  // 1. Dispatch custom event in current window
  window.dispatchEvent(new CustomEvent('autobank_config_updated', { detail: merged }));

  // 2. Broadcast across tabs via BroadcastChannel
  try {
    const channel = new BroadcastChannel('autobank_live_channel');
    channel.postMessage({ type: 'CONFIG_UPDATED', config: merged });
    setTimeout(() => channel.close(), 1000);
  } catch (_) {}

  // 3. Persist to MySQL via NestJS API
  fetch(`${API_BASE}/admin/configs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(merged),
  }).catch(() => {});
}

export function loadBanks() {
  try {
    const saved = localStorage.getItem(STORAGE_BANKS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return defaultBanks.map(b => ({ ...b, active: true }));
}

export function saveBanks(list) {
  localStorage.setItem(STORAGE_BANKS, JSON.stringify(list));
}

export async function fetchStats() {
  try {
    const res = await fetch(`${API_BASE}/admin/stats`);
    if (res.ok) return await res.json();
  } catch (_) {}
  return null;
}

export async function fetchLogs() {
  try {
    const res = await fetch(`${API_BASE}/admin/logs`);
    if (res.ok) return await res.json();
  } catch (_) {}
  return [];
}

export function loadUsers() {
  try {
    const saved = localStorage.getItem(STORAGE_USERS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export async function fetchUsers() {
  try {
    const res = await fetch(`${API_BASE}/admin/users`);
    if (res.ok) {
      const users = await res.json();
      localStorage.setItem(STORAGE_USERS, JSON.stringify(users));
      return users;
    }
  } catch (_) {}
  return loadUsers();
}

export function saveUsers(list) {
  localStorage.setItem(STORAGE_USERS, JSON.stringify(list));
}

export async function saveUserApi(userData) {
  try {
    const res = await fetch(`${API_BASE}/admin/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(userData),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function extendUserApi(email, days) {
  try {
    const res = await fetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}/extend`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ days }),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function toggleBlockUserApi(email) {
  try {
    const res = await fetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}/toggle-block`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteUserApi(email) {
  try {
    const res = await fetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export function loadOrders() {
  try {
    const saved = localStorage.getItem(STORAGE_ORDERS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export async function fetchOrders() {
  try {
    const res = await fetch(`${API_BASE}/admin/orders`);
    if (res.ok) {
      const orders = await res.json();
      localStorage.setItem(STORAGE_ORDERS, JSON.stringify(orders));
      return orders;
    }
  } catch (_) {}
  return loadOrders();
}

export function saveOrders(list) {
  localStorage.setItem(STORAGE_ORDERS, JSON.stringify(list));
}

export async function saveOrderApi(orderData) {
  try {
    const res = await fetch(`${API_BASE}/admin/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(orderData),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function approveOrderApi(orderCode) {
  try {
    const res = await fetch(`${API_BASE}/admin/orders/${encodeURIComponent(orderCode)}/approve`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteOrderApi(orderCode) {
  try {
    const res = await fetch(`${API_BASE}/admin/orders/${encodeURIComponent(orderCode)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export function initCopyButtons() {
  document.querySelectorAll('[data-copy-target]').forEach(btn => {
    btn.onclick = () => {
      const targetId = btn.getAttribute('data-copy-target');
      const input = document.getElementById(targetId);
      if (input) {
        navigator.clipboard.writeText(input.value);
        const originalText = btn.textContent;
        btn.textContent = 'Đã chép!';
        setTimeout(() => (btn.textContent = originalText), 1500);
        showToast('Đã sao chép vào bộ nhớ tạm!');
      }
    };
  });
}
