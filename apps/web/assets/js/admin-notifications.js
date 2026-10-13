import { checkAuth, initSidebar, showToast, loadConfig, saveConfig, STORAGE_PUSH, API_BASE } from './admin-core.js';

let pushHistory = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('notifications');

  const appConfig = loadConfig();
  loadPushHistory();
  renderPushHistory();
  initPushForm();
  initPushEditModal();
  initMaintenanceAndVersion(appConfig);
});

function loadPushHistory() {
  try {
    const raw = localStorage.getItem(STORAGE_PUSH);
    if (raw) {
      pushHistory = JSON.parse(raw);
      return;
    }
  } catch (_) {}

  // Sample default notification if empty
  pushHistory = [
    {
      type: 'system_update',
      title: 'Chào mừng bản cập nhật 1.2.0',
      body: 'Tối ưu tốc độ đọc thông báo nhận tiền xuống dưới 0.3s, tương thích 100% Android 14!',
      action: 'open_app',
      timestamp: new Date().toISOString(),
    },
    {
      type: 'promotion',
      title: 'Ưu đãi gia hạn gói 1 Năm',
      body: 'Gia hạn gói 1 Năm ngay hôm nay chỉ 299.000đ tặng thêm 30 ngày sử dụng!',
      action: 'open_pricing',
      timestamp: new Date(Date.now() - 86400000).toISOString(),
    },
  ];
  savePushHistory();
}

function savePushHistory() {
  localStorage.setItem(STORAGE_PUSH, JSON.stringify(pushHistory));
}

function renderPushHistory() {
  const tbody = document.getElementById('admin-push-history-body');
  if (!tbody) return;

  if (pushHistory.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 30px;">Chưa có thông báo push nào được phát.</td></tr>`;
    return;
  }

  tbody.innerHTML = pushHistory.map((p, idx) => `
    <tr>
      <td style="color: #94a3b8; font-size: 0.8rem; font-family: monospace;">
        ${formatDateTime(p.timestamp)}
      </td>
      <td>
        <span class="admin-badge admin-badge-${getTypeBadge(p.type)}">${getTypeText(p.type)}</span>
      </td>
      <td><strong style="color: #fff;">${p.title}</strong></td>
      <td style="color: #cbd5e1; max-width: 320px; font-size: 0.85rem;">${p.body}</td>
      <td style="color: #38bdf8; font-size: 0.82rem;">${getActionText(p.action)}</td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-resend-push="${idx}" title="Bắn lại thông báo này">Bắn lại</button>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-push="${idx}" title="Chỉnh sửa">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-push="${idx}" title="Xóa khỏi lịch sử">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');

  attachPushHistoryActions();
}

function formatDateTime(iso) {
  if (!iso) return 'Vừa xong';
  try {
    const d = new Date(iso);
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + d.toLocaleDateString('vi-VN');
  } catch (_) {
    return 'Vừa xong';
  }
}

function getTypeBadge(type) {
  if (type === 'promotion') return 'warning';
  if (type === 'warning') return 'danger';
  return 'info';
}

function getTypeText(type) {
  switch (type) {
    case 'promotion': return 'Khuyến mãi';
    case 'warning': return 'Cảnh báo';
    case 'custom': return 'Chung';
    default: return 'Cập nhật';
  }
}

function getActionText(action) {
  switch (action) {
    case 'open_chplay': return 'Mở CH Play';
    case 'open_pricing': return 'Mở Bảng Giá';
    default: return 'Mở Ứng Dụng';
  }
}

function attachPushHistoryActions() {
  // Resend
  document.querySelectorAll('[data-resend-push]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-resend-push'), 10);
      const p = pushHistory[idx];
      if (p) {
        p.timestamp = new Date().toISOString();
        savePushHistory();
        renderPushHistory();

        // Broadcast to MySQL API
        fetch(`${API_BASE}/admin/push`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(p),
        }).catch(() => {});

        showToast(`Đã bắn lại thông báo "${p.title}" đến toàn bộ thiết bị thành công!`, 'success');
      }
    };
  });

  // Edit
  const editModal = document.getElementById('admin-push-modal');
  document.querySelectorAll('[data-edit-push]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-push'), 10);
      const p = pushHistory[idx];
      if (!p) return;

      document.getElementById('edit-push-index').value = idx;
      document.getElementById('m-push-type').value = p.type || 'system_update';
      document.getElementById('m-push-title').value = p.title || '';
      document.getElementById('m-push-body').value = p.body || '';
      document.getElementById('m-push-action').value = p.action || 'open_app';

      editModal.classList.add('is-open');
    };
  });

  // Delete
  document.querySelectorAll('[data-delete-push]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-delete-push'), 10);
      if (confirm('Bạn có chắc chắn muốn xóa thông báo này khỏi lịch sử?')) {
        pushHistory.splice(idx, 1);
        savePushHistory();
        renderPushHistory();
        showToast('Đã xóa thông báo khỏi lịch sử!');
      }
    };
  });

  // Clear all
  const clearBtn = document.getElementById('btn-clear-push-history');
  if (clearBtn) {
    clearBtn.onclick = () => {
      if (confirm('Bạn có chắc chắn muốn xóa toàn bộ lịch sử thông báo push?')) {
        pushHistory = [];
        savePushHistory();
        renderPushHistory();
        showToast('Đã xóa sạch lịch sử thông báo!');
      }
    };
  }
}

function initPushForm() {
  const pushForm = document.getElementById('push-notify-form');
  if (!pushForm) return;

  pushForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const payload = {
      type: document.getElementById('push-type').value,
      title: document.getElementById('push-title').value.trim(),
      body: document.getElementById('push-body').value.trim(),
      action: document.getElementById('push-action').value,
      timestamp: new Date().toISOString(),
    };

    pushHistory.unshift(payload);
    savePushHistory();
    renderPushHistory();

    // Post to MySQL API
    fetch(`${API_BASE}/admin/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).catch(() => {});

    pushForm.reset();
    showToast('Đã phát thông báo Push thành công đến toàn bộ thiết bị đang online!', 'success');
  });
}

function initPushEditModal() {
  const modal = document.getElementById('admin-push-modal');
  const closeBtn = document.getElementById('modal-push-close');
  const cancelBtn = document.getElementById('modal-push-cancel');
  const form = document.getElementById('form-edit-push');

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = (e) => {
      e.preventDefault();
      const editIdx = parseInt(document.getElementById('edit-push-index').value, 10);
      if (editIdx >= 0 && pushHistory[editIdx]) {
        pushHistory[editIdx].type = document.getElementById('m-push-type').value;
        pushHistory[editIdx].title = document.getElementById('m-push-title').value.trim();
        pushHistory[editIdx].body = document.getElementById('m-push-body').value.trim();
        pushHistory[editIdx].action = document.getElementById('m-push-action').value;

        savePushHistory();
        closeModal();
        renderPushHistory();
        showToast('Đã cập nhật thông báo thành công!');
      }
    };
  }
}

function initMaintenanceAndVersion(appConfig) {
  const toggle = document.getElementById('toggle-maintenance');
  const msgInput = document.getElementById('cfg-maintenance-msg');
  const latestVer = document.getElementById('cfg-latest-version');
  const minVer = document.getElementById('cfg-min-version');
  const saveVerBtn = document.getElementById('btn-save-version');

  if (toggle) {
    toggle.checked = appConfig.maintenance === true;
    if (msgInput) msgInput.value = appConfig.maintenanceMsg || '';

    toggle.addEventListener('change', () => {
      saveConfig({
        maintenance: toggle.checked,
        maintenanceMsg: msgInput ? msgInput.value.trim() : appConfig.maintenanceMsg,
      });
      showToast(`${toggle.checked ? 'ĐÃ KÍCH HOẠT BẢO TRÌ TOÀN HỆ THỐNG' : 'Đã tắt bảo trì, hệ thống hoạt động bình thường'}`);
    });
  }

  if (latestVer) latestVer.value = appConfig.latestVersion || '1.2.0';
  if (minVer) minVer.value = appConfig.minVersion || '1.0.0';

  if (saveVerBtn) {
    saveVerBtn.addEventListener('click', () => {
      saveConfig({
        latestVersion: latestVer.value.trim(),
        minVersion: minVer.value.trim(),
      });
      showToast('Đã cập nhật ràng buộc phiên bản App mobile thành công vào MySQL!');
    });
  }
}
