// Import CSS for Vite bundling
import '../css/seo-home.css';
import '../css/style.css';

// Import all interactive logic
import './seo-main-lite.js';
import './seo-accordion.js';
import './seo-nav.js';
import './seo-screenshots.js';
import './seo-hero-lightbox.js';
import './seo-video-carousel.js';
import './payment-modal.js';
import { initVoiceSimulator } from './voice-simulator.js';
import { initBankDirectory } from './bank-directory.js';
import { initLiveSync } from './live-sync.js';

function boot() {
  initVoiceSimulator();
  initBankDirectory();
  initLiveSync();
  console.log('AutoBank Web Landing Page & 65+ Bank Hub Initialized.');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot);
} else {
  boot();
}
