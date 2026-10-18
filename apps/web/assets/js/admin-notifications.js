import { checkAuth, initSidebar, showToast, fetchPushes, sendPushApi, updatePushApi, deletePushApi } from './admin-core.js';

let pushHistory = [];
let editingPushId = null;

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('notifications');

  await reloadPushHistory();
  initPushModal();
  initTableEventDelegation();
});

async function reloadPushHistory() {
  pushHistory = await fetchPushes();
  renderPushHistory();
}

function renderPushHistory() {
  const tbody = document.getElementById('admin-push-table-body');
  const countBadge = document.getElementById('admin-badge-push');
  if (!tbody) return;

  if (countBadge) countBadge.textContent = pushHistory.length;

  if (pushHistory.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 30px;">Chưa có lịch sử bắn thông báo nào. Bấm "+ Soạn Thông Báo Mới" bên trên.</td></tr>`;
    return;
  }

  tbody.innerHTML = pushHistory.map(p => `
    <tr data-push-id="${p.id}">
      <td style="color: #94a3b8; font-size: 0.82rem; white-space: nowrap;">
        ${formatDate(p.timestamp)}
      </td>
      <td>
        <span class="admin-badge admin-badge-${getTypeBadgeClass(p.type)}">
          ${getTypeText(p.type)}
        </span>
      </td>
      <td>
        <strong style="color: #fff; font-size: 0.95rem; display: block;">${p.title}</strong>
        <p style="color: #cbd5e1; font-size: 0.85rem; margin: 4px 0 0; line-height: 1.4;">${p.body}</p>
      </td>
      <td>
        <code style="color: #38bdf8; font-size: 0.8rem; background: rgba(15,23,42,0.8); padding: 4px 8px; border-radius: 4px;">
          ${getActionText(p.action)}
        </code>
      </td>
      <td>
        <span class="admin-badge admin-badge-success">Đã gửi</span>
      </td>
      <td>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="resend" data-id="${p.id}" title="Gửi lại thông báo này ngay lập tức">Gửi lại</button>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-id="${p.id}" title="Sửa nội dung">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-id="${p.id}" title="Xóa thông báo">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function formatDate(val) {
  if (!val) return 'Mới đây';
  try {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + d.toLocaleDateString('vi-VN');
    }
  } catch (_) {}
  return String(val);
}

function getTypeBadgeClass(type) {
  switch (type) {
    case 'security_alert': return 'danger';
    case 'promotion': return 'warning';
    case 'maintenance': return 'info';
    default: return 'info';
  }
}

function getTypeText(type) {
  switch (type) {
    case 'security_alert': return 'Bảo mật';
    case 'promotion': return 'Khuyến mại';
    case 'maintenance': return 'Bảo trì';
    default: return 'Cập nhật';
  }
}

function getActionText(action) {
  switch (action) {
    case 'upgrade_vip': return 'Nâng Cấp Gói';
    case 'battery_guide': return 'Tắt Tiết Kiệm Pin';
    case 'bank_setting': return 'Cài Đặt Ngân Hàng';
    default: return 'Mở Ứng Dụng';
  }
}

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-push-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    // Resend
    const resendBtn = e.target.closest('[data-action="resend"]');
    if (resendBtn) {
      const id = resendBtn.getAttribute('data-id');
      const p = pushHistory.find(x => x.id === id);
      if (p) {
        resendBtn.disabled = true;
        const ok = await sendPushApi({
          type: p.type,
          title: p.title,
          body: p.body,
          action: p.action,
        });
        if (ok) {
          showToast(`Đã bắn lại thông báo "${p.title}" đến toàn bộ thiết bị App!`, 'success');
          await reloadPushHistory();
        } else {
          showToast('Lỗi khi bắn lại thông báo', 'error');
        }
        resendBtn.disabled = false;
      }
      return;
    }

    // Edit
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const id = editBtn.getAttribute('data-id');
      openPushModal(id);
      return;
    }

    // Delete
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const id = delBtn.getAttribute('data-id');
      const p = pushHistory.find(x => x.id === id);
      if (confirm(`Bạn có chắc muốn xóa thông báo "${p?.title || id}" khỏi hệ thống MySQL?`)) {
        delBtn.disabled = true;
        const ok = await deletePushApi(id);
        if (ok) {
          showToast('Đã xóa thông báo khỏi MySQL thành công!', 'success');
          await reloadPushHistory();
        } else {
          showToast('Lỗi khi xóa thông báo', 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }
  });
}

function openPushModal(pushId = null) {
  const modal = document.getElementById('admin-push-modal');
  const form = document.getElementById('form-push-notify');
  if (!modal || !form) return;

  editingPushId = pushId;
  if (pushId) {
    const p = pushHistory.find(x => x.id === pushId);
    if (!p) return;
    document.getElementById('modal-push-title').textContent = `Chỉnh Sửa Thông Báo: ${p.title}`;
    document.getElementById('push-type').value = p.type || 'system_update';
    document.getElementById('push-action').value = p.action || 'open_app';
    document.getElementById('push-title').value = p.title || '';
    document.getElementById('push-body').value = p.body || '';
  } else {
    document.getElementById('modal-push-title').textContent = 'Soạn Thông Báo Mới Gửi Đến Toàn Bộ Thiết Bị';
    form.reset();
  }

  modal.classList.add('is-open');
}

function closePushModal() {
  const modal = document.getElementById('admin-push-modal');
  if (modal) modal.classList.remove('is-open');
  editingPushId = null;
}

function initPushModal() {
  const modal = document.getElementById('admin-push-modal');
  const addBtn = document.getElementById('btn-add-push');
  const closeBtn = document.getElementById('modal-push-close');
  const cancelBtn = document.getElementById('modal-push-cancel');
  const form = document.getElementById('form-push-notify');

  if (closeBtn) closeBtn.onclick = closePushModal;
  if (cancelBtn) cancelBtn.onclick = closePushModal;
  if (addBtn) addBtn.onclick = () => openPushModal(null);

  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closePushModal();
    });
  }

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const payload = {
        type: document.getElementById('push-type').value,
        action: document.getElementById('push-action').value,
        title: document.getElementById('push-title').value.trim(),
        body: document.getElementById('push-body').value.trim(),
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      let ok = false;
      if (editingPushId) {
        ok = await updatePushApi(editingPushId, payload);
        if (ok) showToast('Cập nhật nội dung thông báo thành công!', 'success');
      } else {
        ok = await sendPushApi(payload);
        if (ok) showToast(`Đã bắn thông báo "${payload.title}" đến toàn bộ thiết bị App thành công!`, 'success');
      }

      if (!ok) {
        showToast('Lỗi khi lưu thông báo vào MySQL', 'error');
      } else {
        closePushModal();
        await reloadPushHistory();
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}
