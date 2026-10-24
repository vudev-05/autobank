import { checkAuth, initSidebar, showToast, fetchOrders, saveOrderApi, approveOrderApi, deleteOrderApi, loadConfig } from './admin-core.js';

let ordersList = [];

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('orders');

  await reloadOrdersList();
  initAddAndEditModals();
  initTableEventDelegation();
});

async function reloadOrdersList() {
  const allOrders = await fetchOrders();
  // Bỏ hẳn chờ chuyển khoản, chỉ lấy đơn hàng thành công (PAID / SUCCESS)
  ordersList = allOrders.filter(o => isPaid(o.status));
  renderOrders();
}

function renderOrders() {
  const tbody = document.getElementById('admin-orders-table-body');
  const countBadge = document.getElementById('admin-badge-orders');
  if (!tbody) return;

  const totalRevenue = ordersList.reduce((acc, o) => acc + Number(o.totalAmount || o.amount || 0), 0);

  const elStatPaid = document.getElementById('stat-paid-count');
  if (elStatPaid) elStatPaid.textContent = `● Thành công: ${ordersList.length} đơn`;

  const elStatRevenue = document.getElementById('stat-total-revenue');
  if (elStatRevenue) elStatRevenue.textContent = `● Doanh thu thực nhận: ${totalRevenue.toLocaleString('vi-VN')}đ`;

  if (countBadge) countBadge.textContent = ordersList.length;

  if (ordersList.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 30px;">Chưa ghi nhận giao dịch thành công nào.</td></tr>`;
    return;
  }

  tbody.innerHTML = ordersList.map(o => {
    const code = o.orderCode || o.code;
    return `
    <tr data-order-code="${code}">
      <td><strong style="color: #38bdf8; font-family: monospace;">${code}</strong></td>
      <td>${o.customerName || o.customer || o.customerPhone || o.phone || 'Khách hàng'}</td>
      <td>${o.description || o.pkg || 'Gói cước'}</td>
      <td><strong style="color: #4ade80;">${Number(o.totalAmount || o.amount || 0).toLocaleString('vi-VN')}đ</strong></td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${formatOrderDate(o.createdAt || o.date || o.time)}</td>
      <td>
        <span class="admin-badge admin-badge-success" style="padding: 4px 10px; font-weight: 700;">
          ✓ Thành công
        </span>
      </td>
      <td>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-code="${code}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-code="${code}">Xóa</button>
        </div>
      </td>
    </tr>
  `;
  }).join('');
}

function formatOrderDate(val) {
  if (!val) return 'Hôm nay';
  try {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + d.toLocaleDateString('vi-VN');
    }
  } catch (_) {}
  return String(val);
}

function isPaid(status) {
  const s = String(status || '').toUpperCase();
  return s === 'PAID' || s === 'SUCCESS' || s === 'COMPLETED';
}

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-orders-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    // Duyệt kích hoạt
    const approveBtn = e.target.closest('[data-action="approve"]');
    if (approveBtn) {
      const code = approveBtn.getAttribute('data-code');
      approveBtn.disabled = true;
      const ok = await approveOrderApi(code);
      if (ok) {
        showToast(`Đã duyệt kích hoạt đơn hàng ${code} thành công! Đồng bộ MySQL.`, 'success');
        await reloadOrdersList();
      } else {
        showToast(`Lỗi khi duyệt đơn hàng ${code}`, 'error');
        approveBtn.disabled = false;
      }
      return;
    }

    // Sửa đơn hàng
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const code = editBtn.getAttribute('data-code');
      openOrderModal(code);
      return;
    }

    // Xóa đơn hàng
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const code = delBtn.getAttribute('data-code');
      if (confirm(`Bạn có chắc chắn muốn xóa đơn hàng "${code}" khỏi cơ sở dữ liệu MySQL?`)) {
        delBtn.disabled = true;
        const ok = await deleteOrderApi(code);
        if (ok) {
          showToast(`Đã xóa đơn hàng ${code} khỏi MySQL thành công!`, 'success');
          await reloadOrdersList();
        } else {
          showToast(`Lỗi khi xóa đơn hàng ${code}`, 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }
  });
}

function openOrderModal(orderCode = null) {
  const modal = document.getElementById('admin-order-modal');
  const form = document.getElementById('form-save-order');
  if (!modal || !form) return;

  if (orderCode) {
    const o = ordersList.find(x => (x.orderCode || x.code) === orderCode);
    if (!o) return;
    document.getElementById('modal-order-title').textContent = `Chỉnh Sửa Đơn Hàng: ${orderCode}`;
    document.getElementById('edit-order-index').value = orderCode;
    document.getElementById('m-order-code').value = orderCode;
    document.getElementById('m-order-code').readOnly = true;
    document.getElementById('m-order-customer').value = o.customerName || o.customer || o.phone || '';
    const currentPkg = o.description || o.pkg || '1 Năm (tặng 2T)';
    const pkgSelect = document.getElementById('m-order-pkg');
    if (pkgSelect) {
      // Check if option exists, otherwise add it
      let found = false;
      for (let i = 0; i < pkgSelect.options.length; i++) {
        if (pkgSelect.options[i].value === currentPkg || pkgSelect.options[i].text.includes(currentPkg)) {
          pkgSelect.selectedIndex = i;
          found = true;
          break;
        }
      }
      if (!found && currentPkg) {
        const opt = document.createElement('option');
        opt.value = currentPkg;
        opt.textContent = currentPkg;
        opt.selected = true;
        pkgSelect.appendChild(opt);
      }
    }
    document.getElementById('m-order-amount').value = o.totalAmount || o.amount || 159000;
    document.getElementById('m-order-status').value = isPaid(o.status) ? 'PAID' : 'PENDING';
  } else {
    document.getElementById('modal-order-title').textContent = 'Thêm Đơn Hàng Mới Thủ Công';
    document.getElementById('edit-order-index').value = '';
    form.reset();
    document.getElementById('m-order-code').readOnly = false;
    const randCode = 'ORD-' + Math.floor(100000 + Math.random() * 900000);
    document.getElementById('m-order-code').value = randCode;
    const pkgSelect = document.getElementById('m-order-pkg');
    if (pkgSelect && pkgSelect.selectedOptions[0]) {
      const pVal = pkgSelect.selectedOptions[0].getAttribute('data-price');
      document.getElementById('m-order-amount').value = pVal || '159000';
    } else {
      document.getElementById('m-order-amount').value = '159000';
    }
  }

  modal.classList.add('is-open');
}

function closeOrderModal() {
  const modal = document.getElementById('admin-order-modal');
  if (modal) modal.classList.remove('is-open');
}

async function loadAndSyncOrderPackages() {
  const pkgSelect = document.getElementById('m-order-pkg');
  if (!pkgSelect) return;

  let pkgs = [];
  try {
    const res = await fetch(`${API_BASE}/admin/configs`, {
      headers: { 'Authorization': `Bearer ${getToken()}` },
    });
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data?.packages) && data.packages.length > 0) {
        pkgs = data.packages;
      }
    }
  } catch (e) {
    console.warn('Cannot fetch configs for orders modal, using local fallback:', e);
  }

  if (pkgs.length === 0) {
    const cfg = loadConfig();
    if (Array.isArray(cfg?.packages) && cfg.packages.length > 0) {
      pkgs = cfg.packages;
    }
  }

  const paidPkgs = pkgs.filter(p => p.price > 0 && p.isActive !== false);
  if (paidPkgs.length > 0) {
    pkgSelect.innerHTML = paidPkgs.map((p, idx) => `
      <option value="${p.name}" data-price="${p.price}" ${idx === 3 ? 'selected' : ''}>${p.name} (${Number(p.price).toLocaleString('vi-VN')}đ)</option>
    `).join('');
  }

  pkgSelect.onchange = () => {
    const opt = pkgSelect.selectedOptions[0];
    const pVal = opt ? opt.getAttribute('data-price') : '';
    if (pVal) document.getElementById('m-order-amount').value = pVal;
  };
}

function initAddAndEditModals() {
  const modal = document.getElementById('admin-order-modal');
  const addBtn = document.getElementById('btn-add-order');
  const closeBtn = document.getElementById('modal-order-close');
  const cancelBtn = document.getElementById('modal-order-cancel');
  const form = document.getElementById('form-save-order');

  if (closeBtn) closeBtn.onclick = closeOrderModal;
  if (cancelBtn) cancelBtn.onclick = closeOrderModal;
  if (addBtn) addBtn.onclick = () => openOrderModal(null);

  // Đồng bộ danh mục gói cước từ cấu hình Admin thực tế
  loadAndSyncOrderPackages();

  if (form && !form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const orderData = {
        orderCode: document.getElementById('m-order-code').value.trim(),
        customerName: document.getElementById('m-order-customer').value.trim(),
        description: document.getElementById('m-order-pkg').value,
        totalAmount: parseInt(document.getElementById('m-order-amount').value, 10),
        status: document.getElementById('m-order-status').value,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const ok = await saveOrderApi(orderData);
      if (ok) {
        showToast(`Đã lưu đơn hàng ${orderData.orderCode} vào MySQL thành công!`, 'success');
        closeOrderModal();
        await reloadOrdersList();
      } else {
        showToast('Lỗi khi lưu đơn hàng vào MySQL', 'error');
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}
