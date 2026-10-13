import { checkAuth, initSidebar, showToast, initCopyButtons } from './admin-core.js';

const STORAGE_CLIENT_KEYS = 'autobank_client_api_keys';

const defaultClientKeys = [
  { name: 'AutoBank Android App Mobile (Production)', key: 'ak_mobile_android_live_9a8b7c6d', role: 'FULL', date: '2026-10-10 10:00:00', status: 'ACTIVE' },
  { name: 'Máy POS Quầy Thu Ngân 01', key: 'ak_pos_cashier_01_7e6d5c4b', role: 'READ_ONLY', date: '2026-10-10 14:30:00', status: 'ACTIVE' },
  { name: 'Webhook Nhận Biến Động Số Dư (VietQR)', key: 'ak_webhook_vietqr_listener_1192', role: 'WEBHOOK', date: '2026-10-11 08:15:00', status: 'ACTIVE' },
];

let clientKeys = [];

function loadClientKeys() {
  try {
    const raw = localStorage.getItem(STORAGE_CLIENT_KEYS);
    if (raw) return JSON.parse(raw);
  } catch (_) {}
  return [...defaultClientKeys];
}

function saveClientKeys(list) {
  localStorage.setItem(STORAGE_CLIENT_KEYS, JSON.stringify(list));
}

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('keys');
  initCopyButtons();

  clientKeys = loadClientKeys();
  renderClientKeys();

  // Load server keys from localStorage
  const savedServerKeys = JSON.parse(localStorage.getItem('autobank_server_keys') || '{}');
  if (savedServerKeys.masterKey) document.getElementById('key-master-api').value = savedServerKeys.masterKey;
  if (savedServerKeys.fcmKey) document.getElementById('key-fcm').value = savedServerKeys.fcmKey;
  if (savedServerKeys.webhookUrl) document.getElementById('key-webhook').value = savedServerKeys.webhookUrl;

  // Save server keys button
  const saveServerBtn = document.getElementById('btn-save-server-keys');
  if (saveServerBtn) {
    saveServerBtn.onclick = () => {
      const data = {
        masterKey: document.getElementById('key-master-api').value.trim(),
        fcmKey: document.getElementById('key-fcm').value.trim(),
        webhookUrl: document.getElementById('key-webhook').value.trim(),
      };
      localStorage.setItem('autobank_server_keys', JSON.stringify(data));
      showToast('Đã lưu Master API Key, FCM Server Key & Webhook Endpoint thành công!', 'success');
    };
  }

  // Regen Master Key button
  const regenBtn = document.getElementById('btn-regen-keys');
  if (regenBtn) {
    regenBtn.onclick = () => {
      if (confirm('Bạn có chắc muốn cấp lại Master API Key?')) {
        const rand = 'ak_live_' + Math.random().toString(36).substring(2, 12) + Math.random().toString(36).substring(2, 12) + '_2026';
        document.getElementById('key-master-api').value = rand;
        showToast('Đã sinh lại Master API Key mới! Nhớ bấm Lưu để áp dụng.', 'info');
      }
    };
  }

  // Random Client Token button in modal
  const genClientBtn = document.getElementById('btn-gen-client-token');
  if (genClientBtn) {
    genClientBtn.onclick = () => {
      const token = 'ak_client_' + Math.random().toString(36).substring(2, 10) + Math.random().toString(36).substring(2, 10);
      document.getElementById('m-key-value').value = token;
    };
  }
});

function renderClientKeys() {
  const tbody = document.getElementById('admin-keys-table-body');
  if (!tbody) return;

  if (clientKeys.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 24px;">Chưa có khóa API nào. Bấm nút "+ Thêm Khóa Kết Nối Mới" bên trên.</td></tr>`;
    return;
  }

  tbody.innerHTML = clientKeys.map((k, idx) => `
    <tr>
      <td>
        <strong style="color: #fff; font-size: 0.92rem;">${k.name}</strong>
      </td>
      <td>
        <div style="display: flex; align-items: center; gap: 8px;">
          <code style="background: rgba(15,23,42,0.8); padding: 4px 8px; border-radius: 6px; font-size: 0.8rem; color: #38bdf8;">${k.key}</code>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" style="padding: 2px 8px; font-size: 0.75rem;" data-copy-val="${k.key}">Chép</button>
        </div>
      </td>
      <td>
        <span class="admin-badge ${k.role === 'FULL' ? 'admin-badge-success' : 'admin-badge-info'}">${k.role}</span>
      </td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${k.date}</td>
      <td>
        <span class="admin-badge ${k.status === 'ACTIVE' ? 'admin-badge-success' : 'admin-badge-danger'}">${k.status}</span>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-key="${idx}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-key="${idx}">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');

  // Attach actions
  attachKeyActions();
}

function attachKeyActions() {
  const modal = document.getElementById('admin-clientkey-modal');
  const addBtn = document.getElementById('btn-add-client-key');
  const closeBtn = document.getElementById('modal-key-close');
  const cancelBtn = document.getElementById('modal-key-cancel');
  const form = document.getElementById('form-save-key');

  if (addBtn) {
    addBtn.onclick = () => {
      document.getElementById('modal-key-title').textContent = 'Thêm Khóa Kết Nối Mới';
      document.getElementById('edit-key-index').value = '-1';
      form.reset();
      document.getElementById('m-key-value').value = 'ak_client_' + Math.random().toString(36).substring(2, 10) + Math.random().toString(36).substring(2, 10);
      modal.classList.add('is-open');
    };
  }

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  // Copy quick buttons
  document.querySelectorAll('[data-copy-val]').forEach(btn => {
    btn.onclick = () => {
      const val = btn.getAttribute('data-copy-val');
      navigator.clipboard.writeText(val);
      const orig = btn.textContent;
      btn.textContent = 'Đã chép!';
      setTimeout(() => (btn.textContent = orig), 1500);
      showToast('Đã sao chép khóa API vào clipboard!');
    };
  });

  // Edit buttons
  document.querySelectorAll('[data-edit-key]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-key'), 10);
      const k = clientKeys[idx];
      if (!k) return;

      document.getElementById('modal-key-title').textContent = `Chỉnh sửa: ${k.name}`;
      document.getElementById('edit-key-index').value = idx;
      document.getElementById('m-key-name').value = k.name;
      document.getElementById('m-key-value').value = k.key;
      document.getElementById('m-key-role').value = k.role || 'FULL';
      document.getElementById('m-key-status').value = k.status || 'ACTIVE';
      modal.classList.add('is-open');
    };
  });

  // Delete buttons
  document.querySelectorAll('[data-delete-key]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-delete-key'), 10);
      const k = clientKeys[idx];
      if (k && confirm(`Bạn có chắc chắn muốn xóa khóa API "${k.name}"? Ứng dụng dùng key này sẽ bị ngắt kết nối.`)) {
        clientKeys.splice(idx, 1);
        saveClientKeys(clientKeys);
        renderClientKeys();
        showToast(`Đã xóa thành công khóa API "${k.name}"`);
      }
    };
  });

  // Form submit
  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = (e) => {
      e.preventDefault();
      const editIdx = parseInt(document.getElementById('edit-key-index').value, 10);
      const item = {
        name: document.getElementById('m-key-name').value.trim(),
        key: document.getElementById('m-key-value').value.trim(),
        role: document.getElementById('m-key-role').value,
        status: document.getElementById('m-key-status').value,
        date: new Date().toISOString().replace('T', ' ').slice(0, 19),
      };

      if (editIdx >= 0 && clientKeys[editIdx]) {
        clientKeys[editIdx] = { ...clientKeys[editIdx], ...item, date: clientKeys[editIdx].date };
        showToast(`Cập nhật khóa API "${item.name}" thành công!`);
      } else {
        clientKeys.unshift(item);
        showToast(`Thêm mới khóa API "${item.name}" thành công!`);
      }

      saveClientKeys(clientKeys);
      closeModal();
      renderClientKeys();
    };
  }
}
