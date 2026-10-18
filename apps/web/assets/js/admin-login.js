import { API_BASE, STORAGE_AUTH_TOKEN, STORAGE_JWT_TOKEN, showToast } from './admin-core.js';

document.addEventListener('DOMContentLoaded', () => {
  // If already authenticated with valid JWT, redirect to /admin
  const existingToken = sessionStorage.getItem(STORAGE_JWT_TOKEN);
  if (existingToken && sessionStorage.getItem(STORAGE_AUTH_TOKEN) === 'autobank_admin_authenticated') {
    window.location.href = '/admin';
    return;
  }

  const form = document.getElementById('admin-login-form');
  const userInput = document.getElementById('admin-user-input');
  const passInput = document.getElementById('admin-pass-input');
  const errorMsg = document.getElementById('admin-login-error');
  const submitBtn = document.getElementById('admin-login-submit');

  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const u = userInput.value.trim();
      const p = passInput.value.trim();

      if (!u || !p) {
        showToast('Vui lòng nhập tài khoản và mật khẩu', 'warning');
        return;
      }

      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = 'Đang xác thực an toàn...';
      }

      try {
        const res = await fetch(`${API_BASE}/auth/admin/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ username: u, password: p }),
        });

        const data = await res.json().catch(() => ({}));

        if (res.ok && data.token) {
          sessionStorage.setItem(STORAGE_JWT_TOKEN, data.token);
          sessionStorage.setItem(STORAGE_AUTH_TOKEN, 'autobank_admin_authenticated');
          if (errorMsg) errorMsg.style.display = 'none';
          showToast('🎉 Đăng nhập thành công! Đang chuyển hướng...', 'success');
          setTimeout(() => {
            window.location.href = '/admin';
          }, 350);
        } else {
          const msg = data.message || 'Tài khoản hoặc mật khẩu không chính xác!';
          if (errorMsg) {
            errorMsg.textContent = msg;
            errorMsg.style.display = 'block';
          }
          passInput.value = '';
          passInput.focus();
          showToast(msg, 'error');
        }
      } catch (err) {
        const networkMsg = 'Không thể kết nối đến máy chủ xác thực: ' + (err.message || 'Lỗi mạng');
        if (errorMsg) {
          errorMsg.textContent = networkMsg;
          errorMsg.style.display = 'block';
        }
        showToast(networkMsg, 'error');
      } finally {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Đăng nhập hệ thống';
        }
      }
    });
  }
});
