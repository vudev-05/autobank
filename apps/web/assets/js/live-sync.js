/**
 * Autobank Live Synchronization Engine
 * Connects Admin Portal, MySQL Database, and Landing Page in real-time.
 * Guarantees 100% immediate reflection of pricing, hotline, Zalo, YouTube, brand, and slogan.
 */

export function initLiveSync() {
  const API_BASE = (typeof window !== 'undefined' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1')
    ? 'https://api.docthongbaobank.com'
    : (import.meta.env.VITE_API_BASE || 'http://localhost:3000');

  function parsePrice(val, defaultVal) {
    if (typeof val === 'number' && !isNaN(val)) return val;
    if (!val) return defaultVal;
    const num = parseInt(String(val).replace(/\D/g, ''), 10);
    return isNaN(num) ? defaultVal : num;
  }

  function formatVND(val) {
    return Number(val).toLocaleString('vi-VN') + 'đ';
  }

  function renderDynamicPricingCards(packagesList) {
    const container = document.getElementById('pricing-packages-container') || document.querySelector('.pricing-grid-6');
    if (!container || !Array.isArray(packagesList) || packagesList.length === 0) return;

    // Filter only active packages
    const activePackages = packagesList.filter(p => p.isActive !== false);
    if (activePackages.length === 0) return;

    container.innerHTML = activePackages.map(pkg => {
      const isTrial = pkg.price === 0;
      const isFeatured = (pkg.badge && (pkg.badge.includes('Khuyên dùng') || pkg.badge.includes('Bán chạy'))) || pkg.key === '1y' || pkg.key === '1year';
      const formattedPrice = isTrial ? '0đ (3 ngày)' : `${Number(pkg.price).toLocaleString('vi-VN')}đ`;
      const durationText = pkg.durationDays >= 9999 ? 'Thời hạn vĩnh viễn (Trọn đời)' : `Thời hạn sử dụng ${pkg.durationDays} ngày`;
      const monthlyCalc = pkg.price > 0 && pkg.durationDays >= 30 
        ? `<li>Chỉ <strong>~${Math.round(pkg.price / (pkg.durationDays / 30)).toLocaleString('vi-VN')}đ/tháng</strong> ${pkg.badge ? `(${pkg.badge})` : ''}</li>` 
        : '';

      let iconSvg = '';
      if (isTrial) {
        iconSvg = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>`;
      } else if (pkg.durationDays <= 30) {
        iconSvg = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`;
      } else if (pkg.durationDays <= 90) {
        iconSvg = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><path d="M8 14h.01M12 14h.01M16 14h.01"/></svg>`;
      } else if (pkg.durationDays <= 180) {
        iconSvg = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>`;
      } else {
        iconSvg = `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 22 12 18.56 5.82 22 7 14.14l-5-4.87 6.91-1.01L12 2z"/></svg>`;
      }

      return `
        <div class="single-price text-center ${isFeatured ? 'featured active' : ''}" style="position: relative;">
          ${pkg.badge ? `<div style="position: absolute; top: -14px; left: 50%; transform: translateX(-50%); background: #0f172a; color: #fff; font-size: 0.72rem; font-weight: 800; padding: 4px 12px; border-radius: 999px; text-transform: uppercase; letter-spacing: 0.5px; white-space: nowrap; box-shadow: 0 4px 12px rgba(0,0,0,0.15); z-index: 2;">${pkg.badge}</div>` : ''}
          <div class="price-icon mx-auto" style="${isFeatured ? 'background: #0f172a !important; color: #fff !important;' : ''}">
            ${iconSvg}
          </div>
          <h3 class="package-name mb-15">${pkg.name}</h3>
          <p class="package-price mb-20" style="${isFeatured ? 'color: #0284c7;' : ''}">${formattedPrice}</p>
          <ul class="package-details">
            <li>${durationText}</li>
            ${monthlyCalc}
            ${pkg.description ? `<li>${pkg.description}</li>` : '<li>Hỗ trợ toàn bộ 65+ app ngân hàng & ví</li>'}
            <li>Đọc thông báo 24/7 ổn định cao</li>
          </ul>
          <a href="#${pkg.key}" class="btn-hover price-btn main-btn" data-package="${pkg.key}" style="${isFeatured ? 'background: linear-gradient(135deg, #0284c7, #0369a1);' : ''}">
            ${isTrial ? 'Dùng thử 3 ngày' : `Chọn ${pkg.name}`}
          </a>
        </div>
      `;
    }).join('');

    // Rebind payment modal trigger to newly rendered buttons
    if (window.autobankPaymentModal && window.autobankPaymentModal.attachPricingButtons) {
      window.autobankPaymentModal.attachPricingButtons();
    } else if (window.attachPricingButtons) {
      window.attachPricingButtons();
    }
  }

  function applyConfig(cfg) {
    if (!cfg || typeof cfg !== 'object') return;

    // 1. HOTLINE & ZALO SYNCHRONIZATION
    const rawHotline = cfg.hotline || '0869226687';
    const cleanDigits = rawHotline.replace(/\D/g, '');
    const intlPhone = cleanDigits.replace(/^0/, '+84');
    const zaloUrl = `https://zalo.me/${cleanDigits}`;

    // Update all tel links
    document.querySelectorAll('a[href^="tel:"]').forEach(a => {
      a.href = `tel:${intlPhone}`;
      const txt = a.textContent.trim();
      if (/^[0-9\+\.\s]{9,15}$/.test(txt)) {
        a.textContent = rawHotline;
      } else if (txt.toLowerCase().includes('hotline')) {
        a.textContent = `Hotline ${rawHotline}`;
      }
    });

    // Update all Zalo links
    document.querySelectorAll('a[href*="zalo.me"]').forEach(a => {
      a.href = zaloUrl;
      const txt = a.textContent.trim();
      if (txt.includes('zalo.me/')) {
        a.textContent = `zalo.me/${cleanDigits}`;
      } else if (txt.toLowerCase().includes('zalo') && /\d{9,12}/.test(txt)) {
        a.textContent = txt.replace(/\d{9,12}/, rawHotline);
      }
    });

    // Update contact cards in contact section
    document.querySelectorAll('.seo-contact-card').forEach(card => {
      const label = card.querySelector('.seo-contact-card__label')?.textContent?.trim().toLowerCase() || '';
      const val = card.querySelector('.seo-contact-card__value');
      if (val) {
        if (label.includes('hotline')) {
          card.href = `tel:${intlPhone}`;
          val.textContent = rawHotline;
        } else if (label.includes('zalo')) {
          card.href = zaloUrl;
          val.textContent = `zalo.me/${cleanDigits}`;
        }
      }
    });

    // Update FAQ text if phone mentioned
    document.querySelectorAll('#faq6 .seo-faq-item__a a, #contact a').forEach(a => {
      if (a.href && a.href.includes('zalo.me')) {
        a.href = zaloUrl;
        a.textContent = `Zalo ${rawHotline}`;
      }
    });

    // 2. PRICING PACKAGES SYNCHRONIZATION (Dynamic 24/24 from Admin)
    if (Array.isArray(cfg.packages) && cfg.packages.length > 0) {
      renderDynamicPricingCards(cfg.packages);
    } else {
      // Fallback legacy static cards
      const trialPrice = cfg.priceTrial || '3 ngày miễn phí';
      const trialBtn = document.querySelector('[data-package="trial"]');
      const trialCard = trialBtn?.closest('.single-price');
      if (trialCard) {
        const p = trialCard.querySelector('.package-price');
        if (p) p.textContent = trialPrice;
      }

      const p1m = parsePrice(cfg.price1m, 39000);
      const card1m = document.querySelector('[data-package="1month"]')?.closest('.single-price');
      if (card1m) {
        const p = card1m.querySelector('.package-price');
        if (p) p.textContent = formatVND(p1m);
      }

      const p3m = parsePrice(cfg.price3m, 99000);
      const card3m = document.querySelector('[data-package="3month"]')?.closest('.single-price');
      if (card3m) {
        const p = card3m.querySelector('.package-price');
        if (p) p.textContent = formatVND(p3m);
        const perMonth = card3m.querySelector('.package-details strong');
        if (perMonth) perMonth.textContent = `~${formatVND(Math.round(p3m / 3))}/tháng`;
      }

      const p6m = parsePrice(cfg.price6m, 179000);
      const card6m = document.querySelector('[data-package="6month"]')?.closest('.single-price');
      if (card6m) {
        const p = card6m.querySelector('.package-price');
        if (p) p.textContent = formatVND(p6m);
        const perMonth = card6m.querySelector('.package-details strong');
        if (perMonth) perMonth.textContent = `~${formatVND(Math.round(p6m / 6))}/tháng`;
      }

      const p9m = parsePrice(cfg.price9m, 249000);
      const card9m = document.querySelector('[data-package="9month"]')?.closest('.single-price');
      if (card9m) {
        const p = card9m.querySelector('.package-price');
        if (p) p.textContent = formatVND(p9m);
        const perMonth = card9m.querySelector('.package-details strong');
        if (perMonth) perMonth.textContent = `~${formatVND(Math.round(p9m / 9))}/tháng`;
      }

      const p1y = parsePrice(cfg.price1y, 299000);
      const card1y = document.querySelector('[data-package="1year"]')?.closest('.single-price');
      if (card1y) {
        const p = card1y.querySelector('.package-price');
        if (p) p.textContent = formatVND(p1y);
        const perMonth = card1y.querySelector('.package-details strong');
        if (perMonth) perMonth.textContent = `~${formatVND(Math.round(p1y / 12))}/tháng`;
      }
    }

    // 3. BRAND NAME & SLOGAN
    if (cfg.brandName) {
      document.querySelectorAll('.seo-pillnav-drawer-title, .seo-download-card__title').forEach(el => {
        el.textContent = cfg.brandName;
      });
      const headerBrand = document.querySelector('.seo-pillnav-brand-text');
      if (headerBrand) {
        headerBrand.textContent = 'Đọc thông báo';
      }
      const heroTitle = document.querySelector('.seo-hero-title');
      if (heroTitle) {
        const firstChild = heroTitle.childNodes[0];
        if (firstChild && firstChild.nodeType === Node.TEXT_NODE) {
          firstChild.nodeValue = `${cfg.brandName} \n`;
        }
      }
      const footerBrand = document.querySelector('.footer-widget strong');
      if (footerBrand) footerBrand.textContent = cfg.brandName;
      const footerCredit = document.querySelector('.footer-cradit strong');
      if (footerCredit) footerCredit.textContent = cfg.brandName;
      document.title = `${cfg.brandName} — Loa báo tiền tự động 65+ Ngân hàng & Ví điện tử`;
    }

    if (cfg.brandSlogan) {
      const sloganText = document.querySelector('.seo-hero-slogan-text');
      if (sloganText) sloganText.textContent = cfg.brandSlogan;
      const downloadSlogan = document.querySelector('.seo-download-card__slogan');
      if (downloadSlogan) downloadSlogan.textContent = cfg.brandSlogan;
    }

    // 4. CH PLAY (GOOGLE PLAY STORE)
    const playUrl = cfg.chplayLink || cfg.googlePlayUrl || 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app';
    if (playUrl) {
      document.querySelectorAll('a[href*="play.google.com"], #header-cta-btn, #drawer-cta-btn').forEach(a => {
        a.href = playUrl;
      });
    }

    // 5. YOUTUBE VIDEO & PLAYLIST (Full Dynamic Sync)
    const ytUrl = (cfg.youtubeLink || cfg.youtubeUrl || '').trim();
    const videoSection = document.getElementById('video');
    const navVideoLinks = document.querySelectorAll('a[href="#video"]');

    if (!ytUrl) {
      if (videoSection) videoSection.style.display = 'none';
      navVideoLinks.forEach(link => { link.style.display = 'none'; });
      const footerYt = document.getElementById('footer-yt-link');
      if (footerYt) footerYt.style.display = 'none';
    } else {
      if (videoSection) videoSection.style.display = '';
      navVideoLinks.forEach(link => { link.style.display = ''; });
      const footerYt = document.getElementById('footer-yt-link');
      if (footerYt) {
        footerYt.style.display = '';
        footerYt.href = ytUrl;
      }

      document.querySelectorAll('a.youtube, a[href*="youtube.com"], a[href*="youtu.be"]').forEach(a => {
        a.href = ytUrl;
      });

      const channelLink = document.getElementById('yt-channel-link');
      if (channelLink) {
        channelLink.href = ytUrl;
        const handleMatch = ytUrl.match(/@([a-zA-Z0-9_\-]+)/);
        if (handleMatch) channelLink.textContent = `@${handleMatch[1]}`;
      }

      const playlistLink = document.getElementById('yt-playlist-link');
      if (playlistLink) {
        const listMatch = ytUrl.match(/[?&]list=([^#&?]+)/);
        if (listMatch) {
          playlistLink.href = `https://www.youtube.com/playlist?list=${listMatch[1]}`;
        } else {
          playlistLink.href = ytUrl;
        }
      }
    }

    if (window.autobankUpdateYouTube) {
      window.autobankUpdateYouTube(cfg);
    }

    // 6. SOCIAL MEDIA
    if (cfg.facebook) {
      document.querySelectorAll('a.facebook, a[href*="facebook.com"]').forEach(a => {
        a.href = cfg.facebook;
      });
    }
    if (cfg.tiktok) {
      document.querySelectorAll('a.tiktok, a[href*="tiktok.com"]').forEach(a => {
        a.href = cfg.tiktok;
      });
    }

    // 7. EMAIL
    if (cfg.email) {
      document.querySelectorAll('a[href^="mailto:"]').forEach(a => {
        a.href = `mailto:${cfg.email}`;
        if (a.textContent.includes('@')) a.textContent = cfg.email;
      });
      document.querySelectorAll('.seo-contact-card').forEach(card => {
        const label = card.querySelector('.seo-contact-card__label')?.textContent?.trim().toLowerCase() || '';
        if (label.includes('email')) {
          card.href = `mailto:${cfg.email}`;
          const val = card.querySelector('.seo-contact-card__value');
          if (val) val.textContent = cfg.email;
        }
      });
    }

    // 8. NON-OVERLAPPING FLOATING CONTACT WIDGET
    renderFloatingWidgets(zaloUrl, rawHotline, intlPhone);

    // 9. SYSTEM MAINTENANCE BANNER
    renderMaintenanceBanner(cfg);
  }

  function renderFloatingWidgets(zaloUrl, rawHotline, intlPhone) {
    let wrap = document.getElementById('ab-floating-contact');
    if (!wrap) {
      wrap = document.createElement('div');
      wrap.id = 'ab-floating-contact';
      document.body.appendChild(wrap);
    }

    wrap.innerHTML = `
      <style>
        #ab-floating-contact {
          position: fixed !important;
          bottom: calc(20px + env(safe-area-inset-bottom, 0px)) !important;
          right: calc(18px + env(safe-area-inset-right, 0px)) !important;
          z-index: 990 !important;
          pointer-events: auto !important;
        }
        body.seo-nav-open #ab-floating-contact,
        body.seo-nav-open .back-to-top {
          display: none !important;
        }
        .ab-floating-box {
          display: flex !important;
          flex-direction: column !important;
          gap: 10px !important;
          align-items: flex-end !important;
          margin: 0 !important;
          padding: 0 !important;
        }
        .ab-float-btn {
          display: inline-flex !important;
          align-items: center !important;
          gap: 8px !important;
          padding: 6px 14px 6px 8px !important;
          border-radius: 999px !important;
          color: #ffffff !important;
          text-decoration: none !important;
          font-weight: 700 !important;
          font-size: 0.85rem !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2) !important;
          border: 1.5px solid rgba(255, 255, 255, 0.4) !important;
          backdrop-filter: blur(8px) !important;
          -webkit-backdrop-filter: blur(8px) !important;
          transition: transform 0.2s ease, box-shadow 0.2s ease !important;
          height: 40px !important;
          box-sizing: border-box !important;
          line-height: 1 !important;
          cursor: pointer !important;
        }
        .ab-float-btn:hover {
          transform: translateY(-2px) scale(1.02) !important;
          box-shadow: 0 10px 24px rgba(0, 0, 0, 0.28) !important;
          color: #ffffff !important;
        }
        .ab-float-btn-zalo {
          background: linear-gradient(135deg, #0068ff 0%, #0284c7 100%) !important;
        }
        .ab-float-btn-call {
          background: linear-gradient(135deg, #10b981 0%, #059669 100%) !important;
        }
        .ab-float-icon-bubble {
          width: 28px !important;
          height: 28px !important;
          border-radius: 50% !important;
          background: rgba(255, 255, 255, 0.28) !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          flex-shrink: 0 !important;
        }
        @media (max-width: 767px) {
          #ab-floating-contact {
            bottom: calc(14px + env(safe-area-inset-bottom, 0px)) !important;
            right: 12px !important;
          }
          .ab-floating-box {
            gap: 8px !important;
          }
          .ab-float-btn {
            width: 42px !important;
            height: 42px !important;
            min-width: 42px !important;
            padding: 0 !important;
            justify-content: center !important;
            border-radius: 50% !important;
          }
          .ab-float-label {
            display: none !important;
          }
          .ab-float-icon-bubble {
            width: 100% !important;
            height: 100% !important;
            background: transparent !important;
          }
        }
      </style>
      <div class="ab-floating-box">
        <a href="${zaloUrl}" id="ab-float-zalo" target="_blank" rel="noopener" class="ab-float-btn ab-float-btn-zalo" title="Chat Zalo hỗ trợ tức thì">
          <div class="ab-float-icon-bubble">
            <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z"/></svg>
          </div>
          <span class="ab-float-label">Chat Zalo hỗ trợ</span>
        </a>
        <a href="tel:${intlPhone}" id="ab-float-call" class="ab-float-btn ab-float-btn-call" title="Gọi hotline ${rawHotline}">
          <div class="ab-float-icon-bubble">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/></svg>
          </div>
          <span class="ab-float-label">${rawHotline}</span>
        </a>
      </div>
    `;
  }

  function renderMaintenanceBanner(cfg) {
    const isMaint = cfg.maintenance === true || cfg.maintenanceMode === true;
    const existing = document.getElementById('ab-system-live-banner');
    if (isMaint) {
      if (!existing) {
        const banner = document.createElement('div');
        banner.id = 'ab-system-live-banner';
        banner.style.cssText = `
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          z-index: 999999;
          background: linear-gradient(90deg, #ea580c, #c2410c);
          color: #ffffff;
          font-size: 0.88rem;
          font-weight: 700;
          padding: 10px 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          box-shadow: 0 4px 14px rgba(0,0,0,0.25);
          text-align: center;
        `;
        banner.innerHTML = `
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          <span>[THÔNG BÁO TỪ HỆ THỐNG]: ${cfg.maintenanceMsg || 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ.'}</span>
        `;
        document.body.prepend(banner);
        document.body.style.paddingTop = '42px';
      }
    } else if (existing) {
      existing.remove();
      document.body.style.paddingTop = '';
    }
  }

  // Expose globally
  window.autobankApplyConfig = applyConfig;

  // 1. Synchronous initial load from localStorage
  try {
    const raw = localStorage.getItem('autobank_system_config');
    if (raw) applyConfig(JSON.parse(raw));
  } catch (_) {}

  // 2. Listen to modern BroadcastChannel (instant inter-tab event)
  try {
    const channel = new BroadcastChannel('autobank_live_channel');
    channel.onmessage = (e) => {
      if (e.data && e.data.type === 'CONFIG_UPDATED' && e.data.config) {
        applyConfig(e.data.config);
      }
    };
  } catch (_) {}

  // 3. Listen to window custom event
  window.addEventListener('autobank_config_updated', (e) => {
    if (e.detail) applyConfig(e.detail);
  });

  // 4. Listen to standard storage event (other tabs)
  window.addEventListener('storage', (e) => {
    if (e.key === 'autobank_system_config' && e.newValue) {
      try {
        applyConfig(JSON.parse(e.newValue));
      } catch (_) {}
    }
  });

  // 5. Fetch fresh from NestJS API immediately
  const syncFromApi = () => {
    fetch(`${API_BASE}/admin/configs`)
      .then(res => res.json())
      .then(data => {
        if (data && (data.brandName || data.hotline || data.packages)) {
          const localRaw = localStorage.getItem('autobank_system_config');
          const local = localRaw ? JSON.parse(localRaw) : {};
          const merged = { ...local, ...data };
          localStorage.setItem('autobank_system_config', JSON.stringify(merged));
          applyConfig(merged);
        }
      })
      .catch(() => {});
  };

  syncFromApi();

  // 6. Real-time background sync polling 24/24 (every 4 seconds)
  setInterval(syncFromApi, 4000);
}
