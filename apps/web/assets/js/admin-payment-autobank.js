import { checkAuth, initSidebar, showToast, adminFetch, API_BASE } from './admin-core.js';

document.addEventListener('DOMContentLoaded', async () => {
  if (!checkAuth()) return;
  initSidebar('payment-autobank');

  await loadConfig();
  await loadLogs();

  // Form submit
  document.getElementById('form-thueapi')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const submitBtn = document.getElementById('btn-save-thueapi');
    const originalBtnHtml = submitBtn.innerHTML;

    submitBtn.disabled = true;
    submitBtn.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="spin-icon"><circle cx="12" cy="12" r="10" stroke-opacity="0.25"/><path d="M12 2a10 10 0 0 1 10 10"/></svg>
      Đang lưu vào MySQL...
    `;

    const enabled = document.getElementById('thueapi-enabled').checked;
    const apiKey = document.getElementById('thueapi-key').value;
    const bankAcc = document.getElementById('thueapi-bankacc').value.trim();
    const bankCode = document.getElementById('thueapi-bankcode').value.trim();
    const bankName = document.getElementById('thueapi-bankname').value.trim();

    try {
      const res = await adminFetch(`${API_BASE}/admin/thueapi/config`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ enabled, apiKey, bankAcc, bankCode, bankName }),
      });

      if (res.ok) {
        submitBtn.style.background = '#10b981';
        submitBtn.style.borderColor = '#10b981';
        submitBtn.innerHTML = `
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          ✓ Đã lưu thành công vào MySQL!
        `;

        showToast(`✓ Đã lưu thành công vào cơ sở dữ liệu MySQL! Ngân hàng: ${bankCode} - STK: ${bankAcc}`, 'success');

        try {
          const localRaw = localStorage.getItem('autobank_system_config');
          const local = localRaw ? JSON.parse(localRaw) : {};
          const updated = { ...local, bankAcc, bankCode, bankName, vietqrBank: bankCode, vietqrAccount: bankAcc, vietqrName: bankName };
          localStorage.setItem('autobank_system_config', JSON.stringify(updated));

          const ch = new BroadcastChannel('autobank_live_channel');
          ch.postMessage({ type: 'CONFIG_UPDATED', config: updated });
          window.dispatchEvent(new CustomEvent('autobank_config_updated', { detail: updated }));
        } catch (_) {}

        await loadConfig();

        setTimeout(() => {
          submitBtn.disabled = false;
          submitBtn.style.background = '';
          submitBtn.style.borderColor = '';
          submitBtn.innerHTML = originalBtnHtml;
        }, 2500);
      } else {
        const errJson = await res.json().catch(() => ({}));
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalBtnHtml;
        showToast('Lưu cấu hình thất bại: ' + (errJson.message || res.statusText), 'error');
      }
    } catch (err) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = originalBtnHtml;
      showToast('Lỗi kết nối máy chủ: ' + err.message, 'error');
    }
  });

  // Test connection
  document.getElementById('btn-test-connection')?.addEventListener('click', async () => {
    const box = document.getElementById('test-result-box');
    box.style.display = 'block';
    box.style.background = 'rgba(15, 23, 42, 0.8)';
    box.style.border = '1px solid rgba(255, 255, 255, 0.1)';
    box.style.color = '#38bdf8';
    box.innerText = 'Đang gửi tín hiệu kiểm tra kết nối tới https://thueapi.pro/...';

    try {
      const res = await adminFetch(`${API_BASE}/admin/thueapi/test`, { method: 'POST' });
      const data = await res.json();
      if (data.success) {
        box.style.border = '1px solid rgba(16, 185, 129, 0.4)';
        box.style.color = '#86efac';
        box.innerHTML = `<strong>KẾT NỐI THÀNH CÔNG!</strong><br>${data.message}`;
        showToast('Kết nối ThueApi.Pro thành công!', 'success');
      } else {
        box.style.border = '1px solid rgba(239, 68, 68, 0.4)';
        box.style.color = '#fca5a5';
        box.innerHTML = `<strong>TRẠNG THÁI: ${data.status}</strong><br>${data.message}`;
        showToast(data.message, 'error');
      }
    } catch (err) {
      box.style.border = '1px solid rgba(239, 68, 68, 0.4)';
      box.style.color = '#fca5a5';
      box.innerText = 'Lỗi gửi yêu cầu kiểm tra: ' + err.message;
    }
  });

  // Copy Webhook
  document.getElementById('btn-copy-webhook')?.addEventListener('click', () => {
    const input = document.getElementById('thueapi-webhook-url');
    input.select();
    navigator.clipboard.writeText(input.value);
    showToast('Đã sao chép Webhook URL vào clipboard!', 'success');
  });

  // Toggle Password
  document.getElementById('btn-toggle-key')?.addEventListener('click', () => {
    const input = document.getElementById('thueapi-key');
    const btn = document.getElementById('btn-toggle-key');
    if (input.type === 'password') {
      input.type = 'text';
      btn.innerText = 'Ẩn Key';
    } else {
      input.type = 'password';
      btn.innerText = 'Hiện Key';
    }
  });

  // Refresh Webhook logs
  document.getElementById('btn-refresh-webhooks')?.addEventListener('click', () => {
    loadLogs();
    showToast('Đã làm mới danh sách Webhook!', 'info');
  });
});

async function loadConfig() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/thueapi/config`);
    if (!res.ok) return;
    const data = await res.json();

    document.getElementById('thueapi-enabled').checked = !!data.enabled;
    document.getElementById('thueapi-bankcode').value = data.bankCode || 'MB';
    document.getElementById('thueapi-bankacc').value = data.bankAcc || '3011200588888';
    document.getElementById('thueapi-bankname').value = data.bankName || 'TRẦN QUỐC VŨ';
    document.getElementById('thueapi-webhook-url').value = data.webhookUrl;

    if (data.apiKey) {
      document.getElementById('thueapi-key').value = data.apiKey;
      document.getElementById('thueapi-key').placeholder = `Đã cấu hình (${data.apiKeyMasked})`;
    } else if (data.hasKey) {
      document.getElementById('thueapi-key').placeholder = `Đã cấu hình (${data.apiKeyMasked})`;
    } else {
      document.getElementById('thueapi-key').value = '';
      document.getElementById('thueapi-key').placeholder = 'Chưa cấu hình API Key';
    }

    const sqlDbText = document.getElementById('sql-db-text');
    const sqlDbTime = document.getElementById('sql-db-time');
    if (sqlDbText) {
      sqlDbText.innerHTML = `Cơ sở dữ liệu MySQL: Đã đồng bộ an toàn — <strong>${data.bankCode}</strong> | STK: <strong>${data.bankAcc}</strong> | Chủ TK: <strong>${data.bankName}</strong>`;
    }
    if (sqlDbTime) {
      sqlDbTime.innerText = data.updatedAt
        ? `Lưu lần cuối: ${new Date(data.updatedAt).toLocaleTimeString('vi-VN')} ${new Date(data.updatedAt).toLocaleDateString('vi-VN')}`
        : 'Đã kết nối MySQL';
    }

    const badge = document.getElementById('thueapi-status-badge');
    const banner = document.getElementById('thueapi-alert-banner');

    if (!data.hasKey) {
      badge.innerHTML = '<span class="admin-live-dot" style="background: #ef4444;"></span> BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP';
      banner.style.display = 'block';
      banner.style.background = 'rgba(239, 68, 68, 0.15)';
      banner.style.border = '1px solid rgba(239, 68, 68, 0.4)';
      banner.style.color = '#fca5a5';
      banner.innerHTML = '<strong>BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP</strong><br>Hệ thống tự động kích hoạt gói bản quyền đang tạm dừng vì chưa có API Key từ <strong>https://thueapi.pro/</strong>. Vui lòng đăng ký tài khoản, nhập API Key bên dưới để bắt đầu kích hoạt tự động!';
    } else if (data.enabled) {
      badge.innerHTML = '<span class="admin-live-dot" style="background: #10b981;"></span> ACTIVE: ĐANG HOẠT ĐỘNG';
      banner.style.display = 'block';
      banner.style.background = 'rgba(16, 185, 129, 0.15)';
      banner.style.border = '1px solid rgba(16, 185, 129, 0.4)';
      banner.style.color = '#86efac';
      banner.innerHTML = '<strong>CỔNG TỰ ĐỘNG AUTOBANK ĐANG HOẠT ĐỘNG</strong><br>Hệ thống đang sẵn sàng tiếp nhận biến động số dư VietQR và tự động kích hoạt gói bản quyền cho khách hàng.';
    } else {
      badge.innerHTML = '<span class="admin-live-dot" style="background: #f59e0b;"></span> DISABLED: ĐÃ TẮT';
      banner.style.display = 'none';
    }
  } catch (err) {
    showToast('Lỗi tải cấu hình ThueApi: ' + err.message, 'error');
  }
}

async function loadLogs() {
  try {
    const res = await adminFetch(`${API_BASE}/admin/thueapi/webhooks`);
    if (!res.ok) return;
    const logs = await res.json();
    const tbody = document.getElementById('thueapi-logs-body');
    if (!tbody) return;

    if (!logs || logs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #64748b; padding: 25px;">Chưa ghi nhận sự kiện webhook nào từ ThueApi.Pro.</td></tr>';
      return;
    }

    tbody.innerHTML = logs.map(l => {
      const time = new Date(l.createdAt).toLocaleString('vi-VN');
      const isSuccess = l.status === 'SUCCESS';
      const badgeColor = isSuccess ? '#10b981' : '#ef4444';
      return `
        <tr>
          <td>${time}</td>
          <td><span style="font-family: monospace; color: #38bdf8;">${l.event}</span></td>
          <td><strong>${l.orderCode || 'Không có'}</strong></td>
          <td>${l.responseCode || 200}</td>
          <td><span style="color: ${badgeColor}; font-weight: 600;">● ${l.status}</span></td>
          <td><small style="font-family: monospace; color: #94a3b8; max-width: 250px; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${l.payload}</small></td>
        </tr>
      `;
    }).join('');
  } catch (_) {}
}
