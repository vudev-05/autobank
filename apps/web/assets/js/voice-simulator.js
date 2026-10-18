/**
 * AutoBank High-Speed Voice Simulator (Loa Báo Tiền Tự Động)
 * Đồng bộ chuẩn 100% Mobile App AutoBank & Giao diện Màu Xanh Nước (Water Blue)
 * Hỗ trợ Web Audio Synthesizer, Edge-TTS API, Google TTS & Web Speech API fallback
 */

let globalAudioCtx = null;
function getAudioContext() {
  if (!globalAudioCtx) {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (AudioCtx) {
      globalAudioCtx = new AudioCtx();
    }
  }
  if (globalAudioCtx && globalAudioCtx.state === 'suspended') {
    globalAudioCtx.resume().catch(() => {});
  }
  return globalAudioCtx;
}

// Convert amount number to smooth, natural Vietnamese currency words
function numberToVietnameseWords(num) {
  const n = parseInt(String(num).replace(/\D/g, ''), 10);
  if (isNaN(n) || n === 0) return 'không đồng';

  // Common quick shortcuts
  const fixedMap = {
    30000: 'ba mươi nghìn đồng',
    50000: 'năm mươi nghìn đồng',
    80000: 'tám mươi nghìn đồng',
    100000: 'một trăm nghìn đồng',
    150000: 'một trăm năm mươi nghìn đồng',
    200000: 'hai trăm nghìn đồng',
    250000: 'hai trăm năm mươi nghìn đồng',
    300000: 'ba trăm nghìn đồng',
    500000: 'năm trăm nghìn đồng',
    1000000: 'một triệu đồng',
    1500000: 'một triệu năm trăm nghìn đồng',
    2000000: 'hai triệu đồng',
    5000000: 'năm triệu đồng',
    10000000: 'mười triệu đồng',
  };
  if (fixedMap[n]) return fixedMap[n];

  // Algorithmic converter for arbitrary Vietnamese currency numbers
  const digits = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];

  function read3Digits(val, isFirstBlock) {
    const h = Math.floor(val / 100);
    const t = Math.floor((val % 100) / 10);
    const u = val % 10;
    let res = '';

    if (h > 0 || !isFirstBlock) {
      res += digits[h] + ' trăm ';
    }

    if (t > 1) {
      res += digits[t] + ' mươi ';
      if (u === 1) res += 'mốt ';
      else if (u === 5) res += 'lăm ';
      else if (u > 0) res += digits[u] + ' ';
    } else if (t === 1) {
      res += 'mười ';
      if (u === 5) res += 'lăm ';
      else if (u > 0) res += digits[u] + ' ';
    } else {
      if (h > 0 || !isFirstBlock) {
        if (u > 0) res += 'lẻ ' + digits[u] + ' ';
      } else {
        if (u > 0) res += digits[u] + ' ';
      }
    }
    return res.trim();
  }

  const billions = Math.floor(n / 1000000000);
  const millions = Math.floor((n % 1000000000) / 1000000);
  const thousands = Math.floor((n % 1000000) / 1000);
  const units = n % 1000;

  let out = '';
  let isFirst = true;

  if (billions > 0) {
    out += read3Digits(billions, isFirst) + ' tỷ ';
    isFirst = false;
  }
  if (millions > 0) {
    out += read3Digits(millions, isFirst) + ' triệu ';
    isFirst = false;
  }
  if (thousands > 0) {
    out += read3Digits(thousands, isFirst) + ' nghìn ';
    isFirst = false;
  }
  if (units > 0 && isFirst) {
    out += read3Digits(units, true) + ' ';
  }

  return (out.trim() || String(n)) + ' đồng';
}

// Format number with dots for preview (e.g. 250.000 ₫)
function formatCurrencyPreview(num) {
  const n = parseInt(String(num).replace(/\D/g, ''), 10);
  return isNaN(n) ? '250.000 ₫' : `${n.toLocaleString('vi-VN')} ₫`;
}

// Web Audio synthesizer for crisp Ting-Ting chime (0ms latency, zero delay)
function playTingTingChime() {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;

    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(880, ctx.currentTime);
    gain1.gain.setValueAtTime(0, ctx.currentTime);
    gain1.gain.linearRampToValueAtTime(0.28, ctx.currentTime + 0.015);
    gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.16);
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    osc1.start();
    osc1.stop(ctx.currentTime + 0.16);

    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(1320, ctx.currentTime + 0.05);
    gain2.gain.setValueAtTime(0, ctx.currentTime + 0.05);
    gain2.gain.linearRampToValueAtTime(0.30, ctx.currentTime + 0.07);
    gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.20);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(ctx.currentTime + 0.05);
    osc2.stop(ctx.currentTime + 0.20);
  } catch (_) {}
}

let isInitialized = false;

export function initVoiceSimulator() {
  if (isInitialized) return;

  const playBtn = document.getElementById('ab-voice-play-btn');
  const bankSelect = document.getElementById('ab-voice-bank-select');
  const amountInput = document.getElementById('ab-voice-amount-input');
  const amountLabel = document.getElementById('ab-voice-amount-label');
  const quickPillsContainer = document.getElementById('ab-voice-quick-pills');
  const modeCreditBtn = document.getElementById('ab-voice-mode-credit');
  const modeDebitBtn = document.getElementById('ab-voice-mode-debit');
  const presetChips = document.querySelectorAll('[data-preset]');
  const prefixSelect = document.getElementById('ab-voice-prefix-select');
  const bankStyleSelect = document.getElementById('ab-voice-bank-style-select');
  const suffixSelect = document.getElementById('ab-voice-suffix-select');
  const speedPills = document.querySelectorAll('.ab-voice-speed-pill');
  const optChime = document.getElementById('ab-voice-opt-chime');
  const playerCard = document.getElementById('ab-voice-player-card');
  const cardTitle = document.getElementById('ab-voice-card-title');
  const voiceWave = document.getElementById('ab-voice-wave');
  const voiceStatus = document.getElementById('ab-voice-status');

  if (!playBtn) return;
  isInitialized = true;

  // Water Blue Theme Palette
  const THEME = {
    credit: {
      primary: '#0284c7',
      dark: '#0369a1',
      deep: '#075985',
      lightBg: '#f0f9ff',
      border: '#0284c7',
      textColor: '#0369a1',
      gradient: 'linear-gradient(135deg, #075985 0%, #0369a1 50%, #0284c7 100%)',
      shadow: '0 14px 34px rgba(2, 132, 199, 0.28)',
      statusColor: '#e0f2fe',
      waveColor: '#7dd3fc',
      btnText: '#0284c7',
    },
    debit: {
      primary: '#0369a1',
      dark: '#075985',
      deep: '#0c4a6e',
      lightBg: '#f0f9ff',
      border: '#0369a1',
      textColor: '#075985',
      gradient: 'linear-gradient(135deg, #0c4a6e 0%, #075985 50%, #0369a1 100%)',
      shadow: '0 14px 34px rgba(3, 105, 161, 0.28)',
      statusColor: '#e0f2fe',
      waveColor: '#7dd3fc',
      btnText: '#0369a1',
    },
  };

  // State
  let currentMode = 'credit'; // 'credit' | 'debit'
  let currentPreset = 'BANK_STANDARD';
  let currentSpeed = 1.15;
  let playbackToken = 0;
  let activeAudio = null;
  let speechTimeout = null;

  // In-memory audio cache
  const audioCache = new Map();

  // App-Matching Option Catalogues
  const CREDIT_PREFIXES = [
    { value: 'Đã nhận', label: 'Đã nhận' },
    { value: 'Tài khoản vừa cộng', label: 'Tài khoản vừa cộng' },
    { value: 'Khách chuyển khoản', label: 'Khách chuyển khoản' },
    { value: 'Thu tiền thành công', label: 'Thu tiền thành công' },
    { value: 'Ting ting! Đã nhận', label: 'Ting ting! Đã nhận' },
    { value: 'Khách thanh toán', label: 'Khách thanh toán' },
    { value: 'Vừa nhận được', label: 'Vừa nhận được' },
    { value: '', label: 'Không đọc câu mở đầu (Vào thẳng số tiền)' },
  ];

  const DEBIT_PREFIXES = [
    { value: 'Đã chuyển', label: 'Đã chuyển' },
    { value: 'Tài khoản vừa trừ', label: 'Tài khoản vừa trừ' },
    { value: 'Thanh toán thành công', label: 'Thanh toán thành công' },
    { value: 'Chuyển khoản thành công', label: 'Chuyển khoản thành công' },
    { value: 'Vừa chuyển đi', label: 'Vừa chuyển đi' },
    { value: '', label: 'Không đọc câu mở đầu (Vào thẳng số tiền)' },
  ];

  const CREDIT_BANK_STYLES = [
    { value: 'tu', label: 'từ [Ngân hàng]' },
    { value: 'qua', label: 'qua [Ngân hàng]' },
    { value: 'vao', label: 'vào tài khoản [Ngân hàng]' },
    { value: 'ten', label: 'Chỉ đọc tên [Ngân hàng]' },
    { value: 'none', label: 'Không đọc tên ngân hàng' },
  ];

  const DEBIT_BANK_STYLES = [
    { value: 'qua', label: 'qua [Ngân hàng]' },
    { value: 'tu', label: 'từ tài khoản [Ngân hàng]' },
    { value: 'bang', label: 'bằng [Ngân hàng]' },
    { value: 'ten', label: 'Chỉ đọc tên [Ngân hàng]' },
    { value: 'none', label: 'Không đọc tên ngân hàng' },
  ];

  const CREDIT_SUFFIXES = [
    { value: 'Cảm ơn quý khách!', label: 'Cảm ơn quý khách!' },
    { value: 'Chúc ngày mới đắt hàng!', label: 'Chúc ngày mới đắt hàng!' },
    { value: 'Hẹn gặp lại quý khách!', label: 'Hẹn gặp lại quý khách!' },
    { value: 'Giao dịch thành công!', label: 'Giao dịch thành công!' },
    { value: '', label: 'Không đọc lời cảm ơn' },
  ];

  const DEBIT_SUFFIXES = [
    { value: 'Giao dịch hoàn tất!', label: 'Giao dịch hoàn tất!' },
    { value: 'Thanh toán thành công!', label: 'Thanh toán thành công!' },
    { value: 'Đã lưu biên lai!', label: 'Đã lưu biên lai!' },
    { value: 'Chuyển tiền thành công!', label: 'Chuyển tiền thành công!' },
    { value: '', label: 'Không đọc lời kết' },
  ];

  const CREDIT_AMOUNTS = [
    { val: '50000', label: '50.000 ₫' },
    { val: '250000', label: '250.000 ₫' },
    { val: '500000', label: '500.000 ₫' },
    { val: '1500000', label: '1.500.000 ₫' },
    { val: '5000000', label: '5.000.000 ₫' },
  ];

  const DEBIT_AMOUNTS = [
    { val: '30000', label: '30.000 ₫' },
    { val: '150000', label: '150.000 ₫' },
    { val: '500000', label: '500.000 ₫' },
    { val: '2000000', label: '2.000.000 ₫' },
  ];

  // Refresh Select Options when Tab changes (Credit <-> Debit)
  function syncFormBuilderOptions() {
    if (prefixSelect) {
      const list = currentMode === 'credit' ? CREDIT_PREFIXES : DEBIT_PREFIXES;
      prefixSelect.innerHTML = list.map((item, i) => `<option value="${item.value}" ${i === 0 ? 'selected' : ''}>${item.label}</option>`).join('');
    }
    if (bankStyleSelect) {
      const list = currentMode === 'credit' ? CREDIT_BANK_STYLES : DEBIT_BANK_STYLES;
      bankStyleSelect.innerHTML = list.map((item, i) => `<option value="${item.value}" ${i === 0 ? 'selected' : ''}>${item.label}</option>`).join('');
    }
    if (suffixSelect) {
      const list = currentMode === 'credit' ? CREDIT_SUFFIXES : DEBIT_SUFFIXES;
      suffixSelect.innerHTML = list.map((item, i) => `<option value="${item.value}" ${i === 0 ? 'selected' : ''}>${item.label}</option>`).join('');
    }
    if (quickPillsContainer) {
      const list = currentMode === 'credit' ? CREDIT_AMOUNTS : DEBIT_AMOUNTS;
      quickPillsContainer.innerHTML = list.map((item, i) =>
        `<button type="button" class="ab-voice-pill ${i === 1 ? 'active' : ''}" data-voice-amount="${item.val}">${item.label}</button>`
      ).join('');
      attachQuickPillListeners();
    }
    if (amountInput) {
      amountInput.value = currentMode === 'credit' ? '250000' : '150000';
    }
  }

  function attachQuickPillListeners() {
    document.querySelectorAll('#ab-voice-quick-pills .ab-voice-pill').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#ab-voice-quick-pills .ab-voice-pill').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const amt = btn.getAttribute('data-voice-amount');
        if (amountInput && amt) {
          amountInput.value = amt;
        }
        updateStatusDisplay();
        stopPlayback();
      });
    });
  }

  // Apply a Preset to the Form Controls (Parity with Mobile App Presets)
  function applyPreset(presetId) {
    currentPreset = presetId;

    if (currentMode === 'credit') {
      switch (presetId) {
        case 'FAST_RUSH':
          if (prefixSelect) prefixSelect.value = 'Đã nhận';
          if (bankStyleSelect) bankStyleSelect.value = 'none';
          if (suffixSelect) suffixSelect.value = '';
          if (optChime) optChime.checked = false;
          break;
        case 'STORE_POLITE':
          if (prefixSelect) prefixSelect.value = 'Thu tiền thành công';
          if (bankStyleSelect) bankStyleSelect.value = 'tu';
          if (suffixSelect) suffixSelect.value = 'Cảm ơn quý khách!';
          if (optChime) optChime.checked = true;
          break;
        case 'FULL_RECONCILE':
          if (prefixSelect) prefixSelect.value = 'Tài khoản vừa cộng';
          if (bankStyleSelect) bankStyleSelect.value = 'vao';
          if (suffixSelect) suffixSelect.value = 'Giao dịch thành công!';
          if (optChime) optChime.checked = true;
          break;
        case 'BANK_STANDARD':
        default:
          if (prefixSelect) prefixSelect.value = 'Đã nhận';
          if (bankStyleSelect) bankStyleSelect.value = 'tu';
          if (suffixSelect) suffixSelect.value = 'Cảm ơn quý khách!';
          if (optChime) optChime.checked = true;
          break;
      }
    } else {
      switch (presetId) {
        case 'FAST_RUSH':
          if (prefixSelect) prefixSelect.value = 'Đã chuyển';
          if (bankStyleSelect) bankStyleSelect.value = 'none';
          if (suffixSelect) suffixSelect.value = '';
          if (optChime) optChime.checked = false;
          break;
        case 'STORE_POLITE':
          if (prefixSelect) prefixSelect.value = 'Thanh toán thành công';
          if (bankStyleSelect) bankStyleSelect.value = 'qua';
          if (suffixSelect) suffixSelect.value = 'Giao dịch hoàn tất!';
          if (optChime) optChime.checked = true;
          break;
        case 'FULL_RECONCILE':
          if (prefixSelect) prefixSelect.value = 'Tài khoản vừa trừ';
          if (bankStyleSelect) bankStyleSelect.value = 'tu';
          if (suffixSelect) suffixSelect.value = 'Thanh toán thành công!';
          if (optChime) optChime.checked = true;
          break;
        case 'BANK_STANDARD':
        default:
          if (prefixSelect) prefixSelect.value = 'Đã chuyển';
          if (bankStyleSelect) bankStyleSelect.value = 'qua';
          if (suffixSelect) suffixSelect.value = 'Giao dịch hoàn tất!';
          if (optChime) optChime.checked = true;
          break;
      }
    }

    // Highlight active preset chip with Water Blue
    presetChips.forEach(c => {
      const isCur = c.getAttribute('data-preset') === presetId;
      c.classList.toggle('active', isCur);
      c.style.borderColor = isCur ? THEME.credit.border : '#e2e8f0';
      c.style.background = isCur ? THEME.credit.lightBg : '#fff';
      c.style.color = isCur ? THEME.credit.textColor : '#334155';
    });
  }

  // Master Sentence Builder: Combines All Form Options Faithfully
  function buildSentence(isForSpeech) {
    const rawAmt = amountInput ? amountInput.value : '250000';
    const amtStr = isForSpeech ? numberToVietnameseWords(rawAmt) : formatCurrencyPreview(rawAmt);
    const bankName = (bankSelect && bankSelect.value) ? bankSelect.value : 'Techcombank';
    const bankStyle = bankStyleSelect ? bankStyleSelect.value : 'tu';
    const prefixWord = prefixSelect ? prefixSelect.value.trim() : '';
    const suffixWord = suffixSelect ? suffixSelect.value.trim() : '';
    const shouldChime = optChime ? optChime.checked : true;

    let bankPhrase = '';
    if (bankStyle === 'tu') {
      bankPhrase = `từ ${bankName}`;
    } else if (bankStyle === 'qua') {
      bankPhrase = `qua ${bankName}`;
    } else if (bankStyle === 'vao') {
      bankPhrase = `vào tài khoản ${bankName}`;
    } else if (bankStyle === 'bang') {
      bankPhrase = `bằng ${bankName}`;
    } else if (bankStyle === 'ten') {
      bankPhrase = bankName;
    } else if (bankStyle === 'none') {
      bankPhrase = '';
    }

    const parts = [];
    if (prefixWord) parts.push(prefixWord);
    parts.push(amtStr);
    if (bankPhrase) parts.push(bankPhrase);

    let mainSentence = parts.join(' ');

    if (!isForSpeech && shouldChime) {
      mainSentence = '🔔 Ting! ' + mainSentence;
    }

    if (suffixWord) {
      if (mainSentence.length > 0) {
        mainSentence += (mainSentence.endsWith('.') ? ' ' : '. ') + suffixWord;
      } else {
        mainSentence = suffixWord;
      }
    }

    return mainSentence;
  }

  function updateStatusDisplay() {
    if (voiceStatus) {
      voiceStatus.innerHTML = `"${buildSentence(false)}"`;
    }
  }

  // Master Stop Audio & Visualizer
  function stopPlayback() {
    playbackToken++;
    if (speechTimeout) {
      clearTimeout(speechTimeout);
      speechTimeout = null;
    }
    if (activeAudio) {
      try {
        activeAudio.pause();
        activeAudio.currentTime = 0;
      } catch (_) {}
      activeAudio = null;
    }
    if ('speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel();
      } catch (_) {}
    }
    if (voiceWave) voiceWave.classList.remove('is-playing');
    if (playBtn) {
      playBtn.classList.remove('is-playing');
      playBtn.style.color = THEME.credit.btnText;
      playBtn.innerHTML = `
        <span style="display: inline-flex; align-items: center; gap: 8px;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3" /></svg>
          Bấm nghe thử giọng đọc
        </span>
      `;
    }
  }

  // Pre-fetch Audio stream from Backend / Google Translate
  function getChiGoogleAudio(text) {
    if (audioCache.has(text)) {
      return audioCache.get(text);
    }
    const apiBase = (typeof window !== 'undefined' && window.location.port === '5173')
      ? 'http://localhost:3000'
      : (window.location.origin || 'http://localhost:3000');
    const audioUrl = `${apiBase}/tts?voice=chi-google&text=${encodeURIComponent(text)}`;
    const aud = new Audio(audioUrl);
    aud.preload = 'auto';
    audioCache.set(text, aud);
    return aud;
  }

  // Core 0ms Instant Playback using Authentic Voice Engine
  function speakCurrentConfig() {
    stopPlayback();
    const token = ++playbackToken;

    getAudioContext();
    updateStatusDisplay();

    const spokenSentence = buildSentence(true);
    const shouldChime = (optChime && optChime.checked);

    // 1. Play Ting-Ting chime instantly (0ms)
    if (shouldChime) {
      playTingTingChime();
    }

    if (voiceWave) voiceWave.classList.add('is-playing');
    if (playBtn) {
      playBtn.classList.add('is-playing');
      playBtn.innerHTML = `
        <span style="display: inline-flex; align-items: center; gap: 8px;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
          Đang đọc thông báo...
        </span>
      `;
    }

    const speechDelay = shouldChime ? 130 : 0;

    speechTimeout = setTimeout(() => {
      if (token !== playbackToken) return;

      const audio = getChiGoogleAudio(spokenSentence);
      activeAudio = audio;
      audio.playbackRate = currentSpeed;
      audio.currentTime = 0;

      let playedSuccessfully = false;

      audio.onended = () => {
        if (token === playbackToken) stopPlayback();
      };

      // Fallback 1: Direct Google Translate TTS URL
      const tryGoogleTranslateDirect = () => {
        if (playedSuccessfully || token !== playbackToken) return;
        const gUrl = `https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=${encodeURIComponent(spokenSentence)}`;
        const gAudio = new Audio(gUrl);
        activeAudio = gAudio;
        gAudio.playbackRate = currentSpeed;
        gAudio.onended = () => { if (token === playbackToken) stopPlayback(); };
        gAudio.onerror = fallbackToWebSpeech;
        const gp = gAudio.play();
        if (gp !== undefined) {
          gp.then(() => { playedSuccessfully = true; }).catch(fallbackToWebSpeech);
        } else {
          playedSuccessfully = true;
        }
      };

      // Fallback 2: Browser Web Speech API
      const fallbackToWebSpeech = () => {
        if (playedSuccessfully || token !== playbackToken) return;
        if (!('speechSynthesis' in window)) {
          stopPlayback();
          return;
        }
        try {
          window.speechSynthesis.cancel();
          const utterance = new SpeechSynthesisUtterance(spokenSentence);
          utterance.lang = 'vi-VN';
          utterance.rate = currentSpeed;
          utterance.pitch = 1.0;

          const voices = window.speechSynthesis.getVoices();
          const gv = voices.find(v => v.name.toLowerCase().includes('google') && (v.lang.includes('vi') || v.lang.includes('VN'))) ||
                     voices.find(v => v.lang.includes('vi') || v.lang.includes('VN'));
          if (gv) utterance.voice = gv;

          utterance.onend = () => { if (token === playbackToken) stopPlayback(); };
          utterance.onerror = () => { if (token === playbackToken) stopPlayback(); };
          window.speechSynthesis.speak(utterance);
        } catch (_) {
          stopPlayback();
        }
      };

      audio.onerror = tryGoogleTranslateDirect;

      const p = audio.play();
      if (p !== undefined) {
        p.then(() => {
          playedSuccessfully = true;
        }).catch(() => {
          tryGoogleTranslateDirect();
        });
      }
    }, speechDelay);
  }

  // Trigger Play / Pause Button
  if (playBtn) {
    playBtn.addEventListener('click', () => {
      if (playBtn.classList.contains('is-playing')) {
        stopPlayback();
      } else {
        speakCurrentConfig();
      }
    });
  }

  // 1. Transaction Mode Tabs: Credit vs Debit
  if (modeCreditBtn) {
    modeCreditBtn.addEventListener('click', () => {
      currentMode = 'credit';
      modeCreditBtn.classList.add('active');
      modeCreditBtn.style.background = THEME.credit.primary;
      modeCreditBtn.style.color = '#fff';
      modeCreditBtn.style.boxShadow = '0 2px 8px rgba(2, 132, 199, 0.35)';

      if (modeDebitBtn) {
        modeDebitBtn.classList.remove('active');
        modeDebitBtn.style.background = 'transparent';
        modeDebitBtn.style.color = '#475569';
        modeDebitBtn.style.boxShadow = 'none';
      }

      if (playerCard) {
        playerCard.style.background = THEME.credit.gradient;
        playerCard.style.boxShadow = THEME.credit.shadow;
      }
      if (cardTitle) cardTitle.textContent = 'Nghe Thử Câu Đọc Nhận Tiền';
      if (amountLabel) amountLabel.textContent = 'Số tiền nhận thử nghiệm (VNĐ):';

      syncFormBuilderOptions();
      applyPreset('BANK_STANDARD');
      updateStatusDisplay();
      stopPlayback();
    });
  }

  if (modeDebitBtn) {
    modeDebitBtn.addEventListener('click', () => {
      currentMode = 'debit';
      modeDebitBtn.classList.add('active');
      modeDebitBtn.style.background = THEME.debit.primary;
      modeDebitBtn.style.color = '#fff';
      modeDebitBtn.style.boxShadow = '0 2px 8px rgba(3, 105, 161, 0.35)';

      if (modeCreditBtn) {
        modeCreditBtn.classList.remove('active');
        modeCreditBtn.style.background = 'transparent';
        modeCreditBtn.style.color = '#475569';
        modeCreditBtn.style.boxShadow = 'none';
      }

      if (playerCard) {
        playerCard.style.background = THEME.debit.gradient;
        playerCard.style.boxShadow = THEME.debit.shadow;
      }
      if (cardTitle) cardTitle.textContent = 'Nghe Thử Câu Đọc Trừ Tiền';
      if (amountLabel) amountLabel.textContent = 'Số tiền chuyển đi (VNĐ):';

      syncFormBuilderOptions();
      applyPreset('BANK_STANDARD');
      updateStatusDisplay();
      stopPlayback();
    });
  }

  // 2. Reading Presets
  presetChips.forEach(chip => {
    chip.addEventListener('click', () => {
      const presetId = chip.getAttribute('data-preset') || 'BANK_STANDARD';
      applyPreset(presetId);
      updateStatusDisplay();
      stopPlayback();
    });
  });

  // 3. Bank Selection
  if (bankSelect) {
    bankSelect.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }

  // 4. Amount Input change
  if (amountInput) {
    amountInput.addEventListener('input', () => {
      updateStatusDisplay();
    });
    amountInput.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }

  // 5. Prefix, Bank Style, Suffix Selectors
  if (prefixSelect) {
    prefixSelect.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }
  if (bankStyleSelect) {
    bankStyleSelect.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }
  if (suffixSelect) {
    suffixSelect.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }

  // 6. Voice Speed Selection
  speedPills.forEach(pill => {
    pill.addEventListener('click', () => {
      speedPills.forEach(p => {
        p.classList.remove('active');
        p.style.background = '#fff';
        p.style.color = '#0f172a';
        p.style.borderColor = '#cbd5e1';
      });
      pill.classList.add('active');
      pill.style.background = THEME.credit.primary;
      pill.style.color = '#fff';
      pill.style.borderColor = THEME.credit.primary;
      currentSpeed = parseFloat(pill.getAttribute('data-speed') || '1.15');
      stopPlayback();
    });
  });

  // 7. Ting-Ting Chime Toggle
  if (optChime) {
    optChime.addEventListener('change', () => {
      updateStatusDisplay();
      stopPlayback();
    });
  }

  // Initialize
  syncFormBuilderOptions();
  applyPreset('BANK_STANDARD');
  updateStatusDisplay();
}
