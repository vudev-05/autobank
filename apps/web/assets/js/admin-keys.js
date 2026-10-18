import { checkAuth, initSidebar, showToast, initCopyButtons, fetchApiKeys, saveApiKeyApi, deleteApiKeyApi, fetchServerKeys, saveServerKeysApi } from './admin-core.js';

let clientKeys = [];

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('keys');
  initCopyButtons();

  await reloadServerKeys();
  await reloadClientKeys();
  initKeyModal();
  initTableEventDelegation();

  // Save server keys button
  const saveServerBtn = document.getElementById('btn-save-server-keys');
  if (saveServerBtn) {
    saveServerBtn.onclick = async () => {
      saveServerBtn.disabled = true;
      const originalText = saveServerBtn.textContent;
      saveServerBtn.textContent = 'Đang lưu vào MySQL...';

      const data = {
        masterKey: document.getElementById('key-master-api').value.trim(),
        fcmKey: document.getElementById('key-fcm').value.trim(),
        webhookUrl: document.getElementById('key-webhook').value.trim(),
      };

      const ok = await saveServerKeysApi(data);
      saveServerBtn.disabled = false;
      saveServerBtn.textContent = originalText;

      if (ok) {
        showToast('Đã lưu Master API Key, FCM Server Key & Webhook Endpoint vào MySQL thành công!', 'success');
      } else {
        showToast('Lỗi khi lưu thông tin khóa máy chủ', 'error');
      }
    };
  }

  // Regen Master Key button
  const regenBtn = document.getElementById('btn-regen-keys');
  if (regenBtn) {
    regenBtn.onclick = () => {
      if (confirm('Bạn có chắc muốn cấp lại Master API Key ngẫu nhiên?')) {
        const rand = 'ak_live_' + Math.random().toString(36).substring(2, 12) + Math.random().toString(36).substring(2, 12) + '_2026';
        document.getElementById('key-master-api').value = rand;
        showToast('Đã sinh lại Master API Key mới! Nhớ bấm "Lưu Khóa Máy Chủ" để áp dụng vào MySQL.', 'info');
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

async function reloadServerKeys() {
  const keys = await fetchServerKeys();
  if (keys) {
    const masterEl = document.getElementById('key-master-api');
    if (masterEl && keys.masterKey) masterEl.value = keys.masterKey;
    const fcmEl = document.getElementById('key-fcm');
    if (fcmEl && keys.fcmKey !== undefined) fcmEl.value = keys.fcmKey;
    const webhookEl = document.getElementById('key-webhook');
    if (webhookEl && keys.webhookUrl) webhookEl.value = keys.webhookUrl;
  }
}

async function reloadClientKeys() {
  clientKeys = await fetchApiKeys();
  renderClientKeys();
}

function renderClientKeys() {
  const tbody = document.getElementById('admin-keys-table-body');
  if (!tbody) return;

  if (!clientKeys || clientKeys.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 24px;">Chưa có khóa API nào trong MySQL. Bấm nút "+ Thêm Khóa Kết Nối Mới" bên trên.</td></tr>`;
    return;
  }

  tbody.innerHTML = clientKeys.map(k => {
    const keyId = k.id || k.key;
    const dateFormatted = k.createdAt ? new Date(k.createdAt).toLocaleDateString('vi-VN') : (k.date || 'Mới tạo');
    return `
    <tr data-key-id="${keyId}">
      <td>
        <strong style="color: #fff; font-size: 0.92rem;">${k.name}</strong>
      </td>
      <td>
        <div style="display: flex; align-items: center; gap: 8px;">
          <code style="background: rgba(15,23,42,0.8); padding: 4px 8px; border-radius: 6px; font-size: 0.8rem; color: #38bdf8;">${k.key}</code>
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" style="padding: 2px 8px; font-size: 0.75rem;" data-action="copy" data-val="${k.key}">Chép</button>
        </div>
      </td>
      <td>
        <span class="admin-badge ${k.role === 'FULL' ? 'admin-badge-success' : 'admin-badge-info'}">${k.role}</span>
      </td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${dateFormatted}</td>
      <td>
        <span class="admin-badge ${k.status === 'ACTIVE' ? 'admin-badge-success' : 'admin-badge-danger'}">${k.status === 'ACTIVE' ? 'Kích hoạt' : 'Tạm khóa'}</span>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-id="${keyId}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-id="${keyId}" data-name="${k.name}">Xóa</button>
        </div>
      </td>
    </tr>
  `;
  }).join('');
}

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-keys-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    // Copy
    const copyBtn = e.target.closest('[data-action="copy"]');
    if (copyBtn) {
      const val = copyBtn.getAttribute('data-val');
      navigator.clipboard.writeText(val);
      const orig = copyBtn.textContent;
      copyBtn.textContent = 'Đã chép!';
      setTimeout(() => (copyBtn.textContent = orig), 1500);
      showToast('Đã sao chép khóa API vào clipboard!');
      return;
    }

    // Edit
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const id = editBtn.getAttribute('data-id');
      openKeyModal(id);
      return;
    }

    // Delete
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const id = delBtn.getAttribute('data-id');
      const name = delBtn.getAttribute('data-name') || id;
      if (confirm(`Bạn có chắc chắn muốn xóa khóa API "${name}"? Ứng dụng dùng key này sẽ bị ngắt kết nối.`)) {
        delBtn.disabled = true;
        const ok = await deleteApiKeyApi(id);
        if (ok) {
          showToast(`Đã xóa thành công khóa API "${name}" khỏi MySQL!`);
          await reloadClientKeys();
        } else {
          showToast('Lỗi khi xóa khóa API', 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }
  });
}

function openKeyModal(keyId = null) {
  const modal = document.getElementById('admin-clientkey-modal');
  const form = document.getElementById('form-save-key');
  if (!modal || !form) return;

  if (keyId) {
    const k = clientKeys.find(x => (x.id === keyId || x.key === keyId));
    if (!k) return;
    document.getElementById('modal-key-title').textContent = `Chỉnh sửa: ${k.name}`;
    document.getElementById('edit-key-index').value = k.key;
    document.getElementById('m-key-name').value = k.name;
    document.getElementById('m-key-value').value = k.key;
    document.getElementById('m-key-role').value = k.role || 'FULL';
    document.getElementById('m-key-status').value = k.status || 'ACTIVE';
  } else {
    document.getElementById('modal-key-title').textContent = 'Thêm Khóa Kết Nối Mới';
    document.getElementById('edit-key-index').value = '';
    form.reset();
    document.getElementById('m-key-value').value = 'ak_client_' + Math.random().toString(36).substring(2, 10) + Math.random().toString(36).substring(2, 10);
  }

  modal.classList.add('is-open');
}

function closeKeyModal() {
  const modal = document.getElementById('admin-clientkey-modal');
  if (modal) modal.classList.remove('is-open');
}

function initKeyModal() {
  const modal = document.getElementById('admin-clientkey-modal');
  const addBtn = document.getElementById('btn-add-client-key');
  const closeBtn = document.getElementById('modal-key-close');
  const cancelBtn = document.getElementById('modal-key-cancel');
  const form = document.getElementById('form-save-key');

  if (!modal || !form) return;

  if (closeBtn) closeBtn.onclick = closeKeyModal;
  if (cancelBtn) cancelBtn.onclick = closeKeyModal;
  if (addBtn) addBtn.onclick = () => openKeyModal(null);

  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeKeyModal();
  });

  if (!form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const item = {
        name: document.getElementById('m-key-name').value.trim(),
        key: document.getElementById('m-key-value').value.trim(),
        role: document.getElementById('m-key-role').value,
        status: document.getElementById('m-key-status').value,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const ok = await saveApiKeyApi(item);
      if (ok) {
        showToast(`Đã lưu khóa API "${item.name}" vào cơ sở dữ liệu MySQL thành công!`, 'success');
        closeKeyModal();
        await reloadClientKeys();
      } else {
        showToast('Lỗi khi lưu khóa API vào MySQL', 'error');
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}
