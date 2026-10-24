import { Controller, Get, Post, Body, Param, Query, Res, HttpStatus, OnModuleInit, Logger } from '@nestjs/common';
import type { Response } from 'express';
import { MsEdgeTTS, OUTPUT_FORMAT } from 'msedge-tts';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { PrismaService } from '../prisma/prisma.service.js';

export interface VoicePresetMeta {
  id: string;
  name: string;
  gender: 'FEMALE' | 'MALE' | 'AI' | 'ANNOUNCER';
  region: string;
  desc: string;
  avatar: string;
  voice: string;
  defaultRate: string;
  defaultPitch: string;
  defaultVolume: string;
  isFree: boolean; // Chỉ giọng mặc định nu-bac là miễn phí cho gói dùng thử
  sampleSentence: string;
}

export const VOICES_CATALOG: VoicePresetMeta[] = [
  {
    id: 'chi-google',
    name: 'Giọng Chị Google Chuẩn Quốc Dân',
    gender: 'FEMALE',
    region: 'Toàn quốc',
    desc: 'Giọng đọc Chị Google tiếng Việt (vi-VN) chuẩn quốc dân 100%, to rõ, không vấp',
    avatar: '🗣️ Chị Google',
    voice: 'vi-VN-HoaiMyNeural',
    defaultRate: '+0%',
    defaultPitch: '+0Hz',
    defaultVolume: '+10%',
    isFree: true, // GIỌNG CHUẨN 100% CỦA HỆ THỐNG
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'nam-bac',
    name: 'Nam Bắc chuẩn (Hà Nội)',
    gender: 'MALE',
    region: 'Hà Nội',
    desc: 'Giọng nam Hà Nội trầm ấm, chững chạc, uy tín tài chính ngân hàng',
    avatar: '👨 Hà Nội',
    voice: 'vi-VN-NamMinhNeural',
    defaultRate: '-4%',
    defaultPitch: '-14Hz',
    defaultVolume: '+0%',
    isFree: true,
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'nu-bac',
    name: 'Nữ Bắc chuẩn (Hà Nội)',
    gender: 'FEMALE',
    region: 'Hà Nội',
    desc: 'Giọng phát thanh viên truyền cảm, ngọt ngào, phát âm chuẩn quốc gia',
    avatar: '👩 Hà Nội',
    voice: 'vi-VN-HoaiMyNeural',
    defaultRate: '+0%',
    defaultPitch: '+0Hz',
    defaultVolume: '+0%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'nu-nam',
    name: 'Nữ Nam Bộ (Sài Gòn)',
    gender: 'FEMALE',
    region: 'Sài Gòn',
    desc: 'Giọng nữ Sài Gòn dễ thương, nhanh nhẹn, thân thiện buôn bán',
    avatar: '👱‍♀️ Sài Gòn',
    voice: 'vi-VN-HoaiMyNeural',
    defaultRate: '+8%',
    defaultPitch: '+20Hz',
    defaultVolume: '+0%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'nu-hue',
    name: 'Nữ Miền Trung (Huế)',
    gender: 'FEMALE',
    region: 'Huế',
    desc: 'Giọng nữ Huế dịu dàng, thanh thoát, nhẹ nhàng Cố Đô',
    avatar: '🌸 Huế',
    voice: 'vi-VN-HoaiMyNeural',
    defaultRate: '-8%',
    defaultPitch: '-6Hz',
    defaultVolume: '+0%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'nam-nam',
    name: 'Nam Nam Bộ (Sài Gòn)',
    gender: 'MALE',
    region: 'Sài Gòn',
    desc: 'Giọng nam Sài Gòn hào sảng, năng động, dứt khoát thương nhân',
    avatar: '🧔 Sài Gòn',
    voice: 'vi-VN-NamMinhNeural',
    defaultRate: '+8%',
    defaultPitch: '+10Hz',
    defaultVolume: '+0%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'ai-speaker',
    name: 'AI Trợ Lý Ảo (Công Nghệ)',
    gender: 'AI',
    region: 'Smart Speaker',
    desc: 'Giọng AI số hóa công nghệ cao, sắc nét, hiện đại 4.0',
    avatar: '🤖 AI Bot',
    voice: 'vi-VN-HoaiMyNeural',
    defaultRate: '+18%',
    defaultPitch: '+30Hz',
    defaultVolume: '+0%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
  {
    id: 'sieu-thi',
    name: 'Loa Siêu Thị (Chống Ồn)',
    gender: 'ANNOUNCER',
    region: 'Quầy bán lẻ',
    desc: 'Giọng phát thanh âm vang quầy thu ngân, chống ồn cho chợ và tạp hóa',
    avatar: '📢 Loa quầy',
    voice: 'vi-VN-NamMinhNeural',
    defaultRate: '+2%',
    defaultPitch: '+4Hz',
    defaultVolume: '+10%',
    isFree: false, // VIP
    sampleSentence: 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
  },
];

// Khối thành phần cấu tạo nên Form đọc duy nhất
export const SENTENCE_BLOCKS = [
  { id: 'bell', name: 'Chuông báo Ting-Ting', sample: 'Ting!', isDefault: true },
  { id: 'prefix', name: 'Lời chào / Tiền tố', sample: 'Đã nhận', isDefault: true },
  { id: 'amount', name: 'Số tiền thanh toán', sample: '250.000 đồng', isDefault: true },
  { id: 'bank', name: 'Ngân hàng nhận', sample: 'từ Techcombank', isDefault: true },
  { id: 'shopOrOrder', name: 'Tên quán / Mã đơn', sample: 'đơn hàng D H 1 0 5 8', isDefault: false },
  { id: 'suffix', name: 'Lời cảm ơn / Hậu tố', sample: 'Cảm ơn quý khách!', isDefault: false },
];

export const SENTENCE_PRESETS = [
  {
    id: 'BANK_STANDARD',
    name: 'Chuẩn Ngân Hàng',
    icon: 'account_balance',
    desc: 'Chuông ting + Đã nhận + Số tiền + Ngân hàng',
    order: ['bell', 'prefix', 'amount', 'bank'],
    enabled: ['bell', 'prefix', 'amount', 'bank'],
  },
  {
    id: 'STORE_POLITE',
    name: 'Lịch Sự & Bán Hàng',
    icon: 'storefront',
    desc: 'Chuông ting + Tiền tố + Số tiền + Tên quán + Lời cảm ơn',
    order: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
    enabled: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
  },
  {
    id: 'FAST_RUSH',
    name: 'Siêu Nhanh (Giờ Cao Điểm)',
    icon: 'bolt',
    desc: 'Nhận + Số tiền (cực kỳ ngắn gọn, chống ùn tắc quầy)',
    order: ['prefix', 'amount'],
    enabled: ['prefix', 'amount'],
  },
  {
    id: 'FULL_RECONCILE',
    name: 'Đối Soát Chi Tiết',
    icon: 'receipt_long',
    desc: 'Đầy đủ chuông, số tiền, ngân hàng, mã đơn hàng',
    order: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder'],
    enabled: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder'],
  },
  {
    id: 'CUSTOM_BUILDER',
    name: 'Tùy Chỉnh Thứ Tự',
    icon: 'tune',
    desc: 'Tự do bật/tắt và kéo thả sắp xếp vị trí bất kỳ',
    order: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder', 'suffix'],
    enabled: ['bell', 'prefix', 'amount', 'bank'],
  },
];

// In-memory audio buffer cache
const audioCache = new Map<string, Buffer>();
const userVoiceConfigs = new Map<string, any>();
const tempDir = path.join(os.tmpdir(), 'autobank_tts_cache');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

@Controller(['api/tts', 'tts'])
export class TtsController implements OnModuleInit {
  private readonly logger = new Logger(TtsController.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    this.prewarmCache().catch((err) => {
      this.logger.warn(`TTS Prewarm warning: ${err?.message || err}`);
    });
  }

  /**
   * 1. Lấy danh mục giọng đọc chuẩn
   */
  @Get('voices')
  getVoices() {
    return {
      success: true,
      defaultVoiceId: 'chi-google',
      voices: VOICES_CATALOG,
    };
  }

  /**
   * 2. Lấy danh sách các Form đọc và khối thành phần sắp xếp được
   */
  @Get('templates')
  getTemplates() {
    return {
      success: true,
      blocks: SENTENCE_BLOCKS,
      presets: SENTENCE_PRESETS,
    };
  }

  /**
   * 3. Kiểm tra bản quyền tài khoản
   * Giọng Chị Google chuẩn quốc dân sẵn sàng 100% cho mọi tài khoản.
   */
  @Post('validate-license')
  async validateLicense(@Body() body: { email?: string; voiceId?: string }) {
    const { email, voiceId } = body;
    const requestedVoiceId = voiceId || 'chi-google';
    const voiceMeta = VOICES_CATALOG.find((v) => v.id === requestedVoiceId) || VOICES_CATALOG[0];

    // Giọng Chị Google và giọng mặc định luôn cho phép
    if (voiceMeta.isFree || requestedVoiceId === 'chi-google' || requestedVoiceId === 'nam-bac') {
      return {
        allowed: true,
        voiceId: requestedVoiceId,
        isTrial: false,
        message: 'Giọng Chị Google Chuẩn Quốc Dân sẵn sàng cho mọi tài khoản',
      };
    }

    return {
      allowed: true,
      voiceId: requestedVoiceId,
      isTrial: false,
      message: 'Giọng đọc đã được kích hoạt',
    };
  }

  /**
   * 4. Lưu cấu hình giọng đọc của người dùng vào SQL
   */
  @Post('user-config')
  async saveUserConfig(@Body() body: any) {
    const email = (body.email || '').trim().toLowerCase();
    let configData = {
      ...body,
      updatedAt: new Date().toISOString(),
    };

    if (email && email !== 'anonymous') {
      try {
        // Lấy cấu hình hiện tại để merge an toàn (không làm mất voice templates khi update sharePin hoặc ngược lại)
        let existingCfg: any = {};
        const rows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM app_device_users WHERE LOWER(email) = ? LIMIT 1`,
          email,
        );
        if (rows && rows[0]?.voiceSettingsJson) {
          try {
            existingCfg = JSON.parse(rows[0].voiceSettingsJson);
          } catch (_) {}
        }
        configData = {
          ...existingCfg,
          ...body,
          email,
          updatedAt: new Date().toISOString(),
        };
        const jsonStr = JSON.stringify(configData);

        // Lưu vào MySQL bảng app_device_users
        await this.prisma.$executeRawUnsafe(
          `UPDATE app_device_users SET voiceSettingsJson = ?, updatedAt = NOW() WHERE LOWER(email) = ?`,
          jsonStr,
          email,
        );

        // Lưu vào MySQL bảng users
        await this.prisma.$executeRawUnsafe(
          `UPDATE users SET voiceSettingsJson = ?, updatedAt = NOW() WHERE LOWER(email) = ?`,
          jsonStr,
          email,
        );
      } catch (err: any) {
        this.logger.error(`Error saving voiceSettingsJson to MySQL for ${email}: ${err.message}`);
      }
      userVoiceConfigs.set(email, configData);
    } else {
      userVoiceConfigs.set('anonymous', configData);
    }

    return {
      success: true,
      message: 'Đã lưu cấu hình giọng đọc và form câu đọc vào hệ thống SQL của tài khoản',
      data: configData,
    };
  }

  /**
   * 5. Lấy cấu hình giọng đọc của người dùng từ SQL
   */
  @Get('user-config/:email')
  async getUserConfig(@Param('email') emailParam: string) {
    return this.findUserConfig(emailParam);
  }

  @Get('user-config')
  async getUserConfigQuery(@Query('email') emailQuery: string) {
    return this.findUserConfig(emailQuery);
  }

  private async findUserConfig(emailInput: string) {
    const email = (emailInput || '').trim().toLowerCase();
    if (email && email !== 'anonymous') {
      try {
        // Query từ MySQL bảng app_device_users
        const rows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM app_device_users WHERE LOWER(email) = ? AND voiceSettingsJson IS NOT NULL LIMIT 1`,
          email,
        );

        if (rows && rows.length > 0 && rows[0].voiceSettingsJson) {
          const parsed = JSON.parse(rows[0].voiceSettingsJson);
          userVoiceConfigs.set(email, parsed);
          return {
            success: true,
            data: parsed,
          };
        }

        // Query từ MySQL bảng users
        const userRows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM users WHERE LOWER(email) = ? AND voiceSettingsJson IS NOT NULL LIMIT 1`,
          email,
        );
        if (userRows && userRows.length > 0 && userRows[0].voiceSettingsJson) {
          const parsed = JSON.parse(userRows[0].voiceSettingsJson);
          userVoiceConfigs.set(email, parsed);
          return {
            success: true,
            data: parsed,
          };
        }
      } catch (err: any) {
        this.logger.error(`Error loading voiceSettingsJson from MySQL for ${email}: ${err.message}`);
      }
    } else {
      // Khi không có email trong tham số, tự động lấy cấu hình đã lưu gần nhất của thiết bị trong MySQL
      try {
        const latestRows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM app_device_users WHERE voiceSettingsJson IS NOT NULL ORDER BY updatedAt DESC LIMIT 1`,
        );
        if (latestRows && latestRows.length > 0 && latestRows[0].voiceSettingsJson) {
          const parsed = JSON.parse(latestRows[0].voiceSettingsJson);
          return {
            success: true,
            data: parsed,
          };
        }
        const latestUserRows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM users WHERE voiceSettingsJson IS NOT NULL ORDER BY updatedAt DESC LIMIT 1`,
        );
        if (latestUserRows && latestUserRows.length > 0 && latestUserRows[0].voiceSettingsJson) {
          const parsed = JSON.parse(latestUserRows[0].voiceSettingsJson);
          return {
            success: true,
            data: parsed,
          };
        }
      } catch (_) {}
    }

    return {
      success: true,
      data: userVoiceConfigs.get(email) || userVoiceConfigs.get('anonymous') || {
        voiceId: 'chi-google',
        speechRate: 0.90,
        pitch: 1.0,
        volume: 1.0,
        templateId: 'BANK_STANDARD',
        blocksOrder: ['bell', 'prefix', 'amount', 'bank'],
        enabledBlocks: ['bell', 'prefix', 'amount', 'bank'],
      },
    };
  }

  private async generateBuffer(
    voiceId: string,
    text: string,
    customRate?: string,
    customPitch?: string,
    customVolume?: string,
  ): Promise<Buffer | null> {
    const cleanText = (text || '').trim();
    if (!cleanText) return null;

    const cfg = VOICES_CATALOG.find((v) => v.id === voiceId) || VOICES_CATALOG[0];

    // Chuẩn hóa định dạng rate, pitch, volume cho SSML
    const formatProsody = (val: string | undefined, defaultVal: string, unit: string) => {
      if (!val) return defaultVal;
      let v = val.trim();
      if (!v.endsWith(unit)) v = `${v}${unit}`;
      if (!v.startsWith('+') && !v.startsWith('-')) {
        const num = parseFloat(v);
        if (num >= 0) v = `+${v}`;
      }
      return v;
    };

    const rate = formatProsody(customRate, cfg.defaultRate, '%');
    const pitch = formatProsody(customPitch, cfg.defaultPitch, 'Hz');
    const volume = formatProsody(customVolume, cfg.defaultVolume, '%');

    const cacheKey = `${voiceId}::${rate}::${pitch}::${volume}::${cleanText}`;
    if (audioCache.has(cacheKey)) {
      return audioCache.get(cacheKey)!;
    }

    // 1. NẾU LÀ GIỌNG CHỊ GOOGLE: LUÔN LUÔN ƯU TIÊN 100% GOOGLE TRANSLATE CHÍNH GỐC
    if (voiceId === 'chi-google') {
      try {
        const googleTtsUrl = `https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=${encodeURIComponent(cleanText)}`;
        const googleRes = await fetch(googleTtsUrl, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://translate.google.com/',
          },
        });

        if (googleRes.ok) {
          const arrayBuf = await googleRes.arrayBuffer();
          const googleAudioBuffer = Buffer.from(arrayBuf);
          if (googleAudioBuffer && googleAudioBuffer.length > 500) {
            audioCache.set(cacheKey, googleAudioBuffer);
            return googleAudioBuffer;
          }
        }
      } catch (googleErr: any) {
        this.logger.warn(`Google Translate TTS fetch warning: ${googleErr?.message || googleErr}`);
      }
    }

    // 2. CÁC GIỌNG VÙNG MIỀN HOẶC KHI CÓ PROSODY TÙY CHỈNH (MsEdgeTTS)
    const hasCustomProsody =
      (customRate && customRate !== '+0%') ||
      (customPitch && customPitch !== '+0Hz' && customPitch !== '+0%');

    if (hasCustomProsody || voiceId !== 'chi-google') {
      try {
        const tts = new MsEdgeTTS();
        await tts.setMetadata(cfg.voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);

        const ssml = `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='vi-VN'>
          <voice name='${cfg.voice}'>
            <prosody rate='${rate}' pitch='${pitch}' volume='${volume}'>${cleanText}</prosody>
          </voice>
        </speak>`;

        const result = await (tts as any)._rawSSMLRequestToFile(tempDir, ssml);
        if (result && result.audioFilePath && fs.existsSync(result.audioFilePath)) {
          const audioBuffer = fs.readFileSync(result.audioFilePath);
          audioCache.set(cacheKey, audioBuffer);
          return audioBuffer;
        }
      } catch (err: any) {
        this.logger.warn(`EdgeTTS prosody fetch warning: ${err?.message || err}`);
      }
    }

    // Dự phòng qua MsEdgeTTS
    try {
      const tts = new MsEdgeTTS();
      await tts.setMetadata(cfg.voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);

      const ssml = `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='vi-VN'>
        <voice name='${cfg.voice}'>
          <prosody rate='${rate}' pitch='${pitch}' volume='${volume}'>${cleanText}</prosody>
        </voice>
      </speak>`;

      const result = await (tts as any)._rawSSMLRequestToFile(tempDir, ssml);
      if (result && result.audioFilePath && fs.existsSync(result.audioFilePath)) {
        const audioBuffer = fs.readFileSync(result.audioFilePath);
        audioCache.set(cacheKey, audioBuffer);
        return audioBuffer;
      }
    } catch (_) {}

    return null;
  }

  private async prewarmCache() {
    const defaultTexts = [
      'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
      'Đã nhận năm mươi nghìn đồng từ Vietcombank',
      'Đã nhận năm trăm nghìn đồng từ Timo',
    ];
    for (const v of VOICES_CATALOG) {
      for (const t of defaultTexts) {
        try {
          await this.generateBuffer(v.id, t);
        } catch (_) {}
      }
    }
    this.logger.log(`TTS prewarmed ${audioCache.size} voice samples successfully`);
  }

  /**
   * 6. Phát âm thanh Edge-TTS với đầy đủ tùy chỉnh tốc độ, cao giọng, âm lượng
   */
  @Get()
  async synthesize(
    @Query('voice') voiceId = 'nu-bac',
    @Query('text') text = 'Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank',
    @Query('rate') rate?: string,
    @Query('pitch') pitch?: string,
    @Query('volume') volume?: string,
    @Res() res?: Response,
  ) {
    const cleanText = (text || '').trim();
    if (!cleanText) {
      return res?.status(HttpStatus.BAD_REQUEST).json({ error: 'Text query parameter is required' });
    }

    const cfg = VOICES_CATALOG.find((v) => v.id === voiceId) || VOICES_CATALOG[0];
    const finalRate = rate || cfg.defaultRate;
    const finalPitch = pitch || cfg.defaultPitch;
    const finalVolume = volume || cfg.defaultVolume;

    const cacheKey = `${voiceId}::${finalRate}::${finalPitch}::${finalVolume}::${cleanText}`;

    if (audioCache.has(cacheKey)) {
      const cached = audioCache.get(cacheKey)!;
      res?.set({
        'Content-Type': 'audio/mpeg',
        'Content-Length': cached.length.toString(),
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Cache-Control': 'public, max-age=86400',
        'X-Cache': 'HIT',
      });
      return res?.send(cached);
    }

    try {
      const buffer = await this.generateBuffer(voiceId, cleanText, finalRate, finalPitch, finalVolume);
      if (buffer) {
        res?.set({
          'Content-Type': 'audio/mpeg',
          'Content-Length': buffer.length.toString(),
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
          'Cross-Origin-Resource-Policy': 'cross-origin',
          'Cache-Control': 'public, max-age=86400',
          'X-Cache': 'MISS',
        });
        return res?.send(buffer);
      } else {
        return res?.status(HttpStatus.INTERNAL_SERVER_ERROR).json({ error: 'Audio file generation failed' });
      }
    } catch (err: any) {
      this.logger.error(`Synthesis error: ${err.message}`);
      return res?.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'Synthesis failed',
        message: err.message,
      });
    }
  }
}

