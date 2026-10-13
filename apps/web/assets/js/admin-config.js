import { checkAuth, initSidebar, showToast, loadConfig, saveConfig, defaultConfig } from './admin-core.js';

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('config');

  const form = document.getElementById('config-form');
  if (!form) return;

  function populateForm(cfg) {
    document.getElementById('cfg-brand-name').value = cfg.brandName || '';
    document.getElementById('cfg-brand-slogan').value = cfg.brandSlogan || '';
    document.getElementById('cfg-chplay-link').value = cfg.chplayLink || '';
    document.getElementById('cfg-youtube-link').value = cfg.youtubeLink || '';
    document.getElementById('cfg-hotline').value = cfg.hotline || '';
    document.getElementById('cfg-email').value = cfg.email || '';
    document.getElementById('cfg-facebook').value = cfg.facebook || '';
    document.getElementById('cfg-tiktok').value = cfg.tiktok || '';

    const elBankCode = document.getElementById('cfg-bank-code');
    if (elBankCode) elBankCode.value = cfg.bankCode || 'MB';
    const elBankAcc = document.getElementById('cfg-bank-acc');
    if (elBankAcc) elBankAcc.value = cfg.bankAcc || '';
    const elBankName = document.getElementById('cfg-bank-name');
    if (elBankName) elBankName.value = cfg.bankName || '';

    document.getElementById('cfg-price-trial').value = cfg.priceTrial || '3 ngày miễn phí';
    document.getElementById('cfg-price-1m').value = cfg.price1m ?? 39000;
    document.getElementById('cfg-price-3m').value = cfg.price3m ?? 99000;
    document.getElementById('cfg-price-6m').value = cfg.price6m ?? 179000;
    document.getElementById('cfg-price-9m').value = cfg.price9m ?? 249000;
    document.getElementById('cfg-price-1y').value = cfg.price1y ?? 299000;

    const maintToggle = document.getElementById('cfg-maintenance-toggle');
    if (maintToggle) maintToggle.checked = Boolean(cfg.maintenance);

    const maintMsg = document.getElementById('cfg-maintenance-msg');
    if (maintMsg) maintMsg.value = cfg.maintenanceMsg || '';
  }

  // Load current config
  const appConfig = loadConfig();
  populateForm(appConfig);

  // Form submit
  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const parseNum = (id, fallback) => {
      const val = document.getElementById(id).value;
      const clean = String(val).replace(/\D/g, '');
      const parsed = parseInt(clean, 10);
      return isNaN(parsed) ? fallback : parsed;
    };

    const current = loadConfig();
    const updated = {
      ...current,
      brandName: document.getElementById('cfg-brand-name').value.trim(),
      brandSlogan: document.getElementById('cfg-brand-slogan').value.trim(),
      chplayLink: document.getElementById('cfg-chplay-link').value.trim(),
      youtubeLink: document.getElementById('cfg-youtube-link').value.trim(),
      hotline: document.getElementById('cfg-hotline').value.trim(),
      email: document.getElementById('cfg-email').value.trim(),
      facebook: document.getElementById('cfg-facebook').value.trim(),
      tiktok: document.getElementById('cfg-tiktok').value.trim(),
      priceTrial: document.getElementById('cfg-price-trial').value.trim(),
      price1m: parseNum('cfg-price-1m', 39000),
      price3m: parseNum('cfg-price-3m', 99000),
      price6m: parseNum('cfg-price-6m', 179000),
      price9m: parseNum('cfg-price-9m', 249000),
      price1y: parseNum('cfg-price-1y', 299000),
      maintenance: document.getElementById('cfg-maintenance-toggle')?.checked || false,
      maintenanceMsg: document.getElementById('cfg-maintenance-msg')?.value.trim() || '',
    };

    saveConfig(updated);
    showToast('Đã lưu & đồng bộ cấu hình tức thì đến toàn bộ Trang Web & App!', 'success');
  });

  // Test YouTube button
  const ytTestBtn = document.getElementById('btn-test-yt');
  if (ytTestBtn) {
    ytTestBtn.addEventListener('click', () => {
      const val = document.getElementById('cfg-youtube-link')?.value.trim();
      if (!val) {
        showToast('Vui lòng nhập đường dẫn YouTube trước khi kiểm tra!', 'warning');
        return;
      }
      window.open(val.startsWith('http') ? val : `https://${val}`, '_blank');
      showToast('Đang mở kiểm tra video YouTube trên tab mới...', 'info');
    });
  }

  // Reset to default button
  const resetBtn = document.getElementById('btn-reset-default');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      if (confirm('Bạn có chắc muốn khôi phục toàn bộ cấu hình về giá trị mặc định ban đầu?')) {
        populateForm(defaultConfig);
        saveConfig(defaultConfig);
        showToast('Đã khôi phục toàn bộ cấu hình mặc định ban đầu thành công!', 'info');
      }
    });
  }
});
