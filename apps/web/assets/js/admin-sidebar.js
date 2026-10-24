/**
 * Shared Admin Sidebar Component
 * Tách biệt 1 code riêng duy nhất cho toàn bộ 9 trang Admin Portal.
 * Tự động đồng bộ badge số lượng thực tế từ MySQL Database 24/7.
 */
import {
  API_BASE,
  STORAGE_AUTH_TOKEN,
  ENV_ADMIN_USER,
  fetchBanks,
  fetchUsers,
  fetchOrders,
  fetchCoupons,
  fetchPushes,
  fetchApiKeys
} from './admin-core.js';

export function renderAdminSidebar(activePageKey = 'overview') {
  const sidebar = document.querySelector('.admin-sidebar') || document.getElementById('admin-sidebar');
  if (!sidebar) return;

  sidebar.innerHTML = `
    <div class="admin-sidebar-brand">
      <img src="../assets/images/favicon.png" alt="AutoBank Logo" />
      <div>
        <strong>Đọc Thông Báo</strong>
        <span>Admin Portal</span>
      </div>
      <button type="button" class="admin-sidebar-close" id="admin-sidebar-close" title="Đóng Menu">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="18" x2="18" y2="18"></line>
        </svg>
      </button>
    </div>

    <nav class="admin-sidebar-nav">
      <a href="/admin" class="admin-nav-item ${activePageKey === 'overview' ? 'active' : ''}" data-page="overview">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>
        </svg>
        <span>Tổng quan hệ thống</span>
      </a>

      <a href="/admin/config" class="admin-nav-item ${activePageKey === 'config' ? 'active' : ''}" data-page="config">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="3"/>
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
        </svg>
        <span>Cấu hình Web &amp; App</span>
      </a>

      <a href="/admin/banks" class="admin-nav-item ${activePageKey === 'banks' ? 'active' : ''}" data-page="banks">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="3" y1="21" x2="21" y2="21"/><line x1="3" y1="10" x2="21" y2="10"/>
          <polyline points="5 6 12 3 19 6"/><line x1="4" y1="10" x2="4" y2="21"/>
          <line x1="20" y1="10" x2="20" y2="21"/><line x1="8" y1="14" x2="8" y2="17"/>
          <line x1="12" y1="14" x2="12" y2="17"/><line x1="16" y1="14" x2="16" y2="17"/>
        </svg>
        <span>65+ Ngân Hàng &amp; Ví</span>
        <span class="admin-nav-badge" id="admin-badge-banks">--</span>
      </a>

      <a href="/admin/users" class="admin-nav-item ${activePageKey === 'users' ? 'active' : ''}" data-page="users">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        <span>Người dùng &amp; Thiết bị</span>
        <span class="admin-nav-badge" id="admin-badge-users">--</span>
      </a>

      <a href="/admin/notifications" class="admin-nav-item ${activePageKey === 'notifications' ? 'active' : ''}" data-page="notifications">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <span>Bắn thông báo đến App</span>
        <span class="admin-nav-badge" id="admin-badge-push">--</span>
      </a>

      <a href="/admin/coupons" class="admin-nav-item ${activePageKey === 'coupons' ? 'active' : ''}" data-page="coupons">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/>
          <line x1="7" y1="7" x2="7.01" y2="7"/>
        </svg>
        <span>Mã Giảm Giá</span>
        <span class="admin-nav-badge" id="admin-badge-coupons">--</span>
      </a>

      <a href="/admin/orders" class="admin-nav-item ${activePageKey === 'orders' ? 'active' : ''}" data-page="orders">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>
        </svg>
        <span>Đơn hàng &amp; Giao dịch</span>
        <span class="admin-nav-badge" id="admin-badge-orders">--</span>
      </a>

      <a href="/admin/affiliate" class="admin-nav-item ${activePageKey === 'affiliate' ? 'active' : ''}" data-page="affiliate">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><line x1="12" y1="6" x2="12" y2="8"/><line x1="12" y1="16" x2="12" y2="18"/>
        </svg>
        <span>Giới thiệu &amp; Rút tiền</span>
        <span class="admin-nav-badge" id="admin-badge-affiliate" style="background:#0284c7; display:none;">0</span>
      </a>

      <a href="/admin/payment-autobank" class="admin-nav-item ${activePageKey === 'payment-autobank' ? 'active' : ''}" data-page="payment-autobank">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
        </svg>
        <span>Thanh toán AutoBank</span>
      </a>

      <a href="/admin/keys" class="admin-nav-item ${activePageKey === 'keys' ? 'active' : ''}" data-page="keys">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
        </svg>
        <span>API Keys &amp; Kết nối</span>
        <span class="admin-nav-badge" id="admin-badge-keys">--</span>
      </a>
    </nav>

    <div class="admin-sidebar-footer">
      <div class="admin-user-pill">
        <div class="admin-avatar">AD</div>
        <div class="admin-user-info">
          <strong id="admin-display-username">${ENV_ADMIN_USER || 'admin'}</strong>
          <small>● Toàn quyền quản trị</small>
        </div>
      </div>
      <button type="button" class="admin-logout-btn" id="admin-logout-btn" title="Đăng xuất khỏi hệ thống">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
          <polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
        </svg>
      </button>
    </div>
  `;

  setupSidebarInteractions();
  syncSidebarBadgesFromSql();
}

function setupSidebarInteractions() {
  // Mobile Off-canvas Drawer Toggle & Overlay
  let overlay = document.querySelector('.admin-sidebar-overlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.className = 'admin-sidebar-overlay';
    document.body.appendChild(overlay);
  }
  overlay.onclick = () => document.body.classList.remove('sidebar-open');

  const closeBtn = document.getElementById('admin-sidebar-close');
  if (closeBtn) {
    closeBtn.onclick = () => document.body.classList.remove('sidebar-open');
  }

  // Topbar hamburger button
  const topbar = document.querySelector('.admin-topbar');
  let toggleBtn = document.getElementById('admin-menu-toggle');
  if (topbar && !toggleBtn) {
    toggleBtn = document.createElement('button');
    toggleBtn.id = 'admin-menu-toggle';
    toggleBtn.className = 'admin-menu-toggle';
    toggleBtn.type = 'button';
    toggleBtn.title = 'Mở Menu Sidebar';
    toggleBtn.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>';
    topbar.insertBefore(toggleBtn, topbar.firstChild);
  }
  if (toggleBtn) {
    toggleBtn.onclick = () => document.body.classList.toggle('sidebar-open');
  }

  // Close drawer on mobile when clicking links
  document.querySelectorAll('.admin-nav-item').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 992) {
        document.body.classList.remove('sidebar-open');
      }
    });
  });

  // Logout button handler
  const logoutBtn = document.getElementById('admin-logout-btn');
  if (logoutBtn) {
    logoutBtn.onclick = () => {
      if (confirm('Bạn có chắc chắn muốn đăng xuất khỏi trang quản trị AutoBank?')) {
        sessionStorage.removeItem(STORAGE_AUTH_TOKEN);
        window.location.href = 'login.html';
      }
    };
  }
}

export async function syncSidebarBadgesFromSql() {
  // Banks Badge
  fetchBanks().then(banks => {
    const el = document.getElementById('admin-badge-banks');
    if (el && Array.isArray(banks)) el.textContent = banks.length;
  }).catch(() => {});

  // Users Badge
  fetchUsers().then(users => {
    const el = document.getElementById('admin-badge-users');
    if (el && Array.isArray(users)) el.textContent = users.length;
  }).catch(() => {});

  // Orders Badge (Chỉ đếm đơn thành công)
  fetchOrders().then(orders => {
    const el = document.getElementById('admin-badge-orders');
    if (el && Array.isArray(orders)) {
      const paid = orders.filter(o => ['PAID', 'SUCCESS', 'COMPLETED'].includes(String(o.status || '').toUpperCase()));
      el.textContent = paid.length;
    }
  }).catch(() => {});

  // Coupons Badge
  fetchCoupons().then(coupons => {
    const el = document.getElementById('admin-badge-coupons');
    if (el && Array.isArray(coupons)) el.textContent = coupons.length;
  }).catch(() => {});

  // Push Badge
  fetchPushes().then(pushes => {
    const el = document.getElementById('admin-badge-push');
    if (el && Array.isArray(pushes)) el.textContent = pushes.length;
  }).catch(() => {});

  // API Keys Badge
  fetchApiKeys().then(keys => {
    const el = document.getElementById('admin-badge-keys');
    if (el && Array.isArray(keys)) el.textContent = keys.length;
  }).catch(() => {});

  // Affiliate Withdrawals Pending Badge
  try {
    const jwt = sessionStorage.getItem('autobank_admin_jwt');
    if (jwt) {
      fetch(`${API_BASE}/admin/affiliate/overview`, {
        headers: { Authorization: `Bearer ${jwt}` },
      }).then(r => r.json()).then(data => {
        const el = document.getElementById('admin-badge-affiliate');
        if (el && data && data.withdrawals) {
          const pending = data.withdrawals.filter(w => String(w.status).toUpperCase() === 'PENDING').length;
          if (pending > 0) {
            el.textContent = pending;
            el.style.background = '#f59e0b';
            el.style.display = 'inline-block';
          } else {
            el.style.display = 'none';
          }
        }
      }).catch(() => {});
    }
  } catch (_) {}
}
