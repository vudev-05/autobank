import { checkAuth, initSidebar, showToast, fetchStats, fetchUsers, fetchOrders, loadBanks } from './admin-core.js';

let revenueChartInstance = null;
let packageChartInstance = null;

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('overview');

  await refreshAllAnalytics();

  const refreshBtn = document.getElementById('btn-refresh-stats');
  if (refreshBtn) {
    refreshBtn.onclick = async () => {
      refreshBtn.disabled = true;
      const originalHtml = refreshBtn.innerHTML;
      refreshBtn.textContent = 'Đang tải...';
      await refreshAllAnalytics();
      refreshBtn.disabled = false;
      refreshBtn.innerHTML = originalHtml;
      showToast('Đã làm mới dữ liệu thống kê từ MySQL!');
    };
  }

  // Auto-refresh every 15s to capture live phone notifications and payments
  setInterval(refreshAllAnalytics, 15000);
});

async function refreshAllAnalytics() {
  const [stats, users, orders] = await Promise.all([
    fetchStats(),
    fetchUsers(),
    fetchOrders(),
  ]);

  // Update sidebar badges
  const usersBadge = document.getElementById('admin-badge-users');
  if (usersBadge) usersBadge.textContent = users.length;

  const ordersBadge = document.getElementById('admin-badge-orders');
  if (ordersBadge) ordersBadge.textContent = orders.length;

  const banksBadge = document.getElementById('admin-badge-banks');
  if (banksBadge) banksBadge.textContent = loadBanks().length;

  // 1. KPI Cards
  renderKpiCards(stats, users, orders);

  // 2. Sub-stats Pills
  renderSubstatPills(users);

  // 3. Render Interactive Charts
  renderCharts(orders, users);

  // 4. Render Revenue & Orders Table
  renderRevenueTable(orders);

  // 5. Render Detailed Accounts Table
  renderAccountsTable(users);
}

function renderKpiCards(stats, users = [], orders = []) {
  // Card 1: Total Users
  const totalUsersEl = document.getElementById('stat-total-users');
  const usersBreakdownEl = document.getElementById('stat-users-breakdown');
  if (totalUsersEl) {
    totalUsersEl.textContent = users.length.toLocaleString('vi-VN');
  }
  if (usersBreakdownEl && stats?.users) {
    usersBreakdownEl.innerHTML = `<span class="positive">● ${stats.users.active} hoạt động</span> · ${stats.users.trial} dùng thử`;
  }

  // Card 2: Revenue
  const revenueEl = document.getElementById('stat-revenue');
  const revenueBreakdownEl = document.getElementById('stat-revenue-breakdown');
  const paidOrders = orders.filter(o => String(o.status || '').toUpperCase() === 'PAID');
  const totalRev = paidOrders.reduce((sum, o) => sum + Number(o.totalAmount || o.amount || 0), 0);
  if (revenueEl) {
    revenueEl.textContent = totalRev.toLocaleString('vi-VN') + 'đ';
  }
  if (revenueBreakdownEl) {
    revenueBreakdownEl.innerHTML = `<span class="positive">▲ ${paidOrders.length} gói</span> thanh toán VietQR`;
  }

  // Card 3: Bank Transactions
  const todayTxEl = document.getElementById('stat-today-tx');
  const txBreakdownEl = document.getElementById('stat-tx-breakdown');
  if (todayTxEl && stats?.transactions) {
    todayTxEl.textContent = (stats.transactions.totalCount || 0).toLocaleString('vi-VN');
  }
  if (txBreakdownEl && stats?.transactions) {
    const amt = Number(stats.transactions.todayAmount || 0);
    txBreakdownEl.innerHTML = `Hôm nay: <strong>${amt > 0 ? amt.toLocaleString('vi-VN') + 'đ' : '0đ'}</strong>`;
  }

  // Card 4: Active Rate
  const activeRateEl = document.getElementById('stat-active-rate');
  const rateBreakdownEl = document.getElementById('stat-rate-breakdown');
  if (activeRateEl) {
    const activeCount = users.filter(u => u.status === 'ACTIVE').length;
    const rate = users.length > 0 ? Math.round((activeCount / users.length) * 100) : 100;
    activeRateEl.textContent = `${rate}%`;
  }
  if (rateBreakdownEl) {
    rateBreakdownEl.innerHTML = `<span class="positive">● Đang hoạt động tốt 24/7</span>`;
  }
}

function renderSubstatPills(users = []) {
  let vipCount = 0;
  let trialCount = 0;
  let pendingCount = 0;

  users.forEach(u => {
    const pkg = (u.packagePlan || u.pkg || '').toLowerCase();
    if (pkg.includes('1 năm') || pkg.includes('365')) {
      vipCount++;
    } else if (pkg.includes('dùng thử') || pkg.includes('trial')) {
      trialCount++;
    } else {
      pendingCount++;
    }
  });

  const vipEl = document.getElementById('pill-vip-users');
  if (vipEl) vipEl.textContent = `${vipCount} tài khoản`;

  const trialEl = document.getElementById('pill-trial-users');
  if (trialEl) trialEl.textContent = `${trialCount} tài khoản`;

  const pendingEl = document.getElementById('pill-pending-users');
  if (pendingEl) pendingEl.textContent = `${pendingCount} tài khoản`;
}

function renderCharts(orders = [], users = []) {
  if (typeof Chart === 'undefined') return;

  // Chart 1: Revenue Timeline Chart
  const revenueCanvas = document.getElementById('revenueChart');
  if (revenueCanvas) {
    const ctx = revenueCanvas.getContext('2d');
    const days = 7;
    const labels = [];
    const revenueData = [];

    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dayStr = `${d.getDate()}/${d.getMonth() + 1}`;
      labels.push(dayStr);

      const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0).getTime();
      const dayEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59).getTime();

      let dayTotal = 0;
      orders.forEach(o => {
        if (String(o.status || '').toUpperCase() === 'PAID') {
          const t = new Date(o.createdAt || o.date).getTime();
          if (t >= dayStart && t <= dayEnd) {
            dayTotal += Number(o.totalAmount || o.amount || 0);
          }
        }
      });
      revenueData.push(dayTotal);
    }

    if (revenueChartInstance) {
      revenueChartInstance.destroy();
    }

    revenueChartInstance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Doanh thu (VNĐ)',
          data: revenueData,
          borderColor: '#38bdf8',
          backgroundColor: 'rgba(56, 189, 248, 0.12)',
          borderWidth: 3,
          tension: 0.35,
          fill: true,
          pointBackgroundColor: '#38bdf8',
          pointBorderColor: '#fff',
          pointRadius: 4,
          pointHoverRadius: 6,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (ctx) => ` Doanh thu: ${Number(ctx.raw).toLocaleString('vi-VN')}đ`
            }
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#94a3b8', font: { size: 11 } }
          },
          y: {
            beginAtZero: true,
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: {
              color: '#94a3b8',
              font: { size: 11 },
              callback: (v) => `${Number(v).toLocaleString('vi-VN')}đ`
            }
          }
        }
      }
    });
  }

  // Chart 2: Package Distribution Donut Chart
  const packageCanvas = document.getElementById('packageDonutChart');
  if (packageCanvas) {
    const ctx = packageCanvas.getContext('2d');
    let c1y = 0, c6m = 0, c3m = 0, c1m = 0, cTrial = 0, cOther = 0;

    users.forEach(u => {
      const p = (u.packagePlan || u.pkg || '').toLowerCase();
      if (p.includes('1 năm') || p.includes('365')) c1y++;
      else if (p.includes('6 tháng')) c6m++;
      else if (p.includes('3 tháng')) c3m++;
      else if (p.includes('1 tháng')) c1m++;
      else if (p.includes('dùng thử') || p.includes('trial')) cTrial++;
      else cOther++;
    });

    if (users.length === 0) cTrial = 1; // placeholder if empty

    if (packageChartInstance) {
      packageChartInstance.destroy();
    }

    packageChartInstance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Gói 1 Năm', 'Gói 6 Tháng', 'Gói 3 Tháng', 'Gói 1 Tháng', 'Dùng Thử', 'Chưa Kích Hoạt'],
        datasets: [{
          data: [c1y, c6m, c3m, c1m, cTrial, cOther],
          backgroundColor: [
            '#0284c7', // 1 năm
            '#38bdf8', // 6 tháng
            '#10b981', // 3 tháng
            '#f59e0b', // 1 tháng
            '#fbbf24', // Dùng thử
            '#475569', // Chưa kích hoạt
          ],
          borderWidth: 2,
          borderColor: '#131c31',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#cbd5e1',
              boxWidth: 12,
              padding: 12,
              font: { size: 11 }
            }
          }
        },
        cutout: '68%',
      }
    });
  }
}

function renderRevenueTable(orders = []) {
  const tbody = document.getElementById('overview-orders-body');
  if (!tbody) return;

  if (!orders || orders.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" style="text-align: center; color: #94a3b8; padding: 36px;">
          Chưa có đơn hàng nào phát sinh trong cơ sở dữ liệu MySQL.<br>
          <small style="color: #64748b; margin-top: 4px; display: block;">Khi khách hàng quét mã VietQR mua gói trên trang web hoặc nạp gói trên app, lịch sử thanh toán sẽ xuất hiện ngay tại đây.</small>
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = orders.map(o => {
    const isPaid = String(o.status || '').toUpperCase() === 'PAID';
    const amount = Number(o.totalAmount || o.amount || 0);
    const dateStr = formatDate(o.createdAt || o.date);

    return `
      <tr>
        <td><strong style="color: #38bdf8; font-family: monospace;">${o.orderCode || o.code}</strong></td>
        <td>
          <div style="font-weight: 600; color: #fff;">${o.customerName || o.customer || 'Khách hàng'}</div>
          <small style="color: #94a3b8;">${o.customerPhone || o.phone || ''}</small>
        </td>
        <td><span class="admin-badge admin-badge-info">${o.description || o.pkg || 'Gói cước'}</span></td>
        <td><strong style="color: #fff; font-size: 0.95rem;">${amount.toLocaleString('vi-VN')}đ</strong></td>
        <td><span style="color: #38bdf8; font-weight: 600;">VietQR 24/7</span></td>
        <td style="color: #94a3b8; font-size: 0.82rem;">${dateStr}</td>
        <td>
          <span class="admin-badge ${isPaid ? 'admin-badge-success' : 'admin-badge-warning'}">
            ${isPaid ? '✓ Đã kích hoạt' : 'Chờ chuyển khoản'}
          </span>
        </td>
      </tr>
    `;
  }).join('');
}

function renderAccountsTable(users = []) {
  const tbody = document.getElementById('overview-users-body');
  if (!tbody) return;

  if (!users || users.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align: center; color: #94a3b8; padding: 36px;">
          Chưa có tài khoản người dùng nào đăng ký trên hệ thống.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = users.map(u => {
    const initial = (u.name || 'U').charAt(0).toUpperCase();
    const expiryDate = u.expiresAt || u.expires;
    const isExp = expiryDate ? new Date(expiryDate) < new Date() : false;
    const daysLeft = expiryDate ? Math.ceil((new Date(expiryDate) - new Date()) / (86400000)) : 0;

    let countdownText = `${daysLeft} ngày`;
    if (daysLeft < 0) countdownText = 'Đã hết hạn';
    else if (daysLeft === 0) countdownText = 'Hôm nay';

    return `
      <tr>
        <td>
          <div style="display: flex; align-items: center; gap: 10px;">
            <div style="width: 32px; height: 32px; border-radius: 50%; background: linear-gradient(135deg, #0284c7, #10b981); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 0.8rem;">
              ${initial}
            </div>
            <div>
              <strong style="color: #fff; display: block;">${u.name || 'Người dùng'}</strong>
              <small style="color: #38bdf8;">Chủ Shop</small>
            </div>
          </div>
        </td>
        <td>
          <span style="color: #cbd5e1; font-family: monospace; font-size: 0.85rem;">${u.email}</span>
        </td>
        <td>
          <div style="color: #fff; font-weight: 600;">${u.device || 'Samsung Galaxy'}</div>
          <small style="color: #94a3b8;">v${u.version || '1.2.0'}</small>
        </td>
        <td>
          <span class="admin-badge admin-badge-info">${u.packagePlan || u.pkg || '1 Năm'}</span>
        </td>
        <td>
          <div style="color: ${isExp ? '#ef4444' : '#10b981'}; font-weight: 700;">
            ${formatDateOnly(expiryDate)}
          </div>
          <small style="color: #94a3b8;">(${countdownText})</small>
        </td>
        <td>
          <span class="admin-badge ${u.status === 'BLOCKED' ? 'admin-badge-danger' : (isExp ? 'admin-badge-warning' : 'admin-badge-success')}">
            ${u.status === 'BLOCKED' ? 'Đã khóa' : (isExp ? 'Hết hạn' : 'Đang hoạt động')}
          </span>
        </td>
      </tr>
    `;
  }).join('');
}

function formatDate(val) {
  if (!val) return 'Hôm nay';
  try {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + d.toLocaleDateString('vi-VN');
    }
  } catch (_) {}
  return String(val);
}

function formatDateOnly(val) {
  if (!val) return '2027-10-10';
  try {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return d.toLocaleDateString('vi-VN');
    }
  } catch (_) {}
  return String(val).slice(0, 10);
}

