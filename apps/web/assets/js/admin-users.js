import { checkAuth, initSidebar, showToast, fetchUsers, saveUserApi, extendUserApi, toggleBlockUserApi, deleteUserApi, API_BASE } from './admin-core.js';

let usersList = [];
let currentExtendUserEmail = null;

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('users');

  await reloadUsersList();
  initAddAndEditModals();
  initExtendModal();
  initTableEventDelegation();
});

async function reloadUsersList() {
  usersList = await fetchUsers();
  renderUsers();
}

function renderUsers(filterKeyword = '') {
  const tbody = document.getElementById('admin-users-table-body');
  const countBadge = document.getElementById('admin-badge-users');
  if (!tbody) return;

  const kw = filterKeyword.toLowerCase().trim();
  const filtered = usersList.filter(u => {
    if (!kw) return true;
    return (u.name || '').toLowerCase().includes(kw) || 
           (u.email || '').toLowerCase().includes(kw) || 
           (u.device || '').toLowerCase().includes(kw) ||
           (u.phone || '').toLowerCase().includes(kw) ||
           (u.shopName || '').toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = usersList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 30px;">Không tìm thấy người dùng / thiết bị nào phù hợp.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(u => `
    <tr data-user-email="${u.email}">
      <td>
        <strong style="color: #fff; display: block; font-size: 0.95rem;">${u.name}</strong>
        <span style="font-size: 0.82rem; color: #38bdf8; font-family: monospace;">${u.email}</span>
      </td>
      <td>
        <div style="font-weight: 700; color: #f8fafc; display: flex; align-items: center; gap: 5px;">
          <span>🏪</span> ${u.shopName || '<span style="color: #64748b; font-weight: normal;">Chưa đặt tên cửa hàng</span>'}
        </div>
        <div style="font-size: 0.8rem; color: #94a3b8; margin-top: 3px; display: flex; align-items: center; gap: 5px;">
          <span>📞</span> ${u.phone ? `<strong style="color: #34d399;">${u.phone}</strong>` : '<span style="color: #64748b;">Chưa cập nhật SĐT</span>'}
        </div>
      </td>
      <td>
        <div style="color: #cbd5e1; font-weight: 600;">${u.device || 'Thiết bị di động'}</div>
        <small style="color: #94a3b8;">Phiên bản v${u.version || '1.2.0'}</small>
      </td>
      <td>
        <span class="admin-badge admin-badge-info">${u.pkg || u.packagePlan || '1 Năm'}</span>
      </td>
      <td>
        <strong style="color: ${isExpired(u.expires || u.expiresAt) ? '#ef4444' : '#10b981'};">${formatDate(u.expires || u.expiresAt)}</strong>
      </td>
      <td>
        <span class="admin-badge admin-badge-${getStatusBadgeClass(u.status)}">${getStatusText(u.status)}</span>
      </td>
      <td>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="extend" data-email="${u.email}" title="Gia hạn ngày sử dụng">+ Gia Hạn</button>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-email="${u.email}" title="Chỉnh sửa thông tin">Sửa</button>
          <button type="button" class="admin-btn ${u.status === 'BLOCKED' ? 'admin-btn-success' : 'admin-btn-outline'} admin-btn-sm" data-action="toggle-block" data-email="${u.email}">
            ${u.status === 'BLOCKED' ? 'Mở Khóa' : 'Khóa'}
          </button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-email="${u.email}" data-name="${u.name}" title="Xóa thiết bị khỏi hệ thống">Xóa</button>
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
}

function formatDate(val) {
  if (!val) return '2027-10-10';
  return String(val).slice(0, 10);
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

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-users-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    // Sửa (Edit)
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const email = editBtn.getAttribute('data-email');
      openUserModal(email);
      return;
    }

    // Xóa (Delete)
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const email = delBtn.getAttribute('data-email');
      const name = delBtn.getAttribute('data-name') || email;
      if (confirm(`Bạn có chắc chắn muốn xóa vĩnh viễn người dùng "${name}" (${email}) khỏi hệ thống MySQL?`)) {
        delBtn.disabled = true;
        const ok = await deleteUserApi(email);
        if (ok) {
          showToast(`Đã xóa người dùng ${name} khỏi MySQL thành công!`, 'success');
          await reloadUsersList();
        } else {
          showToast(`Lỗi khi xóa người dùng ${name}`, 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }

    // Gia Hạn
    const extendBtn = e.target.closest('[data-action="extend"]');
    if (extendBtn) {
      const email = extendBtn.getAttribute('data-email');
      openExtendModal(email);
      return;
    }

    // Khóa / Mở Khóa
    const blockBtn = e.target.closest('[data-action="toggle-block"]');
    if (blockBtn) {
      const email = blockBtn.getAttribute('data-email');
      const u = usersList.find(x => x.email === email);
      blockBtn.disabled = true;
      const ok = await toggleBlockUserApi(email);
      if (ok) {
        showToast(`Đã ${u?.status === 'BLOCKED' ? 'mở khóa' : 'khóa tài khoản'} của ${u?.name || email}!`);
        await reloadUsersList();
      } else {
        showToast('Lỗi khi thay đổi trạng thái tài khoản', 'error');
        blockBtn.disabled = false;
      }
      return;
    }
  });
}

function openUserModal(userEmail = null) {
  const editModal = document.getElementById('admin-user-edit-modal');
  const form = document.getElementById('form-save-user');
  if (!editModal || !form) return;

  if (userEmail) {
    const u = usersList.find(x => x.email === userEmail);
    if (!u) return;
    document.getElementById('modal-user-edit-title').textContent = `Chỉnh Sửa: ${u.name}`;
    document.getElementById('edit-user-index').value = u.email;
    document.getElementById('m-user-name-input').value = u.name || '';
    document.getElementById('m-user-email-input').value = u.email || '';
    document.getElementById('m-user-email-input').readOnly = true;
    const shopEl = document.getElementById('m-user-shop-input');
    if (shopEl) shopEl.value = u.shopName || '';
    const phoneEl = document.getElementById('m-user-phone-input');
    if (phoneEl) phoneEl.value = u.phone || '';
    document.getElementById('m-user-device-input').value = u.device || 'Android';
    document.getElementById('m-user-version-input').value = u.version || '1.2.0';
    document.getElementById('m-user-pkg-input').value = u.pkg || u.packagePlan || '1 Năm';
    document.getElementById('m-user-expires-input').value = formatDate(u.expires || u.expiresAt);
    document.getElementById('m-user-status-input').value = u.status || 'ACTIVE';
  } else {
    document.getElementById('modal-user-edit-title').textContent = 'Thêm Người Dùng & Thiết Bị Mới';
    document.getElementById('edit-user-index').value = '';
    form.reset();
    document.getElementById('m-user-email-input').readOnly = false;
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    document.getElementById('m-user-expires-input').value = nextYear.toISOString().split('T')[0];
  }

  updateModalExpireBadge();
  editModal.classList.add('is-open');
}

function updateModalExpireBadge() {
  const expiresEl = document.getElementById('m-user-expires-input');
  const statusEl = document.getElementById('m-user-status-input');
  const badgeEl = document.getElementById('m-user-expires-badge');
  const noteEl = document.getElementById('m-user-preview-note');
  if (!expiresEl || !badgeEl) return;

  const val = expiresEl.value;
  if (!val) return;
  const expDate = new Date(val);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  expDate.setHours(0, 0, 0, 0);
  const diffDays = Math.round((expDate - today) / (1000 * 60 * 60 * 24));

  const isExpiredState = statusEl && (statusEl.value === 'EXPIRED' || statusEl.value === 'BLOCKED');

  if (diffDays < 0 || isExpiredState) {
    const dayText = diffDays < 0 ? `${Math.abs(diffDays)} ngày trước` : 'Hôm nay';
    badgeEl.textContent = `🔴 Đã hết hạn (${dayText})`;
    badgeEl.style.background = 'rgba(239, 68, 68, 0.2)';
    badgeEl.style.color = '#f87171';
    if (noteEl) noteEl.textContent = 'Khóa hoạt động & thu hồi quyền ngay lập tức';
  } else if (diffDays === 0) {
    badgeEl.textContent = '🟡 Hết hạn trong hôm nay';
    badgeEl.style.background = 'rgba(245, 158, 11, 0.2)';
    badgeEl.style.color = '#fbbf24';
    if (noteEl) noteEl.textContent = 'Sẽ hết hạn vào cuối ngày hôm nay';
  } else {
    const periodText = diffDays >= 365 ? `${(diffDays / 365).toFixed(1)} năm` : `${diffDays} ngày`;
    badgeEl.textContent = `🟢 Còn ${periodText}`;
    badgeEl.style.background = 'rgba(16, 185, 129, 0.2)';
    badgeEl.style.color = '#34d399';
    if (noteEl) noteEl.textContent = 'Đầy đủ quyền trực máy và đọc thông báo';
  }
}

function closeUserModal() {
  const editModal = document.getElementById('admin-user-edit-modal');
  if (editModal) editModal.classList.remove('is-open');
}

function openExtendModal(userEmail) {
  const extendModal = document.getElementById('admin-user-modal');
  const emailEl = document.getElementById('m-user-email');
  if (!extendModal || !emailEl) return;

  currentExtendUserEmail = userEmail;
  const u = usersList.find(x => x.email === userEmail);
  if (u) {
    emailEl.textContent = `${u.name} (${u.email}) — Hạn hiện tại: ${formatDate(u.expires || u.expiresAt)}`;
    extendModal.classList.add('is-open');
  }
}

function closeExtendModal() {
  const extendModal = document.getElementById('admin-user-modal');
  if (extendModal) extendModal.classList.remove('is-open');
  currentExtendUserEmail = null;
}

window.adminOpenUserModal = openUserModal;
window.adminCloseUserModal = closeUserModal;
window.adminCloseExtendModal = closeExtendModal;

function initAddAndEditModals() {
  const modal = document.getElementById('admin-user-edit-modal');
  const addBtn = document.getElementById('btn-add-user');
  const closeBtn = document.getElementById('modal-user-edit-close');
  const cancelBtn = document.getElementById('modal-user-edit-cancel');
  const form = document.getElementById('form-save-user');

  if (closeBtn) closeBtn.onclick = closeUserModal;
  if (cancelBtn) cancelBtn.onclick = closeUserModal;
  if (addBtn) addBtn.onclick = () => openUserModal(null);

  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeUserModal();
    });
  }

  // TỰ ĐỘNG ĐỒNG BỘ TRẠNG THÁI VÀ NGÀY HẾT HẠN
  const statusEl = document.getElementById('m-user-status-input');
  const expiresEl = document.getElementById('m-user-expires-input');
  const pkgEl = document.getElementById('m-user-pkg-input');

  if (statusEl && !statusEl.dataset.bound) {
    statusEl.dataset.bound = 'true';
    statusEl.addEventListener('change', () => {
      const st = statusEl.value;
      const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      if (st === 'EXPIRED' || st === 'BLOCKED') {
        // YÊU CẦU: Khi chọn trạng thái hết hạn thì ngày hết hạn thì hết hạn ngay lúc đó luôn
        if (expiresEl) expiresEl.value = yesterday;
      } else if (st === 'ACTIVE') {
        if (expiresEl) {
          const cur = new Date(expiresEl.value);
          if (!expiresEl.value || cur <= new Date()) {
            const nextYear = new Date();
            nextYear.setFullYear(nextYear.getFullYear() + 1);
            expiresEl.value = nextYear.toISOString().split('T')[0];
          }
        }
      } else if (st === 'TRIAL') {
        const in3Days = new Date(Date.now() + 3 * 86400000).toISOString().split('T')[0];
        if (expiresEl) expiresEl.value = in3Days;
        if (pkgEl) pkgEl.value = 'Dùng thử 3 ngày';
      }
      updateModalExpireBadge();
    });
  }

  if (pkgEl && !pkgEl.dataset.bound) {
    pkgEl.dataset.bound = 'true';
    pkgEl.addEventListener('change', () => {
      const p = pkgEl.value;
      const now = new Date();
      if (p.includes('Dùng thử')) {
        now.setDate(now.getDate() + 3);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'TRIAL';
      } else if (p.includes('1 Tháng')) {
        now.setDate(now.getDate() + 30);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      } else if (p.includes('3 Tháng')) {
        now.setDate(now.getDate() + 90);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      } else if (p.includes('6 Tháng')) {
        now.setDate(now.getDate() + 180);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      } else if (p.includes('9 Tháng')) {
        now.setDate(now.getDate() + 270);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      } else if (p.includes('1 Năm')) {
        now.setFullYear(now.getFullYear() + 1);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      } else if (p.includes('Vĩnh Viễn')) {
        now.setFullYear(now.getFullYear() + 10);
        if (expiresEl) expiresEl.value = now.toISOString().split('T')[0];
        if (statusEl) statusEl.value = 'ACTIVE';
      }
      updateModalExpireBadge();
    });
  }

  if (expiresEl && !expiresEl.dataset.bound) {
    expiresEl.dataset.bound = 'true';
    expiresEl.addEventListener('input', () => {
      const chosen = new Date(expiresEl.value);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      if (chosen < today) {
        if (statusEl && statusEl.value !== 'BLOCKED') statusEl.value = 'EXPIRED';
      } else {
        if (statusEl && statusEl.value === 'EXPIRED') statusEl.value = 'ACTIVE';
      }
      updateModalExpireBadge();
    });
  }

  // CÁC NÚT PHÍM TẮT NHANH TRONG MODAL
  const btnExp = document.getElementById('btn-quick-expire');
  if (btnExp && !btnExp.dataset.bound) {
    btnExp.dataset.bound = 'true';
    btnExp.onclick = () => {
      const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      if (expiresEl) expiresEl.value = yesterday;
      if (statusEl) statusEl.value = 'EXPIRED';
      updateModalExpireBadge();
    };
  }

  const btnTrial = document.getElementById('btn-quick-trial');
  if (btnTrial && !btnTrial.dataset.bound) {
    btnTrial.dataset.bound = 'true';
    btnTrial.onclick = () => {
      const in3Days = new Date(Date.now() + 3 * 86400000).toISOString().split('T')[0];
      if (expiresEl) expiresEl.value = in3Days;
      if (pkgEl) pkgEl.value = 'Dùng thử 3 ngày';
      if (statusEl) statusEl.value = 'TRIAL';
      updateModalExpireBadge();
    };
  }

  const btn1m = document.getElementById('btn-quick-1m');
  if (btn1m && !btn1m.dataset.bound) {
    btn1m.dataset.bound = 'true';
    btn1m.onclick = () => {
      const in30Days = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0];
      if (expiresEl) expiresEl.value = in30Days;
      if (pkgEl) pkgEl.value = '1 Tháng';
      if (statusEl) statusEl.value = 'ACTIVE';
      updateModalExpireBadge();
    };
  }

  const btn1y = document.getElementById('btn-quick-1y');
  if (btn1y && !btn1y.dataset.bound) {
    btn1y.dataset.bound = 'true';
    btn1y.onclick = () => {
      const d = new Date();
      d.setFullYear(d.getFullYear() + 1);
      if (expiresEl) expiresEl.value = d.toISOString().split('T')[0];
      if (pkgEl) pkgEl.value = '1 Năm';
      if (statusEl) statusEl.value = 'ACTIVE';
      updateModalExpireBadge();
    };
  }

  const btnLife = document.getElementById('btn-quick-lifetime');
  if (btnLife && !btnLife.dataset.bound) {
    btnLife.dataset.bound = 'true';
    btnLife.onclick = () => {
      const d = new Date();
      d.setFullYear(d.getFullYear() + 10);
      if (expiresEl) expiresEl.value = d.toISOString().split('T')[0];
      if (pkgEl) pkgEl.value = 'Gói Vĩnh Viễn';
      if (statusEl) statusEl.value = 'ACTIVE';
      updateModalExpireBadge();
    };
  }

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const userData = {
        name: document.getElementById('m-user-name-input').value.trim(),
        email: document.getElementById('m-user-email-input').value.trim(),
        shopName: document.getElementById('m-user-shop-input')?.value.trim() || '',
        phone: document.getElementById('m-user-phone-input')?.value.trim() || '',
        device: document.getElementById('m-user-device-input').value.trim(),
        version: document.getElementById('m-user-version-input').value.trim(),
        packagePlan: document.getElementById('m-user-pkg-input').value,
        expiresAt: document.getElementById('m-user-expires-input').value,
        status: document.getElementById('m-user-status-input').value,
        forceUpdate: true,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const ok = await saveUserApi(userData);
      if (ok) {
        showToast(`Lưu dữ liệu người dùng ${userData.name} vào MySQL thành công!`, 'success');
        closeUserModal();
        await reloadUsersList();
      } else {
        showToast('Lỗi khi lưu người dùng vào MySQL', 'error');
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}

function initExtendModal() {
  const extendModal = document.getElementById('admin-user-modal');
  const closeExtendBtn = document.getElementById('modal-user-close');

  if (closeExtendBtn) closeExtendBtn.onclick = closeExtendModal;
  if (extendModal) {
    extendModal.addEventListener('click', (e) => {
      if (e.target === extendModal) closeExtendModal();
    });
  }

  document.querySelectorAll('[data-extend-days]').forEach(btn => {
    btn.onclick = async () => {
      if (!currentExtendUserEmail) return;
      const days = parseInt(btn.getAttribute('data-extend-days'), 10);
      btn.disabled = true;
      const ok = await extendUserApi(currentExtendUserEmail, days);
      if (ok) {
        showToast(`Đã gia hạn thành công thêm ${days} ngày cho ${currentExtendUserEmail}! Đồng bộ MySQL.`);
        closeExtendModal();
        await reloadUsersList();
      } else {
        showToast('Lỗi khi gia hạn người dùng', 'error');
      }
      btn.disabled = false;
    };
  });
}
