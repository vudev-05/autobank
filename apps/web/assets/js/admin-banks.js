import { checkAuth, initSidebar, showToast, loadBanks, saveBanks, API_BASE } from './admin-core.js';

let banksList = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('banks');

  banksList = loadBanks();
  renderBanks();
});

function renderBanks(filterKeyword = '') {
  const tbody = document.getElementById('admin-banks-table-body');
  const countBadge = document.getElementById('admin-badge-banks');
  if (!tbody) return;

  const kw = filterKeyword.toLowerCase().trim();
  const filtered = banksList.filter(b => {
    if (!kw) return true;
    return b.name.toLowerCase().includes(kw) || b.app.toLowerCase().includes(kw) || b.pkg.toLowerCase().includes(kw);
  });

  if (countBadge) countBadge.textContent = banksList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 30px;">Không tìm thấy ngân hàng nào phù hợp.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map((b, idx) => `
    <tr>
      <td>
        <img src="${b.logo}" alt="${b.name}" style="width: 36px; height: 36px; border-radius: 8px; object-fit: contain; background: #fff; padding: 2px; border: 1px solid #e2e8f0;" onerror="this.src='../assets/images/favicon.png'" />
      </td>
      <td>
        <strong style="color: #fff; font-size: 0.92rem;">${b.name}</strong>
      </td>
      <td>
        <div style="font-weight: 600; color: #38bdf8;">${b.app}</div>
        <code style="font-size: 0.75rem; color: #94a3b8;">${b.pkg}</code>
      </td>
      <td>
        <span class="admin-badge admin-badge-info">${getCategoryLabel(b.category)}</span>
      </td>
      <td style="max-width: 300px; font-size: 0.8rem; color: #94a3b8;">
        ${b.guide}
      </td>
      <td>
        <label class="admin-toggle">
          <input type="checkbox" ${b.active !== false ? 'checked' : ''} data-toggle-bank="${idx}" />
          <span class="admin-toggle-slider"></span>
        </label>
      </td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-bank="${idx}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-bank="${idx}">Xóa</button>
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

  attachBankActions();
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

function attachBankActions() {
  const modal = document.getElementById('admin-bank-modal');
  const addBtn = document.getElementById('btn-add-bank');
  const closeBtn = document.getElementById('modal-bank-close');
  const cancelBtn = document.getElementById('modal-bank-cancel');
  const form = document.getElementById('form-save-bank');

  if (addBtn) {
    addBtn.onclick = () => {
      document.getElementById('modal-bank-title').textContent = 'Thêm Ngân Hàng Mới';
      document.getElementById('edit-bank-index').value = '-1';
      form.reset();
      modal.classList.add('is-open');
    };
  }

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  document.querySelectorAll('[data-edit-bank]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-bank'), 10);
      const b = banksList[idx];
      if (!b) return;

      document.getElementById('modal-bank-title').textContent = `Chỉnh sửa: ${b.name}`;
      document.getElementById('edit-bank-index').value = idx;
      document.getElementById('m-bank-name').value = b.name;
      document.getElementById('m-bank-app').value = b.app;
      document.getElementById('m-bank-pkg').value = b.pkg;
      document.getElementById('m-bank-category').value = b.category || 'commercial';
      document.getElementById('m-bank-logo').value = b.logo;
      document.getElementById('m-bank-guide').value = b.guide;
      modal.classList.add('is-open');
    };
  });

  document.querySelectorAll('[data-toggle-bank]').forEach(chk => {
    chk.onchange = () => {
      const idx = parseInt(chk.getAttribute('data-toggle-bank'), 10);
      if (banksList[idx]) {
        banksList[idx].active = chk.checked;
        saveBanks(banksList);
        showToast(`${chk.checked ? 'Đã bật' : 'Đã tắt'} hiển thị ${banksList[idx].name}`);
      }
    };
  });

  document.querySelectorAll('[data-delete-bank]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-delete-bank'), 10);
      const b = banksList[idx];
      if (b && confirm(`Bạn có chắc chắn muốn xóa ngân hàng "${b.name}"?`)) {
        banksList.splice(idx, 1);
        saveBanks(banksList);
        renderBanks();
        showToast(`Đã xóa ngân hàng ${b.name}`);
      }
    };
  });

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = (e) => {
      e.preventDefault();
      const editIdx = parseInt(document.getElementById('edit-bank-index').value, 10);
      const newBank = {
        name: document.getElementById('m-bank-name').value.trim(),
        app: document.getElementById('m-bank-app').value.trim(),
        pkg: document.getElementById('m-bank-pkg').value.trim(),
        category: document.getElementById('m-bank-category').value,
        logo: document.getElementById('m-bank-logo').value.trim(),
        guide: document.getElementById('m-bank-guide').value.trim(),
        active: true,
      };

      if (editIdx >= 0 && banksList[editIdx]) {
        banksList[editIdx] = { ...banksList[editIdx], ...newBank };
        showToast(`Cập nhật ngân hàng ${newBank.name} thành công!`);
      } else {
        banksList.unshift(newBank);
        showToast(`Thêm mới ngân hàng ${newBank.name} thành công!`);
      }

      saveBanks(banksList);
      closeModal();
      renderBanks();
    };
  }
}
