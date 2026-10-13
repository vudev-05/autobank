import { checkAuth, initSidebar, showToast, fetchUsers, saveUserApi, extendUserApi, toggleBlockUserApi, deleteUserApi, API_BASE } from './admin-core.js';

let usersList = [];
let activeEditingUserIndex = -1;

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('users');

  await reloadUsersList();
  initAddAndEditModals();
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
    return (u.name || '').toLowerCase().includes(kw) || (u.email || '').toLowerCase().includes(kw) || (u.device || '').toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = usersList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 30px;">Không tìm thấy người dùng / thiết bị nào phù hợp.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map((u, idx) => `
    <tr>
      <td>
        <strong style="color: #fff; display: block;">${u.name}</strong>
        <span style="font-size: 0.8rem; color: #94a3b8;">${u.email}</span>
      </td>
      <td>
        <div style="color: #cbd5e1; font-weight: 600;">${u.device || 'Thiết bị di động'}</div>
        <small style="color: #38bdf8;">Phiên bản v${u.version || '1.2.0'}</small>
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
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-extend-user="${idx}" title="Gia hạn ngày sử dụng">+ Gia Hạn</button>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-user="${idx}" title="Chỉnh sửa thông tin">Sửa</button>
          <button type="button" class="admin-btn ${u.status === 'BLOCKED' ? 'admin-btn-success' : 'admin-btn-outline'} admin-btn-sm" data-toggle-block="${idx}">
            ${u.status === 'BLOCKED' ? 'Mở Khóa' : 'Khóa'}
          </button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-user="${idx}" title="Xóa thiết bị khỏi hệ thống">Xóa</button>
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

  attachUserTableActions();
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

function attachUserTableActions() {
  // Quick extend modal
  const extendModal = document.getElementById('admin-user-modal');
  const closeExtendBtn = document.getElementById('modal-user-close');
  const emailEl = document.getElementById('m-user-email');

  const closeExtend = () => extendModal.classList.remove('is-open');
  if (closeExtendBtn) closeExtendBtn.onclick = closeExtend;

  document.querySelectorAll('[data-extend-user]').forEach(btn => {
    btn.onclick = () => {
      activeEditingUserIndex = parseInt(btn.getAttribute('data-extend-user'), 10);
      const u = usersList[activeEditingUserIndex];
      if (u) {
        emailEl.textContent = `${u.name} (${u.email}) — Hạn hiện tại: ${formatDate(u.expires || u.expiresAt)}`;
        extendModal.classList.add('is-open');
      }
    };
  });

  document.querySelectorAll('[data-extend-days]').forEach(btn => {
    btn.onclick = async () => {
      const days = parseInt(btn.getAttribute('data-extend-days'), 10);
      if (activeEditingUserIndex >= 0 && usersList[activeEditingUserIndex]) {
        const u = usersList[activeEditingUserIndex];
        btn.disabled = true;
        await extendUserApi(u.email, days);
        closeExtend();
        showToast(`Đã gia hạn thành công thêm ${days} ngày cho ${u.name}! Đồng bộ MySQL thành công.`);
        await reloadUsersList();
      }
    };
  });

  // Toggle block
  document.querySelectorAll('[data-toggle-block]').forEach(btn => {
    btn.onclick = async () => {
      const idx = parseInt(btn.getAttribute('data-toggle-block'), 10);
      const u = usersList[idx];
      if (u) {
        btn.disabled = true;
        await toggleBlockUserApi(u.email);
        showToast(`Đã ${u.status === 'BLOCKED' ? 'mở khóa' : 'khóa tài khoản'} của ${u.name}!`);
        await reloadUsersList();
      }
    };
  });

  // Delete user
  document.querySelectorAll('[data-delete-user]').forEach(btn => {
    btn.onclick = async () => {
      const idx = parseInt(btn.getAttribute('data-delete-user'), 10);
      const u = usersList[idx];
      if (u && confirm(`Bạn có chắc chắn muốn xóa vĩnh viễn người dùng "${u.name}" (${u.email}) khỏi hệ thống?`)) {
        btn.disabled = true;
        await deleteUserApi(u.email);
        showToast(`Đã xóa người dùng ${u.name} khỏi hệ thống MySQL thành công!`);
        await reloadUsersList();
      }
    };
  });

  // Edit user modal opener
  const editModal = document.getElementById('admin-user-edit-modal');
  document.querySelectorAll('[data-edit-user]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-user'), 10);
      const u = usersList[idx];
      if (!u) return;

      document.getElementById('modal-user-edit-title').textContent = `Chỉnh Sửa: ${u.name}`;
      document.getElementById('edit-user-index').value = idx;
      document.getElementById('m-user-name-input').value = u.name;
      document.getElementById('m-user-email-input').value = u.email;
      document.getElementById('m-user-device-input').value = u.device || 'Android';
      document.getElementById('m-user-version-input').value = u.version || '1.2.0';
      document.getElementById('m-user-pkg-input').value = u.pkg || u.packagePlan || '1 Năm';
      document.getElementById('m-user-expires-input').value = formatDate(u.expires || u.expiresAt);
      document.getElementById('m-user-status-input').value = u.status || 'ACTIVE';

      editModal.classList.add('is-open');
    };
  });
}

function initAddAndEditModals() {
  const modal = document.getElementById('admin-user-edit-modal');
  const addBtn = document.getElementById('btn-add-user');
  const closeBtn = document.getElementById('modal-user-edit-close');
  const cancelBtn = document.getElementById('modal-user-edit-cancel');
  const form = document.getElementById('form-save-user');

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  if (addBtn) {
    addBtn.onclick = () => {
      document.getElementById('modal-user-edit-title').textContent = 'Thêm Người Dùng & Thiết Bị Mới';
      document.getElementById('edit-user-index').value = '-1';
      form.reset();
      const nextYear = new Date();
      nextYear.setFullYear(nextYear.getFullYear() + 1);
      document.getElementById('m-user-expires-input').value = nextYear.toISOString().split('T')[0];
      modal.classList.add('is-open');
    };
  }

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const userData = {
        name: document.getElementById('m-user-name-input').value.trim(),
        email: document.getElementById('m-user-email-input').value.trim(),
        device: document.getElementById('m-user-device-input').value.trim(),
        version: document.getElementById('m-user-version-input').value.trim(),
        packagePlan: document.getElementById('m-user-pkg-input').value,
        expiresAt: document.getElementById('m-user-expires-input').value,
        status: document.getElementById('m-user-status-input').value,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      await saveUserApi(userData);
      showToast(`Lưu dữ liệu người dùng ${userData.name} vào MySQL thành công!`);

      if (submitBtn) submitBtn.disabled = false;
      closeModal();
      await reloadUsersList();
    };
  }
}
