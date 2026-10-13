import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BASE_URL = 'https://appbaochuyentien.com/';
const images = [
  'assets/images/favicon.png',
  'assets/images/dots-shape.svg',
  'assets/images/hero-bg.png',
  'assets/images/play-store/app-icon-nav.webp',
  'assets/images/play-store/app-icon.png',
  'assets/images/play-store/app-icon-lg.webp',
  'assets/images/play-store/hero-main.png',
  'assets/images/play-store/feature-stats-sm.webp',
  'assets/images/play-store/feature-stats.webp',
  'assets/images/play-store/feature-stats-sm.png',
  'assets/images/play-store/feature-stats.png'
];

for (let i = 1; i <= 8; i++) {
  const num = String(i).padStart(2, '0');
  images.push(
    `assets/images/play-store/screenshot-${num}-sm.webp`,
    `assets/images/play-store/screenshot-${num}-sm.png`,
    `assets/images/play-store/screenshot-${num}.webp`,
    `assets/images/play-store/screenshot-${num}.png`
  );
}

async function download() {
  for (const relPath of images) {
    const targetPath = path.join(__dirname, relPath);
    const dir = path.dirname(targetPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const url = BASE_URL + relPath;
    try {
      console.log(`Downloading ${url}...`);
      const res = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        }
      });
      if (!res.ok) {
        console.warn(`Failed ${url}: status ${res.status}`);
        continue;
      }
      const buffer = await res.arrayBuffer();
      fs.writeFileSync(targetPath, Buffer.from(buffer));
      console.log(`Saved ${targetPath} (${buffer.byteLength} bytes)`);
    } catch (err) {
      console.error(`Error downloading ${url}:`, err.message);
    }
  }
}

download();
