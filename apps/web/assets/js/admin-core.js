import { BANKS_DATA as defaultBanks } from '../data/banks-data.js';

// Environment variables
export const ENV_ADMIN_USER = import.meta.env.VITE_ADMIN_USERNAME || 'admin';
export const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:3000';

// Storage keys
export const STORAGE_AUTH_TOKEN = 'autobank_admin_session';
export const STORAGE_JWT_TOKEN = 'autobank_admin_jwt';
export const STORAGE_CONFIG = 'autobank_system_config';
export const STORAGE_BANKS = 'autobank_banks_custom';
export const STORAGE_USERS = 'autobank_users_list';
export const STORAGE_ORDERS = 'autobank_orders_list';
export const STORAGE_PUSH = 'autobank_push_notifications';

// Helper lấy tiêu đề Authorization chứa JWT Token quản trị viên
export function getAdminHeaders() {
  const jwt = sessionStorage.getItem(STORAGE_JWT_TOKEN);
  const headers = { 'Content-Type': 'application/json' };
  if (jwt) {
    headers['Authorization'] = `Bearer ${jwt}`;
  }
  return headers;
}

// Wrapper fetch chuyên dụng cho Admin - tự động gắn JWT Token và bắt lỗi hết hạn phiên
export async function adminFetch(url, options = {}) {
  const headers = { ...getAdminHeaders(), ...(options.headers || {}) };
  const res = await fetch(url, { ...options, headers });
  if (res.status === 401 || res.status === 403) {
    sessionStorage.removeItem(STORAGE_AUTH_TOKEN);
    sessionStorage.removeItem(STORAGE_JWT_TOKEN);
    window.location.href = '/admin/login.html';
    throw new Error('Phiên quản trị viên đã hết hạn hoặc không có quyền');
  }
  return res;
}

// Default initial config
export const defaultConfig = {
  brandName: 'Đọc thông báo nhận tiền',
  brandSlogan: 'Tiền vừa sang ~ máy báo vang',
  chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
  youtubeLink: '',
  hotline: '0869226687',
  email: 'tranquocvu3011@gmail.com',
  facebook: 'https://www.facebook.com/Baochuyentienbanggiongnoi',
  tiktok: 'https://www.tiktok.com/@locketgoldqvu',
  bankCode: 'MB',
  bankAcc: '3011200588888',
  bankName: 'TRẦN QUỐC VŨ',
  serverDomain: 'http://192.168.1.217:3000',
  webDomain: 'http://192.168.1.217:5173',
  apiPort: 3000,
  priceTrial: '0đ (3 ngày)',
  price1m: 38000,
  price3m: 99000,
  price6m: 179000,
  price9m: 249000,
  price1y: 299000,
  priceLifetime: 499000,
  packages: [
    { key: 'trial', name: 'Dùng thử miễn phí', durationDays: 3, price: 0, badge: 'Miễn phí', description: 'Trải nghiệm 100% tính năng cao cấp trong 3 ngày', isActive: true },
    { key: '1m', name: 'Gói 1 Tháng', durationDays: 30, price: 39000, badge: '', description: 'Bản quyền 30 ngày đầy đủ thông báo giọng nói & live sync', isActive: true },
    { key: '3m', name: 'Gói 3 Tháng', durationDays: 90, price: 99000, badge: 'Tiết kiệm 15%', description: 'Bản quyền 90 ngày cho cửa hàng kinh doanh', isActive: true },
    { key: '6m', name: 'Gói 6 Tháng', durationDays: 180, price: 179000, badge: 'Phổ biến', description: 'Bản quyền 180 ngày ổn định 24/7', isActive: true },
    { key: '9m', name: 'Gói 9 Tháng', durationDays: 270, price: 249000, badge: 'Tiết kiệm', description: 'Bản quyền 270 ngày vận hành quầy thu ngân', isActive: true },
    { key: '1y', name: 'Gói 1 Năm', durationDays: 365, price: 299000, badge: 'Khuyên dùng (Bán chạy nhất)', description: 'Tặng thêm 2 tháng VIP + Hỗ trợ kỹ thuật 24/7', isActive: true },
    { key: 'lifetime', name: 'Gói Vĩnh Viễn', durationDays: 9999, price: 499000, badge: 'Trọn đời VIP', description: 'Dùng trọn đời không giới hạn thời gian', isActive: true },
  ],
  maintenance: false,
  maintenanceMsg: 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau 15 phút.',
  latestVersion: '1.2.0',
  minVersion: '1.0.0',
};

export const defaultUsers = [];
export const defaultOrders = [];

// Auth Guard
export function checkAuth() {
  const token = sessionStorage.getItem(STORAGE_AUTH_TOKEN);
  const jwt = sessionStorage.getItem(STORAGE_JWT_TOKEN);
  if (token !== 'autobank_admin_authenticated' || !jwt) {
    window.location.href = '/admin/login.html';
    return false;
  }
  return true;
}

// Sidebar Setup (Delegates to dedicated admin-sidebar.js component)
import { renderAdminSidebar } from './admin-sidebar.js';
export { renderAdminSidebar };

export function initSidebar(activePageKey = 'overview') {
  renderAdminSidebar(activePageKey);
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
  adminFetch(`${API_BASE}/admin/configs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(merged),
  }).catch(() => {});
}

export function loadBanks() {
  try {
    const saved = localStorage.getItem(STORAGE_BANKS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export function saveBanks(list) {
  localStorage.setItem(STORAGE_BANKS, JSON.stringify(list));
}

export async function fetchBanks() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/banks`);
    if (res.ok) {
      const list = await res.json();
      const normalized = list.map(b => ({
        ...b,
        active: b.isActive !== false,
      }));
      localStorage.setItem(STORAGE_BANKS, JSON.stringify(normalized));
      return normalized;
    }
  } catch (_) {}
  return loadBanks();
}

export async function saveBankApi(bankData) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/banks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(bankData),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function toggleBankApi(id) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/banks/${encodeURIComponent(id)}/toggle`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteBankApi(id) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/banks/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function fetchStats() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/stats`);
    if (res.ok) return await res.json();
  } catch (_) {}
  return null;
}

export async function fetchLogs() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/logs`);
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
    const res = await adminFetch(`${API_BASE}/admin/users`);
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
    const res = await adminFetch(`${API_BASE}/admin/users`, {
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
    const res = await adminFetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}/extend`, {
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
    const res = await adminFetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}/toggle-block`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteUserApi(email) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/users/${encodeURIComponent(email)}`, {
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
    const res = await adminFetch(`${API_BASE}/admin/orders`);
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
    const res = await adminFetch(`${API_BASE}/admin/orders`, {
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
    const res = await adminFetch(`${API_BASE}/admin/orders/${encodeURIComponent(orderCode)}/approve`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteOrderApi(orderCode) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/orders/${encodeURIComponent(orderCode)}`, {
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

// Coupons Management APIs & Storage
export const STORAGE_COUPONS = 'autobank_coupons_list';

export function loadCoupons() {
  try {
    const saved = localStorage.getItem(STORAGE_COUPONS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export async function fetchCoupons() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/coupons`);
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem(STORAGE_COUPONS, JSON.stringify(data));
      return data;
    }
  } catch (_) {}
  return loadCoupons();
}

export async function saveCouponApi(couponData) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/coupons`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(couponData),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function toggleCouponApi(id) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/coupons/${encodeURIComponent(id)}/toggle`, {
      method: 'PUT',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteCouponApi(id) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/coupons/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function validateCouponApi(code, amount) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/coupons/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code, amount }),
    });
    return await res.json();
  } catch (e) {
    return { valid: false, message: e.message };
  }
}

export function loadPushHistory() {
  try {
    const saved = localStorage.getItem(STORAGE_PUSH);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export async function fetchPushes() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/push`);
    if (res.ok) {
      const list = await res.json();
      const normalized = list.map(p => ({
        id: p.id,
        type: p.type,
        title: p.title,
        body: p.body,
        action: p.action,
        timestamp: p.createdAt,
      }));
      localStorage.setItem(STORAGE_PUSH, JSON.stringify(normalized));
      return normalized;
    }
  } catch (_) {}
  return loadPushHistory();
}

export async function sendPushApi(data) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function updatePushApi(id, data) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/push/${encodeURIComponent(id)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deletePushApi(id) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/push/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

// API Keys & Server Keys Management (MySQL)
export const STORAGE_CLIENT_KEYS = 'autobank_client_api_keys';
export const STORAGE_SERVER_KEYS = 'autobank_server_keys';

export async function fetchApiKeys() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/api-keys`);
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem(STORAGE_CLIENT_KEYS, JSON.stringify(data));
      return data;
    }
  } catch (_) {}
  try {
    const saved = localStorage.getItem(STORAGE_CLIENT_KEYS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return [];
}

export async function saveApiKeyApi(data) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/api-keys`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function deleteApiKeyApi(idOrKey) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/api-keys/${encodeURIComponent(idOrKey)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

export async function fetchServerKeys() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/server-keys`);
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem(STORAGE_SERVER_KEYS, JSON.stringify(data));
      return data;
    }
  } catch (_) {}
  try {
    const saved = localStorage.getItem(STORAGE_SERVER_KEYS);
    if (saved) return JSON.parse(saved);
  } catch (_) {}
  return {
    masterKey: 'ak_live_master_autobank_secret_key_2026',
    fcmKey: '',
    webhookUrl: 'http://localhost:3000/transactions/webhook',
  };
}

export async function saveServerKeysApi(data) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/server-keys`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (res.ok) {
      localStorage.setItem(STORAGE_SERVER_KEYS, JSON.stringify(data));
      return true;
    }
  } catch (_) {}
  return false;
}

