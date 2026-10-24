import { checkAuth, initSidebar, showToast, loadConfig, saveConfig, defaultConfig, API_BASE } from './admin-core.js';

let currentPackages = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!checkAuth()) return;
  initSidebar('config');

  const form = document.getElementById('config-form');
  if (!form) return;

  function populateForm(cfg) {
    const elServerDomain = document.getElementById('cfg-server-domain');
    if (elServerDomain) elServerDomain.value = cfg.serverDomain || 'https://api.docthongbaobank.com';
    const elWebDomain = document.getElementById('cfg-web-domain');
    if (elWebDomain) elWebDomain.value = cfg.webDomain || 'https://docthongbaobank.com';
    const elApiPort = document.getElementById('cfg-api-port');
    if (elApiPort) elApiPort.value = cfg.apiPort || 3000;

    document.getElementById('cfg-brand-name').value = cfg.brandName || '';
    document.getElementById('cfg-brand-slogan').value = cfg.brandSlogan || '';
    document.getElementById('cfg-chplay-link').value = cfg.chplayLink || '';

    const elRatingLink = document.getElementById('cfg-rating-link');
    if (elRatingLink) elRatingLink.value = cfg.ratingUrl || cfg.chplayLink || '';

    const elLivePin = document.getElementById('cfg-live-pin');
    if (elLivePin) elLivePin.value = cfg.liveWebPin || '889922';

    // Populate Affiliate Min Withdraw
    const setVal = (id, v) => { const el = document.getElementById(id); if (el) el.value = v; };
    setVal('cfg-aff-min-withdraw', cfg.affiliateMinWithdraw || 100000);

    document.getElementById('cfg-youtube-link').value = cfg.youtubeLink || '';
    setVal('cfg-video-newbie', cfg.videoGuideNewbie || '');
    setVal('cfg-video-smooth', cfg.videoGuideSmooth || '');
    setVal('cfg-video-affiliate', cfg.videoGuideAffiliate || '');
    setVal('cfg-video-history', cfg.videoGuideHistory || '');
    setVal('cfg-video-voice', cfg.videoGuideVoice || '');

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

    // Load dynamic packages
    currentPackages = Array.isArray(cfg.packages) && cfg.packages.length > 0 
      ? JSON.parse(JSON.stringify(cfg.packages))
      : JSON.parse(JSON.stringify(defaultConfig.packages || []));

    // Đồng bộ hoa hồng tiếp thị theo từng gói cước
    const affList = Array.isArray(cfg.affiliateRewards) ? cfg.affiliateRewards : [];
    currentPackages.forEach(p => {
      if (p.affiliateReward === undefined && p.commission === undefined) {
        const match = affList.find(a => 
          (a.key && a.key === p.key) || 
          (a.name && p.name && (a.name.toLowerCase().includes(p.name.toLowerCase()) || p.name.toLowerCase().includes(a.name.toLowerCase())))
        );
        p.affiliateReward = match ? match.reward : getDefaultAffiliateReward(p.durationDays, p.price);
        p.commission = p.affiliateReward;
      } else {
        p.affiliateReward = p.affiliateReward ?? p.commission ?? 0;
        p.commission = p.affiliateReward;
      }
    });

    renderPackagesTable();
    renderAffiliateCommissionInputs();

    const maintToggle = document.getElementById('cfg-maintenance-toggle');
    if (maintToggle) maintToggle.checked = Boolean(cfg.maintenance);

    const maintMsg = document.getElementById('cfg-maintenance-msg');
    if (maintMsg) maintMsg.value = cfg.maintenanceMsg || '';

    const gpayToggle = document.getElementById('cfg-gpay-maintenance-toggle');
    if (gpayToggle) gpayToggle.checked = Boolean(cfg.googlePayMaintenance);

    const gpayMsg = document.getElementById('cfg-gpay-maintenance-msg');
    if (gpayMsg) gpayMsg.value = cfg.googlePayMaintenanceMsg || 'Cổng thanh toán Google Pay đang tạm bảo trì nâng cấp. Quý khách vui lòng chuyển khoản qua VietQR để kích hoạt ngay!';
  }

  function renderPackagesTable() {
    const tbody = document.getElementById('admin-packages-table-body');
    if (!tbody) return;

    if (currentPackages.length === 0) {
      tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8; padding: 24px;">Chưa có gói cước nào. Bấm "+ Thêm Gói Cước Mới" để tạo gói đầu tiên!</td></tr>`;
      return;
    }

    tbody.innerHTML = currentPackages.map((p, index) => `
      <tr data-pkg-key="${p.key}" data-index="${index}" draggable="true" style="cursor: grab;">
        <td style="text-align: center; vertical-align: middle;">
          <div style="display: inline-flex; align-items: center; justify-content: center; gap: 4px;">
            <button type="button" class="admin-btn admin-btn-outline admin-btn-sm btn-reorder" data-action="move-up" data-index="${index}" title="Chuyển lên trên" ${index === 0 ? 'disabled style="opacity: 0.25; cursor: not-allowed; padding: 2px 7px;"' : 'style="padding: 2px 7px;"'}>
              ▲
            </button>
            <span style="font-weight: 700; color: #38bdf8; min-width: 24px; font-size: 0.88rem;">#${index + 1}</span>
            <button type="button" class="admin-btn admin-btn-outline admin-btn-sm btn-reorder" data-action="move-down" data-index="${index}" title="Chuyển xuống dưới" ${index === currentPackages.length - 1 ? 'disabled style="opacity: 0.25; cursor: not-allowed; padding: 2px 7px;"' : 'style="padding: 2px 7px;"'}>
              ▼
            </button>
          </div>
        </td>
        <td>
          <div style="font-weight: 700; color: #f8fafc;">${p.name}</div>
          <small style="color: #64748b; font-family: monospace;">Key: ${p.key}</small>
        </td>
        <td style="color: #94a3b8;">
          ${p.durationDays >= 9999 ? 'Vĩnh viễn' : `${p.durationDays} ngày`}
        </td>
        <td>
          <strong style="color: ${p.price === 0 ? '#38bdf8' : '#22c55e'}; font-size: 1.05rem;">
            ${p.price === 0 ? '0đ (Miễn phí)' : `${Number(p.price).toLocaleString('vi-VN')}đ`}
          </strong>
        </td>
        <td>
          ${p.badge ? `<span class="admin-badge" style="background: rgba(245, 158, 11, 0.2); color: #fbbf24; font-weight: 600;">${p.badge}</span>` : '<span style="color: #475569;">—</span>'}
        </td>
        <td>
          <span class="admin-badge admin-badge-${p.isActive !== false ? 'success' : 'danger'}">
            ${p.isActive !== false ? 'Đang bán' : 'Tạm ẩn'}
          </span>
        </td>
        <td>
          <div style="display: flex; gap: 6px; flex-wrap: wrap;">
            <button type="button" class="admin-btn admin-btn-outline admin-btn-sm" data-action="edit" data-key="${p.key}">Sửa</button>
            <button type="button" class="admin-btn ${p.isActive !== false ? 'admin-btn-outline' : 'admin-btn-success'} admin-btn-sm" data-action="toggle" data-key="${p.key}">
              ${p.isActive !== false ? 'Ẩn' : 'Hiện'}
            </button>
            <button type="button" class="admin-btn admin-btn-danger admin-btn-sm" data-action="delete" data-key="${p.key}">Xóa</button>
          </div>
        </td>
      </tr>
    `).join('');

    syncLegacyPriceInputs();
    initDragAndDrop();
  }

  function getDefaultAffiliateReward(days, price) {
    if (!days || days <= 3 || !price) return 0;
    if (days <= 30) return 10000;
    if (days <= 90) return 20000;
    if (days <= 180) return 35000;
    if (days <= 450) return 50000;
    return 65000;
  }

  function renderAffiliateCommissionInputs() {
    const container = document.getElementById('admin-affiliate-dynamic-container');
    if (!container) return;

    const paidPackages = currentPackages.filter(p => p.price > 0);
    if (paidPackages.length === 0) {
      container.innerHTML = `<div style="color: #94a3b8; font-size: 0.88rem; padding: 12px; grid-column: 1 / -1;">Chưa có gói cước tính phí nào để cấu hình hoa hồng. Hãy thêm gói cước ở bảng bên dưới.</div>`;
      return;
    }

    container.innerHTML = paidPackages.map((p) => {
      const reward = parseInt(p.affiliateReward ?? p.commission ?? getDefaultAffiliateReward(p.durationDays, p.price), 10) || 0;
      p.affiliateReward = reward;
      p.commission = reward;

      return `
        <div class="admin-form-group" style="background: rgba(15, 23, 42, 0.4); padding: 12px 14px; border-radius: 10px; border: 1px solid rgba(255,255,255,0.06); margin-bottom: 0;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
            <label style="font-weight: 700; color: #f8fafc; font-size: 0.88rem; margin-bottom: 0;">
              ${p.name}
            </label>
            <span style="font-size: 0.76rem; color: #38bdf8; font-family: monospace;">${p.durationDays ? p.durationDays + ' ngày' : ''} · ${Number(p.price).toLocaleString('vi-VN')}đ</span>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <input type="number" 
                   class="admin-input aff-dynamic-input" 
                   id="cfg-aff-pkg-${p.key}" 
                   data-key="${p.key}" 
                   min="0" 
                   step="1000" 
                   value="${reward}" 
                   placeholder="Nhập số tiền VNĐ..." />
            <span style="color: #94a3b8; font-size: 0.85rem; font-weight: 600;">VNĐ</span>
          </div>
        </div>
      `;
    }).join('');

    // Bắt sự kiện người dùng thay đổi giá trị hoa hồng
    container.querySelectorAll('.aff-dynamic-input').forEach(input => {
      input.addEventListener('input', (e) => {
        const key = e.target.getAttribute('data-key');
        const val = parseInt(e.target.value, 10) || 0;
        const targetPkg = currentPackages.find(p => p.key === key);
        if (targetPkg) {
          targetPkg.affiliateReward = val;
          targetPkg.commission = val;
        }
      });
    });
  }

  function movePackage(fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= currentPackages.length || toIndex < 0 || toIndex >= currentPackages.length) return;
    const item = currentPackages.splice(fromIndex, 1)[0];
    currentPackages.splice(toIndex, 0, item);
    renderPackagesTable();
    renderAffiliateCommissionInputs();
    autoSavePackages(`Đã chuyển gói "${item.name}" sang thứ tự #${toIndex + 1} và đồng bộ đến Web & App!`);
  }

  function initDragAndDrop() {
    const tbody = document.getElementById('admin-packages-table-body');
    if (!tbody || tbody.dataset.dragInited) return;
    tbody.dataset.dragInited = 'true';

    let draggedIdx = null;

    tbody.addEventListener('dragstart', (e) => {
      const tr = e.target.closest('tr[data-index]');
      if (!tr) return;
      draggedIdx = parseInt(tr.getAttribute('data-index'), 10);
      tr.style.opacity = '0.35';
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', draggedIdx);
    });

    tbody.addEventListener('dragend', (e) => {
      const tr = e.target.closest('tr[data-index]');
      if (tr) tr.style.opacity = '1';
      document.querySelectorAll('#admin-packages-table-body tr').forEach(r => {
        r.style.opacity = '1';
        r.style.borderTop = '';
      });
    });

    tbody.addEventListener('dragover', (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      const tr = e.target.closest('tr[data-index]');
      if (!tr) return;
      document.querySelectorAll('#admin-packages-table-body tr').forEach(r => {
        r.style.borderTop = '';
      });
      tr.style.borderTop = '2px solid #38bdf8';
    });

    tbody.addEventListener('dragleave', (e) => {
      const tr = e.target.closest('tr[data-index]');
      if (tr) tr.style.borderTop = '';
    });

    tbody.addEventListener('drop', (e) => {
      e.preventDefault();
      const tr = e.target.closest('tr[data-index]');
      if (!tr || draggedIdx === null) return;
      tr.style.borderTop = '';
      const targetIdx = parseInt(tr.getAttribute('data-index'), 10);
      if (draggedIdx !== targetIdx) {
        movePackage(draggedIdx, targetIdx);
      }
    });
  }

  function initPackageEventDelegation() {
    const tbody = document.getElementById('admin-packages-table-body');
    if (!tbody || tbody.dataset.delegated) return;
    tbody.dataset.delegated = 'true';

    tbody.addEventListener('click', (e) => {
      const moveUpBtn = e.target.closest('[data-action="move-up"]');
      if (moveUpBtn && !moveUpBtn.disabled) {
        const idx = parseInt(moveUpBtn.getAttribute('data-index'), 10);
        if (idx > 0) {
          movePackage(idx, idx - 1);
        }
        return;
      }

      const moveDownBtn = e.target.closest('[data-action="move-down"]');
      if (moveDownBtn && !moveDownBtn.disabled) {
        const idx = parseInt(moveDownBtn.getAttribute('data-index'), 10);
        if (idx < currentPackages.length - 1) {
          movePackage(idx, idx + 1);
        }
        return;
      }

      const editBtn = e.target.closest('[data-action="edit"]');
      if (editBtn) {
        const key = editBtn.getAttribute('data-key');
        openPackageModal(key);
        return;
      }

      const toggleBtn = e.target.closest('[data-action="toggle"]');
      if (toggleBtn) {
        const key = toggleBtn.getAttribute('data-key');
        togglePackage(key);
        return;
      }

      const delBtn = e.target.closest('[data-action="delete"]');
      if (delBtn) {
        const key = delBtn.getAttribute('data-key');
        deletePackage(key);
        return;
      }
    });
  }

  function syncLegacyPriceInputs() {
    const findPrice = (key, fallback) => {
      const match = currentPackages.find(p => p.key === key);
      return match ? match.price : fallback;
    };
    const setHidden = (id, val) => {
      const el = document.getElementById(id);
      if (el) el.value = val;
    };
    setHidden('cfg-price-1m', findPrice('1m', 39000));
    setHidden('cfg-price-3m', findPrice('3m', 99000));
    setHidden('cfg-price-6m', findPrice('6m', 179000));
    setHidden('cfg-price-9m', findPrice('9m', 249000));
    setHidden('cfg-price-1y', findPrice('1y', 299000));
    setHidden('cfg-price-lifetime', findPrice('lifetime', 499000));
  }

  function autoSavePackages(msg) {
    const current = loadConfig();
    const affRewards = currentPackages
      .filter(p => p.isActive !== false && p.price > 0)
      .map(p => ({
        name: p.name,
        key: p.key,
        duration: p.durationDays ? `${p.durationDays} ngày` : 'Theo gói',
        reward: parseInt(p.affiliateReward || p.commission || 0, 10),
        desc: `Nhận ${parseInt(p.affiliateReward || p.commission || 0, 10).toLocaleString('vi-VN')}₫/lượt khi khách mua ${p.name}`
      }));

    const updated = {
      ...current,
      packages: currentPackages,
      affiliateRewards: affRewards,
    };
    saveConfig(updated);
    if (msg) showToast(msg, 'success');
  }

  function togglePackage(key) {
    const pkg = currentPackages.find(p => p.key === key);
    if (pkg) {
      pkg.isActive = pkg.isActive === false ? true : false;
      renderPackagesTable();
      renderAffiliateCommissionInputs();
      autoSavePackages(`Đã ${pkg.isActive ? 'bật hiển thị' : 'ẩn'} gói "${pkg.name}" và đồng bộ tức thì đến Web & App!`);
    }
  }

  function deletePackage(key) {
    const idx = currentPackages.findIndex(p => p.key === key);
    if (idx >= 0) {
      const pkg = currentPackages[idx];
      if (confirm(`Bạn có chắc muốn xóa gói "${pkg.name}" khỏi hệ thống?`)) {
        const deletedName = pkg.name;
        currentPackages.splice(idx, 1);
        renderPackagesTable();
        renderAffiliateCommissionInputs();
        autoSavePackages(`Đã xóa gói "${deletedName}" và đồng bộ tức thì đến Web & App!`);
      }
    }
  }

  function openPackageModal(pkgKey = null) {
    const modal = document.getElementById('admin-package-modal');
    const form = document.getElementById('form-save-package');
    const title = document.getElementById('modal-package-title');
    if (!modal || !form) return;

    if (pkgKey) {
      const p = currentPackages.find(x => x.key === pkgKey);
      if (!p) return;
      title.textContent = `Chỉnh Sửa Gói: ${p.name}`;
      document.getElementById('m-pkg-index').value = p.key;
      document.getElementById('m-pkg-key').value = p.key;
      document.getElementById('m-pkg-key').readOnly = true;
      document.getElementById('m-pkg-days').value = p.durationDays;
      document.getElementById('m-pkg-name').value = p.name;
      document.getElementById('m-pkg-price').value = p.price;
      const affInp = document.getElementById('m-pkg-affiliate');
      if (affInp) affInp.value = p.affiliateReward ?? p.commission ?? getDefaultAffiliateReward(p.durationDays, p.price);
      document.getElementById('m-pkg-badge').value = p.badge || '';
      document.getElementById('m-pkg-desc').value = p.description || '';
      document.getElementById('m-pkg-active').checked = p.isActive !== false;
    } else {
      title.textContent = 'Thêm Gói Cước Mới';
      form.reset();
      document.getElementById('m-pkg-index').value = '';
      document.getElementById('m-pkg-key').readOnly = false;
      const affInp = document.getElementById('m-pkg-affiliate');
      if (affInp) affInp.value = '20000';
      document.getElementById('m-pkg-active').checked = true;
    }
    modal.classList.add('is-open');
  }

  function closePackageModal() {
    const modal = document.getElementById('admin-package-modal');
    if (modal) modal.classList.remove('is-open');
  }

  window.adminOpenPackageModal = openPackageModal;
  window.adminClosePackageModal = closePackageModal;

  function initPackageModal() {
    const modal = document.getElementById('admin-package-modal');
    const btnAdd = document.getElementById('btn-add-package');
    const btnClose = document.getElementById('modal-package-close');
    const btnCancel = document.getElementById('modal-package-cancel');
    const form = document.getElementById('form-save-package');

    if (!modal || !form) return;

    if (btnAdd) btnAdd.onclick = () => openPackageModal(null);
    if (btnClose) btnClose.onclick = () => closePackageModal();
    if (btnCancel) btnCancel.onclick = () => closePackageModal();

    modal.addEventListener('click', (e) => {
      if (e.target === modal) closePackageModal();
    });

    form.onsubmit = (e) => {
      e.preventDefault();
      const existingKey = document.getElementById('m-pkg-index').value.trim();
      const key = document.getElementById('m-pkg-key').value.trim();
      const days = parseInt(document.getElementById('m-pkg-days').value, 10) || 30;
      const name = document.getElementById('m-pkg-name').value.trim();
      const price = parseInt(document.getElementById('m-pkg-price').value, 10) || 0;
      const affVal = parseInt(document.getElementById('m-pkg-affiliate')?.value, 10) || 0;
      const badge = document.getElementById('m-pkg-badge').value.trim();
      const desc = document.getElementById('m-pkg-desc').value.trim();
      const isActive = document.getElementById('m-pkg-active').checked;

      if (!key || !name) {
        showToast('Vui lòng điền đầy đủ mã gói và tên gói!', 'warning');
        return;
      }

      const pkgData = {
        key,
        name,
        durationDays: days,
        price,
        affiliateReward: affVal,
        commission: affVal,
        badge,
        description: desc,
        isActive,
      };

      const existingIdx = currentPackages.findIndex(p => p.key === (existingKey || key));
      if (existingIdx >= 0) {
        currentPackages[existingIdx] = pkgData;
      } else {
        if (currentPackages.some(p => p.key === key)) {
          showToast(`Mã gói "${key}" đã tồn tại. Vui lòng chọn mã khác!`, 'error');
          return;
        }
        currentPackages.push(pkgData);
      }

      closePackageModal();
      renderPackagesTable();
      renderAffiliateCommissionInputs();
      autoSavePackages(`Đã ${existingIdx >= 0 ? 'cập nhật' : 'thêm'} gói "${name}" và đồng bộ tức thì đến Web & App!`);
    };
  }

  initPackageEventDelegation();

  // Load current config from localStorage & MySQL API immediately
  const appConfig = loadConfig();
  populateForm(appConfig);
  initPackageModal();

  fetch(`${API_BASE}/admin/configs`)
    .then(res => res.json())
    .then(fresh => {
      if (fresh && (fresh.brandName || fresh.packages)) {
        populateForm(fresh);
      }
    })
    .catch(() => {});

  // Ping domain test button
  const pingBtn = document.getElementById('btn-ping-domain');
  if (pingBtn) {
    pingBtn.addEventListener('click', async () => {
      const domainVal = document.getElementById('cfg-server-domain')?.value.trim();
      if (!domainVal) {
        showToast('Vui lòng nhập tên miền máy chủ API trước khi kiểm tra!', 'warning');
        return;
      }
      showToast(`Đang kiểm tra kết nối tới ${domainVal}...`, 'info');
      try {
        const pingUrl = domainVal.replace(/\/+$/, '') + '/admin/configs';
        const res = await fetch(pingUrl, { method: 'GET' });
        if (res.ok) {
          showToast(`✓ Tên miền ${domainVal} phản hồi tốt (200 OK)! Hệ thống sẵn sàng trỏ toàn bộ.`, 'success');
        } else {
          showToast(`Cảnh báo: Tên miền phản hồi mã lỗi HTTP ${res.status}. Vui lòng kiểm tra lại DNS.`, 'warning');
        }
      } catch (err) {
        showToast(`Không thể kết nối đến ${domainVal}: ${err.message}`, 'error');
      }
    });
  }

  // Form submit
  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const parseNum = (id, fallback) => {
      const el = document.getElementById(id);
      if (!el) return fallback;
      const clean = String(el.value).replace(/\D/g, '');
      const parsed = parseInt(clean, 10);
      return isNaN(parsed) ? fallback : parsed;
    };

    // Xây dựng bảng hoa hồng liên kết chuẩn xác 100% theo các gói cước đang có của Admin
    const affiliateRewards = currentPackages
      .filter(p => p.isActive !== false && p.price > 0)
      .map(p => {
        const inp = document.getElementById(`cfg-aff-pkg-${p.key}`);
        const r = inp ? (parseInt(inp.value, 10) || 0) : (p.affiliateReward || p.commission || 0);
        p.affiliateReward = r;
        p.commission = r;
        return {
          name: p.name,
          key: p.key,
          duration: p.durationDays ? `${p.durationDays} ngày` : 'Theo gói',
          reward: r,
          desc: `Nhận ${r.toLocaleString('vi-VN')}₫/lượt khi khách mua ${p.name}`
        };
      });

    const current = loadConfig();
    const updated = {
      ...current,
      serverDomain: document.getElementById('cfg-server-domain')?.value.trim() || 'https://api.docthongbaobank.com',
      webDomain: document.getElementById('cfg-web-domain')?.value.trim() || 'https://docthongbaobank.com',
      apiPort: parseNum('cfg-api-port', 3000),
      brandName: document.getElementById('cfg-brand-name').value.trim(),
      brandSlogan: document.getElementById('cfg-brand-slogan').value.trim(),
      chplayLink: document.getElementById('cfg-chplay-link').value.trim(),
      ratingUrl: document.getElementById('cfg-rating-link')?.value.trim() || document.getElementById('cfg-chplay-link').value.trim(),
      liveWebPin: document.getElementById('cfg-live-pin')?.value.trim() || '889922',
      affiliateRewards,
      youtubeLink: document.getElementById('cfg-youtube-link').value.trim(),
      videoGuideNewbie: document.getElementById('cfg-video-newbie')?.value.trim() || '',
      videoGuideSmooth: document.getElementById('cfg-video-smooth')?.value.trim() || '',
      videoGuideAffiliate: document.getElementById('cfg-video-affiliate')?.value.trim() || '',
      videoGuideHistory: document.getElementById('cfg-video-history')?.value.trim() || '',
      videoGuideVoice: document.getElementById('cfg-video-voice')?.value.trim() || '',
      hotline: document.getElementById('cfg-hotline').value.trim(),
      email: document.getElementById('cfg-email').value.trim(),
      facebook: document.getElementById('cfg-facebook').value.trim(),
      tiktok: document.getElementById('cfg-tiktok').value.trim(),
      bankCode: document.getElementById('cfg-bank-code')?.value.trim() || current.bankCode || 'MB',
      bankAcc: document.getElementById('cfg-bank-acc')?.value.trim() || current.bankAcc || '',
      bankName: document.getElementById('cfg-bank-name')?.value.trim() || current.bankName || '',
      priceTrial: document.getElementById('cfg-price-trial')?.value.trim() || '0đ (3 ngày)',
      price1m: parseNum('cfg-price-1m', 39000),
      price3m: parseNum('cfg-price-3m', 99000),
      price6m: parseNum('cfg-price-6m', 179000),
      price9m: parseNum('cfg-price-9m', 249000),
      price1y: parseNum('cfg-price-1y', 299000),
      priceLifetime: parseNum('cfg-price-lifetime', 499000),
      packages: currentPackages,
      maintenance: document.getElementById('cfg-maintenance-toggle')?.checked || false,
      maintenanceMsg: document.getElementById('cfg-maintenance-msg')?.value.trim() || '',
      googlePayMaintenance: document.getElementById('cfg-gpay-maintenance-toggle')?.checked || false,
      googlePayMaintenanceMsg: document.getElementById('cfg-gpay-maintenance-msg')?.value.trim() || 'Cổng thanh toán Google Pay đang tạm bảo trì nâng cấp. Quý khách vui lòng chuyển khoản qua VietQR để kích hoạt ngay!',
    };

    saveConfig(updated);
    showToast('Đã lưu & đồng bộ cấu hình tên miền + bảng giá tức thì đến toàn bộ Trang Web & App!', 'success');
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

  // Handle all test video buttons
  document.querySelectorAll('.btn-test-video').forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-target');
      const val = document.getElementById(targetId)?.value.trim();
      if (!val) {
        showToast('Vui lòng nhập link video YouTube trước khi bấm kiểm tra!', 'warning');
        return;
      }
      window.open(val.startsWith('http') ? val : `https://${val}`, '_blank');
      showToast('Đang mở video YouTube trên tab mới...', 'info');
    });
  });

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

  // BẬT / TẮT BẢO TRÌ GOOGLE PAY TỰ ĐỘNG LƯU & ĐỒNG BỘ TỨC THÌ ĐẾN APP (KHÔNG CẦN BẤM LƯU)
  const gpayToggle = document.getElementById('cfg-gpay-maintenance-toggle');
  const gpayMsg = document.getElementById('cfg-gpay-maintenance-msg');
  if (gpayToggle) {
    gpayToggle.addEventListener('change', () => {
      const isMaint = gpayToggle.checked;
      const msg = gpayMsg?.value.trim() || 'Cổng thanh toán Google Pay đang tạm bảo trì nâng cấp. Quý khách vui lòng chuyển khoản qua VietQR để kích hoạt ngay!';
      saveConfig({
        googlePayMaintenance: isMaint,
        googlePayMaintenanceMsg: msg,
      });
      showToast(
        isMaint
          ? '⚠️ ĐÃ BẬT BẢO TRÌ GOOGLE PAY: App lập tức khóa thanh toán GG và hướng dẫn khách dùng VietQR!'
          : '✓ ĐÃ TẮT BẢO TRÌ GOOGLE PAY: Cổng thanh toán GG trên App đã hoạt động bình thường!',
        isMaint ? 'warning' : 'success'
      );
    });
  }

  // BẬT / TẮT BẢO TRÌ TOÀN HỆ THỐNG TỰ ĐỘNG LƯU TỨC THÌ
  const sysMaintToggle = document.getElementById('cfg-maintenance-toggle');
  const sysMaintMsg = document.getElementById('cfg-maintenance-msg');
  if (sysMaintToggle) {
    sysMaintToggle.addEventListener('change', () => {
      const isMaint = sysMaintToggle.checked;
      const msg = sysMaintMsg?.value.trim() || 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ.';
      saveConfig({
        maintenance: isMaint,
        maintenanceMsg: msg,
      });
      showToast(
        isMaint
          ? '⚠️ ĐÃ BẬT BẢO TRÌ TOÀN HỆ THỐNG: Web & App đang hiển thị bảng bảo trì!'
          : '✓ ĐÃ TẮT BẢO TRÌ HỆ THỐNG: Web & App hoạt động lại bình thường!',
        isMaint ? 'warning' : 'success'
      );
    });
  }
});
