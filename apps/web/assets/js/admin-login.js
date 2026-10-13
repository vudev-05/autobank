import { ENV_ADMIN_USER, ENV_ADMIN_PASS, STORAGE_AUTH_TOKEN, showToast } from './admin-core.js';

document.addEventListener('DOMContentLoaded', () => {
  // If already authenticated, redirect to index.html
  if (sessionStorage.getItem(STORAGE_AUTH_TOKEN) === 'autobank_admin_authenticated') {
    window.location.href = 'index.html';
    return;
  }

  const form = document.getElementById('admin-login-form');
  const userInput = document.getElementById('admin-user-input');
  const passInput = document.getElementById('admin-pass-input');
  const errorMsg = document.getElementById('admin-login-error');

  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const u = userInput.value.trim();
      const p = passInput.value.trim();

      if (u === ENV_ADMIN_USER && p === ENV_ADMIN_PASS) {
        sessionStorage.setItem(STORAGE_AUTH_TOKEN, 'autobank_admin_authenticated');
        if (errorMsg) errorMsg.style.display = 'none';
        showToast('Đăng nhập thành công! Đang chuyển hướng...', 'success');
        setTimeout(() => {
          window.location.href = 'index.html';
        }, 500);
      } else {
        if (errorMsg) errorMsg.style.display = 'block';
        passInput.value = '';
        passInput.focus();
        showToast('Tài khoản hoặc mật khẩu không chính xác!', 'error');
      }
    });
  }
});
