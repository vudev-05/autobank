import { checkAuth, initSidebar, showToast, fetchCoupons, saveCouponApi, toggleCouponApi, deleteCouponApi } from './admin-core.js';

let couponsList = [];

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('coupons');

  await reloadCouponsList();
  initCouponModal();
  initTableEventDelegation();
});

async function reloadCouponsList() {
  couponsList = await fetchCoupons();
  renderCoupons();
}

function renderCoupons() {
  const tbody = document.getElementById('admin-coupons-table-body');
  const countBadge = document.getElementById('admin-badge-coupons');
  if (!tbody) return;

  if (countBadge) countBadge.textContent = couponsList.length;

  if (couponsList.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #94a3b8; padding: 30px;">Chưa có mã giảm giá nào trong hệ thống. Hãy bấm "+ Tạo Mã Giảm Giá Mới" để kích thích khách hàng nâng cấp gói!</td></tr>`;
    return;
  }

  tbody.innerHTML = couponsList.map(c => {
    let targetBadge = '<span class="admin-badge" style="background: rgba(56, 189, 248, 0.2); color: #38bdf8; font-weight: 700;">🌟 Toàn bộ người dùng</span>';
    if (c.targetAudience === 'NEW_1DAY') {
      targetBadge = '<span class="admin-badge" style="background: rgba(239, 68, 68, 0.2); color: #f87171; font-weight: 700;">⚡ Khách mới (24h / 1 ngày)</span>';
    } else if (c.targetAudience === 'NEW_2DAYS') {
      targetBadge = '<span class="admin-badge" style="background: rgba(249, 115, 22, 0.2); color: #fb923c; font-weight: 700;">🔥 Khách mới (48h / 2 ngày)</span>';
    } else if (c.targetAudience === 'NEW_3DAYS') {
      targetBadge = '<span class="admin-badge" style="background: rgba(245, 158, 11, 0.2); color: #fbbf24; font-weight: 700;">🎁 Khách mới (72h / 3 ngày)</span>';
    } else if (c.targetAudience === 'MANUAL') {
      targetBadge = '<span class="admin-badge" style="background: rgba(148, 163, 184, 0.2); color: #cbd5e1;">🔑 Nhập mã thủ công</span>';
    }

    const autoApplyBadge = c.autoApply !== false
      ? '<div style="color: #22c55e; font-weight: 700; font-size: 0.82rem; margin-top: 4px;">⚡ Tự động trừ thẳng tiền trên Web &amp; App</div>'
      : '<div style="color: #94a3b8; font-size: 0.8rem; margin-top: 4px;">Áp dụng khi nhập mã</div>';

    return `
    <tr data-coupon-id="${c.id}">
      <td>
        <strong style="color: #38bdf8; font-family: monospace; font-size: 1.05rem; letter-spacing: 1px;">
          ${c.code}
        </strong>
      </td>
      <td>
        <div style="font-weight: 600; color: #f8fafc;">${c.description || 'Ưu đãi'}</div>
        <div style="margin-top: 4px;">${targetBadge}</div>
        <small style="color: #64748b; font-size: 0.75rem;">Tạo lúc: ${formatDate(c.createdAt)}</small>
      </td>
      <td>
        ${c.discountPercent > 0 
          ? `<span class="admin-badge" style="background: rgba(16, 185, 129, 0.2); color: #34d399; font-weight: 800; font-size: 0.95rem;">Giảm ${c.discountPercent}%</span>`
          : `<span class="admin-badge" style="background: rgba(56, 189, 248, 0.2); color: #38bdf8; font-weight: 800; font-size: 0.95rem;">-${Number(c.discountAmount).toLocaleString('vi-VN')}đ</span>`
        }
      </td>
      <td>
        ${autoApplyBadge}
        <small style="color: #94a3b8;">${c.minPrice > 0 ? `Đơn từ ${Number(c.minPrice).toLocaleString('vi-VN')}đ` : 'Áp dụng mọi gói cước'}</small>
      </td>
      <td>
        <span class="admin-badge admin-badge-${c.isActive ? 'success' : 'danger'}">
          ${c.isActive ? 'Đang kích hoạt' : 'Tạm dừng'}
        </span>
      </td>
      <td>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          <button type="button" class="admin-btn ${c.isActive ? 'admin-btn-outline' : 'admin-btn-success'} admin-btn-sm" data-action="toggle" data-id="${c.id}">
            ${c.isActive ? 'Tạm Dừng' : 'Bật Mã'}
          </button>
          <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-id="${c.id}" data-code="${c.code}">
            Xóa
          </button>
        </div>
      </td>
    </tr>
  `;
  }).join('');
}

function formatDate(val) {
  if (!val) return 'Mới đây';
  try {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return d.toLocaleDateString('vi-VN');
    }
  } catch (_) {}
  return String(val);
}

function initTableEventDelegation() {
  const tbody = document.getElementById('admin-coupons-table-body');
  if (!tbody || tbody.dataset.delegated) return;
  tbody.dataset.delegated = 'true';

  tbody.addEventListener('click', async (e) => {
    // Toggle active
    const toggleBtn = e.target.closest('[data-action="toggle"]');
    if (toggleBtn) {
      const id = toggleBtn.getAttribute('data-id');
      toggleBtn.disabled = true;
      const ok = await toggleCouponApi(id);
      if (ok) {
        showToast('Đã cập nhật trạng thái mã giảm giá thành công!', 'success');
        await reloadCouponsList();
      } else {
        showToast('Không thể thay đổi trạng thái mã giảm giá', 'error');
        toggleBtn.disabled = false;
      }
      return;
    }

    // Delete
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const id = delBtn.getAttribute('data-id');
      const code = delBtn.getAttribute('data-code') || id;
      if (confirm(`Bạn có chắc chắn muốn xóa mã giảm giá "${code}" khỏi toàn bộ hệ thống MySQL?`)) {
        delBtn.disabled = true;
        const ok = await deleteCouponApi(id);
        if (ok) {
          showToast(`Đã xóa mã giảm giá ${code} thành công!`, 'success');
          await reloadCouponsList();
        } else {
          showToast('Lỗi khi xóa mã giảm giá', 'error');
          delBtn.disabled = false;
        }
      }
      return;
    }
  });
}

function openCouponModal() {
  const modal = document.getElementById('admin-coupon-modal');
  const form = document.getElementById('form-save-coupon');
  if (!modal || !form) return;
  form.reset();
  const activeEl = document.getElementById('m-coupon-active');
  if (activeEl) activeEl.checked = true;
  const autoEl = document.getElementById('m-coupon-auto-apply');
  if (autoEl) autoEl.checked = true;
  modal.classList.add('is-open');
}

function closeCouponModal() {
  const modal = document.getElementById('admin-coupon-modal');
  if (modal) modal.classList.remove('is-open');
}

window.adminOpenCouponModal = openCouponModal;
window.adminCloseCouponModal = closeCouponModal;

function initCouponModal() {
  const modal = document.getElementById('admin-coupon-modal');
  const btnAdd = document.getElementById('btn-add-coupon');
  const btnClose = document.getElementById('modal-coupon-close');
  const btnCancel = document.getElementById('modal-coupon-cancel');
  const form = document.getElementById('form-save-coupon');

  if (!modal || !form) return;

  if (btnAdd) btnAdd.onclick = openCouponModal;
  if (btnClose) btnClose.onclick = closeCouponModal;
  if (btnCancel) btnCancel.onclick = closeCouponModal;

  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeCouponModal();
  });

  if (!form.dataset.bound) {
    form.dataset.bound = 'true';
    form.onsubmit = async (e) => {
      e.preventDefault();
      const code = document.getElementById('m-coupon-code').value.trim().toUpperCase();
      const desc = document.getElementById('m-coupon-desc').value.trim();
      const pct = parseInt(document.getElementById('m-coupon-percent').value || '0', 10);
      const amt = parseInt(document.getElementById('m-coupon-amount').value || '0', 10);
      const targetAudience = document.getElementById('m-coupon-target')?.value || 'ALL';
      const minPrice = parseInt(document.getElementById('m-coupon-min-price').value || '0', 10);
      const autoApply = document.getElementById('m-coupon-auto-apply')?.checked ?? true;
      const isActive = document.getElementById('m-coupon-active')?.checked ?? true;

      if (!code) {
        showToast('Vui lòng nhập mã code giảm giá!', 'warning');
        return;
      }

      if (pct <= 0 && amt <= 0) {
        showToast('Vui lòng nhập mức giảm theo % hoặc số tiền VNĐ!', 'warning');
        return;
      }

      const payload = {
        code,
        description: desc,
        discountPercent: pct,
        discountAmount: amt,
        targetAudience,
        autoApply,
        minPrice,
        isActive,
      };

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const ok = await saveCouponApi(payload);
      if (ok) {
        showToast(`Đã lưu mã giảm giá ${code} thành công vào MySQL!`, 'success');
        closeCouponModal();
        await reloadCouponsList();
      } else {
        showToast('Lỗi khi lưu mã giảm giá vào máy chủ', 'error');
      }

      if (submitBtn) submitBtn.disabled = false;
    };
  }
}
