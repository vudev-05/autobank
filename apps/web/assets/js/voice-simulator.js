/**
 * Interactive Audio Voice Simulator for AutoBank "Loa Báo Tiền"
 * 7 distinctive Vietnamese voice presets powered by Neural Speech Studio MP3s & Web Audio Chimes.
 * Guaranteed strictly ONE voice playing at any moment with atomic token locking. Zero overlaps.
 */

export const VOICE_PRESETS = [
  {
    id: 'chi-google',
    name: 'Giọng đọc chuẩn',
    desc: 'Giọng đọc tiếng Việt (vi-VN) chuẩn quốc dân, tròn vành rõ chữ',
    gender: 'female',
    accent: 'Chuẩn (vi-VN)',
    chimeType: 'classic',
    previewBadge: 'Mặc định',
    spokenText: (amt, bank) => `Đã nhận ${amt} từ ${bank}.`,
  },
];

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

let isVoiceSimulatorInitialized = false;

export function initVoiceSimulator() {
  if (isVoiceSimulatorInitialized) return;

  const playBtn = document.getElementById('ab-voice-play-btn');
  const bankSelect = document.getElementById('ab-voice-bank-select');
  const voiceSelect = document.getElementById('ab-voice-preset-select');
  const amountInput = document.getElementById('ab-voice-amount-input');
  const quickAmountBtns = document.querySelectorAll('[data-voice-amount]');
  const voicePills = document.querySelectorAll('[data-voice-preset]');
  const voiceWave = document.getElementById('ab-voice-wave');
  const voiceStatus = document.getElementById('ab-voice-status');

  if (!playBtn) return;
  isVoiceSimulatorInitialized = true;

  let currentVoiceId = 'chi-google';
  let currentPlaybackToken = 0;
  let activeAudio = null;
  let speechDelayTimer = null;
  let safetyTimeout = null;
  let activeChimeNodes = [];

  const audioCache = new Map();

  function stopAllChimes() {
    activeChimeNodes.forEach(node => {
      try { node.stop(); } catch (_) {}
      try { node.disconnect(); } catch (_) {}
    });
    activeChimeNodes = [];
  }

  // Master Stop: Instantly kills all chimes, active audio, speech synthesis, and queued timers
  function hardStopAllAudio() {
    // Invalidate any pending token so queued callbacks/timers are permanently neutralized
    currentPlaybackToken++;

    if (speechDelayTimer) {
      clearTimeout(speechDelayTimer);
      speechDelayTimer = null;
    }
    if (safetyTimeout) {
      clearTimeout(safetyTimeout);
      safetyTimeout = null;
    }

    stopAllChimes();

    // Pause and reset active audio
    if (activeAudio) {
      try {
        activeAudio.pause();
        activeAudio.currentTime = 0;
        activeAudio.onended = null;
        activeAudio.onerror = null;
      } catch (_) {}
      activeAudio = null;
    }

    // Stop every audio element currently in cache
    audioCache.forEach(audio => {
      try {
        if (!audio.paused) {
          audio.pause();
          audio.currentTime = 0;
        }
        audio.onended = null;
        audio.onerror = null;
      } catch (_) {}
    });

    // Cancel speech synthesis
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel();
      } catch (_) {}
    }

    // Reset UI indicators
    if (voiceWave) voiceWave.classList.remove('is-playing');
    voicePills.forEach(p => p.classList.remove('is-speaking'));
    if (playBtn) {
      playBtn.classList.remove('is-playing');
      playBtn.innerHTML = `
        <span style="display: inline-flex; align-items: center; gap: 8px;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>
          Bấm nghe thử thông báo nhận tiền
        </span>
      `;
    }
  }

  // Web Audio Chime Synthesizer
  function playChime(type = 'classic') {
    try {
      stopAllChimes();
      const ctx = getAudioContext();
      if (!ctx) return;

      if (type === 'broadcast') {
        const notes = [523.25, 659.25, 783.99];
        notes.forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          const t = ctx.currentTime + idx * 0.08;
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, t);
          gain.gain.setValueAtTime(0, t);
          gain.gain.linearRampToValueAtTime(0.28, t + 0.015);
          gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(t);
          osc.stop(t + 0.22);
          activeChimeNodes.push(osc);
        });
        return;
      }

      if (type === 'digital') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(987.77, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1400, ctx.currentTime + 0.10);
        gain.gain.setValueAtTime(0.20, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.18);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.18);
        activeChimeNodes.push(osc);
        return;
      }

      if (type === 'deep') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(392, ctx.currentTime);
        gain.gain.setValueAtTime(0.35, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.22);
        activeChimeNodes.push(osc);
        return;
      }

      if (type === 'soft') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(698.46, ctx.currentTime);
        gain.gain.setValueAtTime(0, ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.22, ctx.currentTime + 0.03);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.22);
        activeChimeNodes.push(osc);
        return;
      }

      if (type === 'punchy') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(659.25, ctx.currentTime);
        gain.gain.setValueAtTime(0.32, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.20);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.20);
        activeChimeNodes.push(osc);
        return;
      }

      // Default crisp ting-ting
      const freq1 = type === 'cheerful' ? 1046.50 : 880;
      const freq2 = type === 'cheerful' ? 1567.98 : 1320;

      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(freq1, ctx.currentTime);
      gain1.gain.setValueAtTime(0, ctx.currentTime);
      gain1.gain.linearRampToValueAtTime(0.28, ctx.currentTime + 0.02);
      gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.20);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start();
      osc1.stop(ctx.currentTime + 0.20);
      activeChimeNodes.push(osc1);

      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(freq2, ctx.currentTime + 0.06);
      gain2.gain.setValueAtTime(0, ctx.currentTime + 0.06);
      gain2.gain.linearRampToValueAtTime(0.30, ctx.currentTime + 0.09);
      gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.22);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(ctx.currentTime + 0.06);
      osc2.stop(ctx.currentTime + 0.22);
      activeChimeNodes.push(osc2);
    } catch (_) {}
  }

  function numberToVietnameseWords(num) {
    const n = parseInt(String(num).replace(/\D/g, ''), 10);
    if (isNaN(n) || n === 0) return 'hai trăm năm mươi nghìn đồng';
    if (n === 50000) return 'năm mươi nghìn đồng';
    if (n === 250000) return 'hai trăm năm mươi nghìn đồng';
    if (n === 500000) return 'năm trăm nghìn đồng';
    if (n === 1500000) return 'một triệu năm trăm nghìn đồng';
    if (n === 5000000) return 'năm triệu đồng';
    if (n >= 1000000) {
      const millions = (n / 1000000).toLocaleString('vi-VN');
      return `${millions} triệu đồng`;
    }
    if (n >= 1000) {
      const thousands = (n / 1000).toLocaleString('vi-VN');
      return `${thousands} nghìn đồng`;
    }
    return `${n.toLocaleString('vi-VN')} đồng`;
  }

  function getAmountKey(amountVal) {
    const n = parseInt(String(amountVal).replace(/\D/g, ''), 10);
    if (n === 50000) return '50k';
    if (n === 250000) return '250k';
    if (n === 500000) return '500k';
    if (n === 1500000) return '1500k';
    if (n === 5000000) return '5000k';
    return '250k';
  }

  function getAudioUrl(presetId, amountKey) {
    const filePrefix = (presetId === 'chi-google') ? 'nu-bac' : presetId;
    return `assets/audio/${filePrefix}-${amountKey}.mp3`;
  }

  function getCachedAudio(url) {
    let aud = audioCache.get(url);
    if (!aud) {
      aud = new Audio(url);
      aud.preload = 'auto';
      audioCache.set(url, aud);
    }
    return aud;
  }

  // Fallback for rare environments where mp3 files cannot be loaded
  function fallbackSpeechSynthesis(text, preset, playbackToken) {
    if (playbackToken !== currentPlaybackToken) return;
    if (!('speechSynthesis' in window)) {
      hardStopAllAudio();
      return;
    }

    try {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'vi-VN';
      utterance.pitch = 1.0;
      utterance.rate = 0.90;

      // 100% Giọng Chị Google Chuẩn Quốc Dân (vi-VN)
      const voices = window.speechSynthesis.getVoices();
      const googleVoice = voices.find(v => 
        (v.name.toLowerCase().includes('google') && (v.lang.includes('vi') || v.lang.includes('VN'))) ||
        (v.name.toLowerCase().includes('vietnamese') && v.name.toLowerCase().includes('google'))
      ) || voices.find(v => v.lang.includes('vi') || v.lang.includes('VN'));
      if (googleVoice) utterance.voice = googleVoice;

      utterance.onend = () => {
        if (playbackToken !== currentPlaybackToken) return;
        hardStopAllAudio();
        if (voiceStatus) {
          voiceStatus.innerHTML = 'Đã phát xong thông báo nhận tiền. Bấm để nghe lại!';
        }
      };

      utterance.onerror = () => {
        if (playbackToken !== currentPlaybackToken) return;
        hardStopAllAudio();
      };

      window.speechSynthesis.speak(utterance);
    } catch (_) {
      hardStopAllAudio();
    }
  }

  // Core Playback Function: Plays ONE voice preset strictly and safely
  function startVoicePlayback(voiceId) {
    const preset = VOICE_PRESETS.find(v => v.id === voiceId) || VOICE_PRESETS[0];
    const isPlayingCurrent = (activeAudio && !activeAudio.paused) || (playBtn && playBtn.classList.contains('is-playing'));
    const isSameVoice = (voiceId === currentVoiceId);

    // If already playing this exact voice, tapping it acts as Pause/Stop
    if (isPlayingCurrent && isSameVoice) {
      hardStopAllAudio();
      if (voiceStatus) {
        voiceStatus.innerHTML = `Đã tạm dừng thông báo. Bấm để nghe lại!`;
      }
      return;
    }

    // Step 1: Kill ALL existing audio, synthesis, and timers immediately
    hardStopAllAudio();

    // Step 2: Establish new unique playback token
    const playbackToken = ++currentPlaybackToken;
    currentVoiceId = voiceId;

    // Unlock AudioContext from user click gesture
    getAudioContext();

    // Update preset UI cards
    if (voiceSelect) voiceSelect.value = voiceId;
    voicePills.forEach(p => {
      const match = p.getAttribute('data-voice-preset') === voiceId;
      p.classList.toggle('active', match);
      p.classList.toggle('is-speaking', match);
    });

    // Determine amount and phrase
    const bankName = (bankSelect && bankSelect.value) ? bankSelect.value : 'Techcombank';
    const amountVal = (amountInput && amountInput.value) ? amountInput.value : '250000';
    const amountKey = getAmountKey(amountVal);
    const spokenAmount = numberToVietnameseWords(amountVal);
    const fullSpeechText = preset.spokenText(spokenAmount, bankName);

    // Update Status Bar and Play Button UI
    if (voiceStatus) {
      voiceStatus.innerHTML = `<strong>Đang phát thông báo:</strong> "${fullSpeechText}"`;
    }
    if (voiceWave) voiceWave.classList.add('is-playing');
    if (playBtn) {
      playBtn.classList.add('is-playing');
      playBtn.innerHTML = `
        <span style="display: inline-flex; align-items: center; gap: 8px;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
          Đang phát thông báo...
        </span>
      `;
    }

    // Play signature chime sound
    playChime(preset.chimeType);

    // Safety watchdog: Max 10 seconds timeout
    safetyTimeout = setTimeout(() => {
      if (playbackToken === currentPlaybackToken) {
        hardStopAllAudio();
      }
    }, 10000);

    // Sequence smoothly: Ding chime for 180ms, then begin studio MP3 voice
    speechDelayTimer = setTimeout(() => {
      if (playbackToken !== currentPlaybackToken) return;
      speechDelayTimer = null;

      // Intelligent Audio Route:
      // - Standard presets (50k, 250k, 500k, 1.5M, 5M with Techcombank) use instant studio MP3s (0ms delay)
      // - Custom amounts or other banks call dynamic TTS API (/api/tts) to generate speech on the fly
      const host = window.location.hostname || 'localhost';
      const audioUrl = `http://${host}:3000/tts?text=${encodeURIComponent(fullSpeechText)}`;
      const googleFallbackUrl = `https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=${encodeURIComponent(fullSpeechText)}`;

      const audio = getCachedAudio(audioUrl);

      activeAudio = audio;
      audio.currentTime = 0;
      audio.volume = 1.0;

      let hasEnded = false;
      audio.onended = () => {
        if (hasEnded || playbackToken !== currentPlaybackToken) return;
        hasEnded = true;
        hardStopAllAudio();
        if (voiceStatus) {
          voiceStatus.innerHTML = 'Đã phát xong thông báo nhận tiền. Bấm để nghe lại!';
        }
      };

      let hasErrored = false;
      const handleError = () => {
        if (hasErrored || playbackToken !== currentPlaybackToken) return;
        hasErrored = true;
        try {
          audio.pause();
          audio.currentTime = 0;
          audio.onended = null;
          audio.onerror = null;
        } catch (_) {}
        // Phát trực tiếp từ Google Translate TTS nếu API backend bận
        const fallbackAudio = getCachedAudio(googleFallbackUrl);
        activeAudio = fallbackAudio;
        fallbackAudio.currentTime = 0;
        fallbackAudio.onended = () => {
          if (playbackToken !== currentPlaybackToken) return;
          hardStopAllAudio();
          if (voiceStatus) {
            voiceStatus.innerHTML = 'Đã phát xong thông báo nhận tiền. Bấm để nghe lại!';
          }
        };
        fallbackAudio.onerror = () => {
          hardStopAllAudio();
        };
        fallbackAudio.play().catch(() => {
          hardStopAllAudio();
        });
      };

      audio.onerror = handleError;

      const playPromise = audio.play();
      if (playPromise !== undefined) {
        playPromise.catch(() => {
          handleError();
        });
      }
    }, 190);
  }

  // Pre-cache voice samples in background
  function preloadAllAudio() {
    try {
      const amountVal = (amountInput && amountInput.value) ? amountInput.value : '250000';
      const amountKey = getAmountKey(amountVal);
      VOICE_PRESETS.forEach(v => {
        const url = getAudioUrl(v.id, amountKey);
        getCachedAudio(url);
      });
    } catch (_) {}
  }

  // Event Listeners: Clicking ANY voice preset card immediately reads THAT voice!
  voicePills.forEach(pill => {
    pill.addEventListener('click', (e) => {
      e.preventDefault();
      const vid = pill.getAttribute('data-voice-preset');
      startVoicePlayback(vid);
    });
  });

  if (voiceSelect) {
    voiceSelect.addEventListener('change', (e) => {
      startVoicePlayback(e.target.value);
    });
  }

  // Big Play Button
  playBtn.addEventListener('click', (e) => {
    e.preventDefault();
    startVoicePlayback(currentVoiceId);
  });

  // Quick Amount Pills
  quickAmountBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      quickAmountBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      if (amountInput) {
        amountInput.value = btn.getAttribute('data-voice-amount');
      }
      // If currently playing, smoothly replay with new amount
      const isPlaying = (activeAudio && !activeAudio.paused) || playBtn.classList.contains('is-playing');
      if (isPlaying) {
        startVoicePlayback(currentVoiceId);
      } else {
        preloadAllAudio();
      }
    });
  });

  if (amountInput) {
    amountInput.addEventListener('change', () => {
      preloadAllAudio();
    });
  }

  if (bankSelect) {
    bankSelect.addEventListener('change', () => {
      const isPlaying = (activeAudio && !activeAudio.paused) || playBtn.classList.contains('is-playing');
      if (isPlaying) {
        startVoicePlayback(currentVoiceId);
      }
    });
  }

  // Preload initial set of audio
  preloadAllAudio();
}
