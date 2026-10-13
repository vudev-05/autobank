import { checkAuth, initSidebar, showToast, fetchOrders, saveOrderApi, approveOrderApi, deleteOrderApi, API_BASE } from './admin-core.js';

let ordersList = [];

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('orders');

  await reloadOrdersList();
  initAddAndEditModals();
});

async function reloadOrdersList() {
  ordersList = await fetchOrders();
  renderOrders();
}

function renderOrders() {
  const tbody = document.getElementById('admin-orders-table-body');
  const countBadge = document.getElementById('admin-badge-orders');
  const filterSelect = document.getElementById('filter-order-status');
  if (!tbody) return;

  const filter = filterSelect ? filterSelect.value : 'all';
  const filtered = ordersList.filter(o => {
    if (filter === 'all') return true;
    const s = (o.status || '').toUpperCase();
    return s === filter.toUpperCase();
  });

  if (countBadge) countBadge.textContent = ordersList.length;

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 30px;">Chưa có đơn hàng nào trong hệ thống MySQL. Khi khách quét mã QR trên web hoặc nạp gói trên app, đơn sẽ xuất hiện tại đây!</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map((o, idx) => `
    <tr>
      <td><strong style="color: #38bdf8; font-family: monospace;">${o.orderCode || o.code}</strong></td>
      <td>${o.customerName || o.customer || o.customerPhone || o.phone || 'Khách hàng'}</td>
      <td>${o.description || o.pkg || 'Gói cước'}</td>
      <td><strong style="color: #fff;">${Number(o.totalAmount || o.amount || 0).toLocaleString('vi-VN')}đ</strong></td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${formatOrderDate(o.createdAt || o.date || o.time)}</td>
      <td>
        <span class="admin-badge admin-badge-${isPaid(o.status) ? 'success' : 'warning'}">
          ${isPaid(o.status) ? 'Đã kích hoạt' : 'Chờ chuyển khoản'}
        </span>
      </td>
      <td>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          ${!isPaid(o.status) ? `
            <button type="button" class="admin-btn admin-btn-success admin-btn-sm" data-approve-order="${idx}">Duyệt Kích Hoạt</button>
          ` : `
            <span style="color: #22c55e; font-size: 0.82rem; padding: 4px 6px; font-weight: 700;">✓ Hoàn tất</span>
          `}
          <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-edit-order="${idx}">Sửa</button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-delete-order="${idx}">Xóa</button>
        </div>
      </td>
    </tr>
  `).join('');

  attachOrderRowActions();

  if (filterSelect && !filterSelect.dataset.bound) {
    filterSelect.dataset.bound = 'true';
    filterSelect.addEventListener('change', renderOrders);
  }
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
  return s === 'PAID';
}

function attachOrderRowActions() {
  // Quick approve button
  document.querySelectorAll('[data-approve-order]').forEach(btn => {
    btn.onclick = async () => {
      const idx = parseInt(btn.getAttribute('data-approve-order'), 10);
      const o = ordersList[idx];
      if (o) {
        btn.disabled = true;
        const code = o.orderCode || o.code;
        await approveOrderApi(code);
        showToast(`Đã duyệt kích hoạt đơn hàng ${code} thành công! Đồng bộ MySQL.`);
        await reloadOrdersList();
      }
    };
  });

  // Edit order
  const modal = document.getElementById('admin-order-modal');
  document.querySelectorAll('[data-edit-order]').forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute('data-edit-order'), 10);
      const o = ordersList[idx];
      if (!o) return;

      document.getElementById('modal-order-title').textContent = `Chỉnh Sửa Đơn Hàng: ${o.orderCode || o.code}`;
      document.getElementById('edit-order-index').value = idx;
      document.getElementById('m-order-code').value = o.orderCode || o.code;
      document.getElementById('m-order-customer').value = o.customerName || o.customer || o.phone || '';
      document.getElementById('m-order-pkg').value = o.description || o.pkg || 'Gói 1 Năm';
      document.getElementById('m-order-amount').value = o.totalAmount || o.amount || 299000;
      document.getElementById('m-order-status').value = isPaid(o.status) ? 'PAID' : 'PENDING';

      modal.classList.add('is-open');
    };
  });

  // Delete order
  document.querySelectorAll('[data-delete-order]').forEach(btn => {
    btn.onclick = async () => {
      const idx = parseInt(btn.getAttribute('data-delete-order'), 10);
      const o = ordersList[idx];
      const code = o?.orderCode || o?.code;
      if (o && confirm(`Bạn có chắc chắn muốn xóa đơn hàng "${code}" khỏi MySQL?`)) {
        btn.disabled = true;
        await deleteOrderApi(code);
        showToast(`Đã xóa đơn hàng ${code} khỏi MySQL thành công!`);
        await reloadOrdersList();
      }
    };
  });
}

function initAddAndEditModals() {
  const modal = document.getElementById('admin-order-modal');
  const addBtn = document.getElementById('btn-add-order');
  const closeBtn = document.getElementById('modal-order-close');
  const cancelBtn = document.getElementById('modal-order-cancel');
  const form = document.getElementById('form-save-order');

  const closeModal = () => modal.classList.remove('is-open');
  if (closeBtn) closeBtn.onclick = closeModal;
  if (cancelBtn) cancelBtn.onclick = closeModal;

  if (addBtn) {
    addBtn.onclick = () => {
      document.getElementById('modal-order-title').textContent = 'Thêm Đơn Hàng Mới Thủ Công';
      document.getElementById('edit-order-index').value = '-1';
      form.reset();
      const randCode = 'ORD-' + Math.floor(100000 + Math.random() * 900000);
      document.getElementById('m-order-code').value = randCode;
      document.getElementById('m-order-amount').value = '299000';
      modal.classList.add('is-open');
    };
  }

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

      await saveOrderApi(orderData);
      showToast(`Đã lưu đơn hàng ${orderData.orderCode} vào MySQL thành công!`);

      if (submitBtn) submitBtn.disabled = false;
      closeModal();
      await reloadOrdersList();
    };
  }
}
