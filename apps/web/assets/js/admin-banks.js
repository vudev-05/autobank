import { checkAuth, initSidebar, showToast, fetchBanks, saveBankApi, toggleBankApi, deleteBankApi } from './admin-core.js';

let banksList = [];

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('banks');

  await reloadBanksList();
  initBankModal();
  initTableEventDelegation();
});

async function reloadBanksList() {
  banksList = await fetchBanks();
  renderBanks();
}

function renderBanks(filterKeyword = '') {
  const tbody = document.getElementById('admin-banks-table-body');
  const countBadge = document.getElementById('admin-badge-banks');
  if (!tbody) return;

  const kw = filterKeyword.toLowerCase().trim();
  const filtered = banksList.filter(b => {
    if (!kw) return true;
    return (b.name || '').toLowerCase().includes(kw) || 
           (b.pkg || '').toLowerCase().includes(kw) || 
           (b.code || '').toLowerCase().includes(kw) ||
           (b.app || '').toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = banksList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 30px;">Không tìm thấy ngân hàng nào phù hợp với từ khóa "${kw}".</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(b => `
    <tr data-bank-row="${b.id}">
      <td>
        <img src="${b.logo || 'https://cdn.vietqr.io/img/MB.png'}" alt="${b.name}" style="width: 38px; height: 38px; border-radius: 8px; object-fit: contain; background: #fff; padding: 3px;" onerror="this.src='https://cdn.vietqr.io/img/MB.png'" />
      </td>
      <td>
        <strong style="color: #fff; font-size: 0.95rem;">${b.name}</strong>
        <span style="font-size: 0.8rem; color: #94a3b8; display: block;">${b.app || b.name}</span>
      </td>
      <td>
        <code style="background: rgba(15,23,42,0.8); padding: 4px 8px; border-radius: 6px; font-size: 0.8rem; color: #38bdf8;">${b.pkg || b.id}</code>
      </td>
      <td>
        <span class="admin-badge admin-badge-info">${getCategoryLabel(b.category)}</span>
      </td>
      <td>
        <label class="admin-switch">
          <input type="checkbox" data-action="toggle" data-id="${b.id}" ${b.active ? 'checked' : ''} />
          <span class="admin-slider"></span>
        </label>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-id="${b.id}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-id="${b.id}" data-name="${b.name}">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');

  // Search input
  const searchInput = document.getElementById('admin-search-bank');
  if (searchInput && !searchInput.dataset.bound) {
    searchInput.dataset.bound = 'true';
    searchInput.addEventListener('input', (e) => renderBanks(e.target.value));
  }
}

function getCategoryLabel(cat) {
  switch (cat) {
    case 'neobank':
    case 'digital': return 'Ngân hàng số';
    case 'ewallet':
    case 'wallet': return 'Ví điện tử';
    case 'business':
    case 'corporate': return 'Doanh nghiệp';
    default: return 'Thương mại';
  }
}

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-banks-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const id = editBtn.getAttribute('data-id');
      openBankModal(id);
      return;
    }

    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const id = delBtn.getAttribute('data-id');
      const name = delBtn.getAttribute('data-name') || id;
      if (confirm(`Bạn có chắc chắn muốn xóa ngân hàng "${name}" khỏi toàn bộ hệ thống MySQL?`)) {
        delBtn.disabled = true;
        const ok = await deleteBankApi(id);
        if (ok) {
          showToast(`Đã xóa ngân hàng ${name} khỏi MySQL thành công!`);
          await reloadBanksList();
        } else {
          showToast(`Lỗi khi xóa ngân hàng ${name}`, 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }
  });

  tbody.addEventListener('change', async (e) => {
    const toggleInput = e.target.closest('[data-action="toggle"]');
    if (toggleInput) {
      const id = toggleInput.getAttribute('data-id');
      const bank = banksList.find(b => b.id === id);
      toggleInput.disabled = true;
      const ok = await toggleBankApi(id);
      if (ok) {
        showToast(`${toggleInput.checked ? 'Đã bật' : 'Đã tắt'} nhận thông báo ${bank?.name || id} trên MySQL & App!`);
        await reloadBanksList();
      } else {
        showToast('Không thể thay đổi trạng thái ngân hàng', 'error');
        toggleInput.disabled = false;
      }
    }
  });
}

function openBankModal(bankId = null) {
  const modal = document.getElementById('admin-bank-modal');
  const form = document.getElementById('form-save-bank');
  if (!modal || !form) return;

  let hiddenId = document.getElementById('edit-bank-id');
  if (!hiddenId) {
    hiddenId = document.getElementById('edit-bank-index');
  }

  if (bankId) {
    const b = banksList.find(x => x.id === bankId);
    if (!b) return;
    document.getElementById('modal-bank-title').textContent = `Chỉnh sửa: ${b.name}`;
    if (hiddenId) hiddenId.value = b.id;
    document.getElementById('m-bank-name').value = b.name || '';
    document.getElementById('m-bank-app').value = b.app || b.name || '';
    document.getElementById('m-bank-pkg').value = b.pkg || b.id || '';
    document.getElementById('m-bank-category').value = b.category || 'commercial';
    document.getElementById('m-bank-logo').value = b.logo || '';
    document.getElementById('m-bank-guide').value = b.guide || '';
  } else {
    document.getElementById('modal-bank-title').textContent = 'Thêm Ngân Hàng Mới (Lưu MySQL)';
    if (hiddenId) hiddenId.value = '';
    form.reset();
  }

  modal.classList.add('is-open');
}

function closeBankModal() {
  const modal = document.getElementById('admin-bank-modal');
  if (modal) modal.classList.remove('is-open');
}

function initBankModal() {
  const modal = document.getElementById('admin-bank-modal');
  const addBtn = document.getElementById('btn-add-bank');
  const closeBtn = document.getElementById('modal-bank-close');
  const cancelBtn = document.getElementById('modal-bank-cancel');
  const form = document.getElementById('form-save-bank');

  if (!modal || !form) return;

  if (addBtn) addBtn.onclick = () => openBankModal(null);
  if (closeBtn) closeBtn.onclick = closeBankModal;
  if (cancelBtn) cancelBtn.onclick = closeBankModal;

  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeBankModal();
  });

  if (!form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      let hiddenId = document.getElementById('edit-bank-id') || document.getElementById('edit-bank-index');
      const existingId = hiddenId ? hiddenId.value.trim() : '';

      const name = document.getElementById('m-bank-name').value.trim();
      const app = document.getElementById('m-bank-app').value.trim();
      const pkg = document.getElementById('m-bank-pkg').value.trim();
      const category = document.getElementById('m-bank-category').value;
      const logo = document.getElementById('m-bank-logo').value.trim();
      const guide = document.getElementById('m-bank-guide').value.trim();

      const bankId = (existingId && existingId !== '-1') 
        ? existingId 
        : name.toLowerCase().replace(/[^a-z0-9]/g, '');

      const payload = {
        id: bankId,
        code: name.toUpperCase().replace(/\s+/g, ''),
        name,
        app,
        pkg,
        category,
        logo,
        guide,
        isActive: true,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const ok = await saveBankApi(payload);
      if (ok) {
        showToast(`Đã lưu ngân hàng "${name}" vào MySQL thành công!`, 'success');
        closeBankModal();
        await reloadBanksList();
      } else {
        showToast('Lỗi khi lưu ngân hàng vào MySQL', 'error');
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}
