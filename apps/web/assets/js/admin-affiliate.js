import { checkAuth, initSidebar, showToast, adminFetch, API_BASE } from './admin-core.js';

let affiliateData = {
  stats: { totalCommissionPaid: 0, pendingWithdrawalAmount: 0, totalReferralsCount: 0, pendingWithdrawalsCount: 0 },
  top3: [],
  withdrawals: [],
  referrals: [],
};

let currentFilter = 'ALL';

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('affiliate');

  loadAffiliateData();

  // Tab switching
  const tabBtnWithdrawals = document.getElementById('tab-btn-withdrawals');
  const tabBtnReferrals = document.getElementById('tab-btn-referrals');
  const tabContentWithdrawals = document.getElementById('tab-content-withdrawals');
  const tabContentReferrals = document.getElementById('tab-content-referrals');

  tabBtnWithdrawals?.addEventListener('click', () => {
    tabBtnWithdrawals.classList.add('active');
    tabBtnReferrals.classList.remove('active');
    tabContentWithdrawals.style.display = 'block';
    tabContentReferrals.style.display = 'none';
  });

  tabBtnReferrals?.addEventListener('click', () => {
    tabBtnReferrals.classList.add('active');
    tabBtnWithdrawals.classList.remove('active');
    tabContentReferrals.style.display = 'block';
    tabContentWithdrawals.style.display = 'none';
  });

  // Filter buttons for withdrawals
  document.querySelectorAll('.filter-wd-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.filter-wd-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      currentFilter = btn.getAttribute('data-filter') || 'ALL';
      renderWithdrawalsTable();
    });
  });

  // Refresh button
  document.getElementById('btn-refresh-affiliate')?.addEventListener('click', () => {
    loadAffiliateData(true);
  });

  // Modal reject
  const modalReject = document.getElementById('modal-reject');
  const formReject = document.getElementById('form-reject-withdrawal');
  const btnCloseModal = document.getElementById('modal-reject-close');
  const btnCancelModal = document.getElementById('modal-reject-cancel');

  const closeModal = () => {
    if (modalReject) modalReject.classList.remove('active');
    if (formReject) formReject.reset();
  };

  btnCloseModal?.addEventListener('click', closeModal);
  btnCancelModal?.addEventListener('click', closeModal);

  formReject?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('reject-wd-id')?.value;
    const reason = document.getElementById('reject-reason')?.value.trim();
    if (!id || !reason) return;

    try {
      const res = await adminFetch(`${API_BASE}/admin/affiliate/withdrawals/${id}/reject`, {
        method: 'POST',
        body: JSON.stringify({ reason }),
      });
      const data = await res.json();
      if (res.ok) {
        showToast(data.message || 'Đã từ chối lệnh rút và hoàn lại số dư', 'success');
        closeModal();
        loadAffiliateData();
      } else {
        showToast(data.message || 'Lỗi khi từ chối lệnh rút', 'error');
      }
    } catch (err) {
      showToast(`Lỗi: ${err.message}`, 'error');
    }
  });
});

async function loadAffiliateData(showFeedback = false) {
  try {
    const res = await adminFetch(`${API_BASE}/admin/affiliate/overview`);
    if (res.ok) {
      affiliateData = await res.json();
      renderStats();
      renderTop3();
      renderWithdrawalsTable();
      renderReferralsTable();
      if (showFeedback) showToast('Đã làm mới dữ liệu giới thiệu & rút tiền thành công!', 'success');
    }
  } catch (err) {
    console.error('Lỗi nạp dữ liệu affiliate:', err);
    if (showFeedback) showToast(`Không thể tải dữ liệu: ${err.message}`, 'error');
  }
}

function renderStats() {
  const s = affiliateData.stats || {};
  const setEl = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };

  setEl('stat-total-paid', `${(s.totalCommissionPaid || 0).toLocaleString('vi-VN')} đ`);
  setEl('stat-pending-withdraw', `${(s.pendingWithdrawalAmount || 0).toLocaleString('vi-VN')} đ`);
  setEl('stat-pending-count', s.pendingWithdrawalsCount || 0);
  setEl('stat-total-referrals', s.totalReferralsCount || 0);
  setEl('count-withdrawals', (affiliateData.withdrawals || []).length);
  setEl('count-referrals', (affiliateData.referrals || []).length);
}

function renderTop3() {
  const container = document.getElementById('top3-podium-container');
  if (!container) return;

  const top3 = affiliateData.top3 || [];
  if (top3.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; color: #94a3b8; padding: 24px;">
        Chưa có đại lý nào đạt đủ điều kiện xếp hạng. Hãy chia sẻ mã giới thiệu ngay!
      </div>
    `;
    return;
  }

  const colors = [
    { bg: '#eab308', cardClass: 'top3-card-1', badgeClass: 'top3-badge-1', label: 'Quán Quân 🥇' },
    { bg: '#94a3b8', cardClass: 'top3-card-2', badgeClass: 'top3-badge-2', label: 'Á Quân 🥈' },
    { bg: '#f97316', cardClass: 'top3-card-3', badgeClass: 'top3-badge-3', label: 'Hạng Ba 🥉' },
  ];

  container.innerHTML = top3.map((u, i) => {
    const c = colors[i] || colors[0];
    const initial = (u.name || u.email || 'A').charAt(0).toUpperCase();
    return `
      <div class="top3-card ${c.cardClass}">
        <div class="top3-badge ${c.badgeClass}">${c.label}</div>
        <div class="top3-avatar" style="background: ${c.bg};">${initial}</div>
        <div class="top3-name">${u.name || 'Đại lý VIP'}</div>
        <div class="top3-code">Mã: ${u.code || '------'} · ${u.email || ''}</div>
        <div class="top3-amount">+${(u.totalEarned || 0).toLocaleString('vi-VN')} đ</div>
        <div class="top3-sub">Đã mời thành công <strong>${u.count || 0}</strong> khách hàng</div>
      </div>
    `;
  }).join('');
}

function renderWithdrawalsTable() {
  const tbody = document.getElementById('table-withdrawals-body');
  if (!tbody) return;

  const list = (affiliateData.withdrawals || []).filter((w) => {
    if (currentFilter === 'ALL') return true;
    return w.status === currentFilter;
  });

  if (list.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="9" style="text-align: center; color: #94a3b8; padding: 28px;">
          Không có lệnh rút tiền nào ở bộ lọc này.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = list.map((w) => {
    let statusBadge = `<span class="badge-status badge-pending">Chờ duyệt</span>`;
    if (w.status === 'APPROVED') {
      statusBadge = `<span class="badge-status badge-approved">Đã duyệt</span>`;
    } else if (w.status === 'REJECTED') {
      statusBadge = `<span class="badge-status badge-rejected" title="${w.rejectReason || ''}">Từ chối</span>`;
    }

    const isPending = w.status === 'PENDING' || w.status === 'Chờ duyệt';

    return `
      <tr>
        <td><strong style="color: #38bdf8;">${w.id}</strong></td>
        <td>
          <div style="font-weight: 600; color: #fff;">${w.referralCode}</div>
          <small style="color: #94a3b8;">${w.userEmail || ''}</small>
        </td>
        <td><strong style="color: #38bdf8;">${w.bankName}</strong></td>
        <td><code style="background: rgba(15,23,42,0.6); padding: 2px 6px; border-radius: 4px; color: #e2e8f0; font-weight: bold;">${w.accountNumber}</code></td>
        <td style="font-weight: 600; text-transform: uppercase;">${w.accountHolder}</td>
        <td><strong style="color: #10b981; font-size: 0.95rem;">${Number(w.amount || 0).toLocaleString('vi-VN')} đ</strong></td>
        <td style="color: #94a3b8; font-size: 0.8rem;">${w.date || ''}</td>
        <td>${statusBadge}</td>
        <td style="text-align: right;">
          ${isPending ? `
            <div style="display: inline-flex; gap: 6px;">
              <button type="button" class="admin-btn admin-btn-sm btn-approve" data-id="${w.id}" style="background: #10b981; color: #fff; padding: 4px 10px;">
                ✓ Duyệt
              </button>
              <button type="button" class="admin-btn admin-btn-sm btn-reject" data-id="${w.id}" style="background: #ef4444; color: #fff; padding: 4px 10px;">
                ✕ Từ chối
              </button>
            </div>
          ` : `
            <span style="color: #64748b; font-size: 0.8rem;">Đã xử lý</span>
          `}
        </td>
      </tr>
    `;
  }).join('');

  // Attach button events
  tbody.querySelectorAll('.btn-approve').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-id');
      approveWithdrawal(id);
    });
  });

  tbody.querySelectorAll('.btn-reject').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-id');
      openRejectModal(id);
    });
  });
}

function renderReferralsTable() {
  const tbody = document.getElementById('table-referrals-body');
  if (!tbody) return;

  const list = affiliateData.referrals || [];
  if (list.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align: center; color: #94a3b8; padding: 28px;">
          Chưa có lượt giới thiệu nào được ghi nhận.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = list.map((r) => `
    <tr>
      <td><strong style="color: #a855f7;">${r.id}</strong></td>
      <td>
        <div style="font-weight: 600; color: #fff;">Mã: ${r.referrerCode}</div>
        <small style="color: #94a3b8;">${r.referrerEmail || ''}</small>
      </td>
      <td>
        <div style="font-weight: 600; color: #38bdf8;">${r.invitedName || 'Khách hàng'}</div>
        <small style="color: #94a3b8;">${r.invitedEmail || ''}</small>
      </td>
      <td>
        <span style="background: rgba(56, 189, 248, 0.15); color: #38bdf8; padding: 3px 8px; border-radius: 6px; font-weight: 700; font-size: 0.8rem;">
          ${r.packageName}
        </span>
      </td>
      <td>
        <strong style="color: #10b981; font-size: 0.95rem;">+${Number(r.commissionAmount || 0).toLocaleString('vi-VN')} đ</strong>
      </td>
      <td style="color: #94a3b8; font-size: 0.8rem;">${r.date || ''}</td>
    </tr>
  `).join('');
}

async function approveWithdrawal(id) {
  if (!confirm(`Xác nhận duyệt chuyển tiền cho lệnh rút #${id}? Bạn hãy chắc chắn đã chuyển khoản cho đối tác qua ngân hàng.`)) {
    return;
  }

  try {
    const res = await adminFetch(`${API_BASE}/admin/affiliate/withdrawals/${id}/approve`, {
      method: 'POST',
    });
    const data = await res.json();
    if (res.ok) {
      showToast(data.message || `Đã duyệt thành công lệnh rút #${id}`, 'success');
      loadAffiliateData();
    } else {
      showToast(data.message || 'Lỗi khi duyệt lệnh rút', 'error');
    }
  } catch (err) {
    showToast(`Lỗi: ${err.message}`, 'error');
  }
}

function openRejectModal(id) {
  const modal = document.getElementById('modal-reject');
  const inputId = document.getElementById('reject-wd-id');
  if (!modal || !inputId) return;
  inputId.value = id;
  modal.classList.add('active');
}
