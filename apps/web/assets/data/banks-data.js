export const BANK_CATEGORIES = {
  ALL: 'all',
  COMMERCIAL: 'commercial',
  NEOBANK: 'neobank',
  EWALLET: 'ewallet',
  BUSINESS: 'business'
};

export const BANKS_DATA = [
  // --- NGÂN HÀNG THƯƠNG MẠI ---
  {
    id: 'vcb',
    name: 'Vietcombank',
    app: 'VCB Digibank',
    code: 'VCB',
    pkg: 'com.VCB',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VCB.png',
    guide: 'Vào VCB Digibank → Cài đặt → Cài đặt thông báo → Bật Nhận tin biến động số dư qua thông báo OTT.'
  },
  {
    id: 'tcb',
    name: 'Techcombank',
    app: 'Techcombank Mobile',
    code: 'TCB',
    pkg: 'vn.com.techcombank.bb.app',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/TCB.png',
    guide: 'Mở Techcombank Mobile → Cài đặt bảo mật & thông báo → Bật Thông báo biến động số dư.'
  },
  {
    id: 'mb',
    name: 'MBBank',
    app: 'MB Bank',
    code: 'MB',
    pkg: 'com.mbmobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/MB.png',
    guide: 'Mở MBBank → Tiện ích → Thông báo biến động số dư → Kích hoạt nhận tin nhắn OTT qua ứng dụng.'
  },
  {
    id: 'bidv',
    name: 'BIDV',
    app: 'Smart Banking',
    code: 'BIDV',
    pkg: 'com.vnpay.bidv',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/BIDV.png',
    guide: 'Vào SmartBanking → Cài đặt → Đăng ký OTT biến động số dư → Bật thông báo tức thời.'
  },
  {
    id: 'icb',
    name: 'VietinBank',
    app: 'VietinBank iPay',
    code: 'ICB',
    pkg: 'com.vietinbank.ipay',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/ICB.png',
    guide: 'Mở VietinBank iPay → Cài đặt → Nhận biến động số dư qua tin nhắn OTT.'
  },
  {
    id: 'acb',
    name: 'ACB',
    app: 'ACB ONE',
    code: 'ACB',
    pkg: 'mobile.acb.com.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/ACB.png',
    guide: 'Mở ACB ONE → Cài đặt chung → Quản lý thông báo → Bật Nhận thông báo giao dịch.'
  },
  {
    id: 'vpb',
    name: 'VPBank',
    app: 'VPBank NEO',
    code: 'VPB',
    pkg: 'com.vnpay.vpbankonline',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VPB.png',
    guide: 'Vào VPBank NEO → Cài đặt → Thông báo biến động số dư → Bật nhận thông báo.'
  },
  {
    id: 'stb',
    name: 'Sacombank',
    app: 'Sacombank Pay',
    code: 'STB',
    pkg: 'com.sacombank.pay',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/STB.png',
    guide: 'Mở Sacombank Pay → Cài đặt tài khoản → Kích hoạt thông báo giao dịch chuyển/nhận tiền.'
  },
  {
    id: 'hdb',
    name: 'HDBank',
    app: 'HDBank Mobile',
    code: 'HDB',
    pkg: 'com.vnpay.hdbank',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/HDB.png',
    guide: 'Mở HDBank → Cài đặt → Thông báo OTT số dư tài khoản → Bật hiển thị biểu ngữ.'
  },
  {
    id: 'vba',
    name: 'Agribank',
    app: 'Agribank Plus',
    code: 'VBA',
    pkg: 'com.vnpay.agribank',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VBA.png',
    guide: 'Mở Agribank Plus → Dịch vụ thông báo → Đăng ký tin nhắn OTT thông báo biến động số dư.'
  },
  {
    id: 'scb',
    name: 'SCB',
    app: 'SCB Mobile Banking',
    code: 'SCB',
    pkg: 'com.vnpay.scb',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SCB.png',
    guide: 'Cài đặt → Thông báo số dư qua ứng dụng.'
  },
  {
    id: 'pvcb',
    name: 'PVcomBank',
    app: 'PVcomBank Mobile',
    code: 'PVCB',
    pkg: 'com.pvcombank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/PVCB.png',
    guide: 'Bật thông báo push OTT trong mục Cài đặt thông báo tài khoản.'
  },
  {
    id: 'bab',
    name: 'Bắc Á Bank',
    app: 'BAC A BANK Mobile',
    code: 'BAB',
    pkg: 'com.baca.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/BAB.png',
    guide: 'Vào Tiện ích → Đăng ký nhận biến động số dư qua ứng dụng.'
  },
  {
    id: 'ocb',
    name: 'OCB',
    app: 'OCB OMNI',
    code: 'OCB',
    pkg: 'com.ocb.omni',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/OCB.png',
    guide: 'Mở OCB OMNI → Cài đặt tài khoản → Thông báo số dư OTT.'
  },
  {
    id: 'shb',
    name: 'SHB',
    app: 'SHB Mobile',
    code: 'SHB',
    pkg: 'vn.shb.mbanking',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SHB.png',
    guide: 'Cài đặt → Đăng ký biến động số dư qua tin nhắn ứng dụng.'
  },
  {
    id: 'seab',
    name: 'SeABank',
    app: 'SeAMobile',
    code: 'SEAB',
    pkg: 'vn.com.seabank.mb1',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SEAB.png',
    guide: 'Vào SeAMobile → Cài đặt bảo mật & thông báo → Bật OTT giao dịch.'
  },
  {
    id: 'tpb',
    name: 'TPBank',
    app: 'TPBank Mobile',
    code: 'TPB',
    pkg: 'com.tpb.mb.gprsandroid',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/TPB.png',
    guide: 'Vào TPBank Mobile → Cài đặt → Cài đặt thông báo → Bật Biến động số dư tài khoản.'
  },
  {
    id: 'nab',
    name: 'Nam Á Bank',
    app: 'OpenSky Nam A Bank',
    code: 'NAB',
    pkg: 'namabank.opensky',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/NAB.png',
    guide: 'Mở OpenSky → Cài đặt thông báo → Bật OTT.'
  },
  {
    id: 'lpb',
    name: 'LP Bank',
    app: 'LPBank Mobile',
    code: 'LPB',
    pkg: 'com.lienvietpostbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/LPB.png',
    guide: 'Cài đặt → Thông báo biến động số dư → Kích hoạt nhận qua App.'
  },
  {
    id: 'vib',
    name: 'VIB',
    app: 'MyVIB',
    code: 'VIB',
    pkg: 'com.vib.myvib',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VIB.png',
    guide: 'Vào MyVIB → Cài đặt → Cài đặt thông báo → Chọn nhận thông báo giao dịch qua ứng dụng.'
  },
  {
    id: 'eib',
    name: 'Eximbank',
    app: 'Eximbank EDigi',
    code: 'EIB',
    pkg: 'com.eximbank.edigi',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/EIB.png',
    guide: 'Vào EDigi → Cài đặt thông báo → Bật OTT biến động số dư.'
  },
  {
    id: 'msb',
    name: 'MSB mBank',
    app: 'MSB mBank',
    code: 'MSB',
    pkg: 'com.msb.mbanking',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/MSB.png',
    guide: 'Cài đặt → Đăng ký nhận biến động số dư qua ứng dụng MSB.'
  },
  {
    id: 'uob',
    name: 'UOB Vietnam',
    app: 'UOB TMRW Vietnam',
    code: 'UOB',
    pkg: 'com.uob.mighty.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/UOB.png',
    guide: 'Vào UOB TMRW → Settings → Notifications → Bật Transaction alerts.'
  },
  {
    id: 'cimb',
    name: 'CIMB Bank',
    app: 'OCTO by CIMB',
    code: 'CIMB',
    pkg: 'com.cimb.octovn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/CIMB.png',
    guide: 'Cài đặt ứng dụng → Bật Push Notification cho các giao dịch nạp/rút.'
  },
  {
    id: 'hlb',
    name: 'Hong Leong Bank',
    app: 'HLB Connect VN',
    code: 'HLBVN',
    pkg: 'com.hlb.connect.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/HLBVN.png',
    guide: 'Settings → Notification preferences → Bật Transaction Notification.'
  },
  {
    id: 'pbvn',
    name: 'Public Bank',
    app: 'Public Bank Mobile',
    code: 'PBVN',
    pkg: 'com.publicbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/PBVN.png',
    guide: 'Kích hoạt thông báo giao dịch trong mục Quản lý thông báo.'
  },
  {
    id: 'scvn',
    name: 'Standard Chartered',
    app: 'SC Mobile Vietnam',
    code: 'SCVN',
    pkg: 'com.sc.scmobile.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SCVN.png',
    guide: 'Cài đặt → Bật thông báo đẩy (Push alerts) khi có giao dịch tài khoản.'
  },
  {
    id: 'hsbc',
    name: 'HSBC',
    app: 'HSBC Vietnam',
    code: 'HSBC',
    pkg: 'vn.hsbc.hsbcvietnam',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/HSBC.png',
    guide: 'Profile → Communication preferences → Bật Push notifications.'
  },
  {
    id: 'wvn',
    name: 'Woori Bank',
    app: 'Woori WON Vietnam',
    code: 'WVN',
    pkg: 'com.woori.won.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/WVN.png',
    guide: 'Vào Cài đặt → Đăng ký dịch vụ biến động số dư qua ứng dụng.'
  },
  {
    id: 'ibk',
    name: 'IBK Bank',
    app: 'i-ONE Bank Global',
    code: 'IBK',
    pkg: 'com.ibk.ione.global',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/IBK.png',
    guide: 'Cài đặt thông báo tài khoản qua Push Notification.'
  },
  {
    id: 'kbank',
    name: 'KASIKORNBANK',
    app: 'K PLUS Vietnam',
    code: 'KBANK',
    pkg: 'com.kasikornbank.kplus.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/KBANK.png',
    guide: 'Vào Cài đặt tài khoản → Bật thông báo biến động số dư tức thời.'
  },
  {
    id: 'klb',
    name: 'Kiên Long Bank',
    app: 'KienlongBank Plus',
    code: 'KLB',
    pkg: 'com.kienlongbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/KLB.png',
    guide: 'Mở KienlongBank Plus → Cài đặt → Bật OTT biến động số dư.'
  },
  {
    id: 'sgicb',
    name: 'Saigonbank',
    app: 'Saigonbank Smart Banking',
    code: 'SGICB',
    pkg: 'com.saigonbank.smartbanking',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SGICB.png',
    guide: 'Bật thông báo giao dịch trong mục Quản lý tài khoản.'
  },
  {
    id: 'vab',
    name: 'Việt Á Bank',
    app: 'VietABank EzMobile',
    code: 'VAB',
    pkg: 'com.vietabank.ezmobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VAB.png',
    guide: 'Cài đặt → Nhận thông báo giao dịch qua ứng dụng.'
  },
  {
    id: 'ncb',
    name: 'NCB',
    app: 'NCB iziMobile',
    code: 'NCB',
    pkg: 'com.ncb.izimobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/NCB.png',
    guide: 'Vào iziMobile → Cài đặt → Đăng ký OTT thông báo biến động số dư.'
  },
  {
    id: 'pgb',
    name: 'PGBank',
    app: 'PGBank Mobile',
    code: 'PGB',
    pkg: 'com.pgbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/PGB.png',
    guide: 'Bật nhận thông báo push cho giao dịch chuyển tiền đến.'
  },
  {
    id: 'ocean',
    name: 'OceanBank',
    app: 'Easy OceanBank Mobile',
    code: 'OceanBank',
    pkg: 'com.oceanbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.haitrieu.com/wp-content/uploads/2022/02/Icon-OceanBank.png',
    guide: 'Cài đặt → Đăng ký nhận thông báo OTT.'
  },
  {
    id: 'coop',
    name: 'Co-opBank',
    app: 'Co-opBank Mobile Banking',
    code: 'COOPBANK',
    pkg: 'com.coopbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/COOPBANK.png',
    guide: 'Vào Cài đặt thông báo → Bật tin nhắn giao dịch qua ứng dụng.'
  },
  {
    id: 'bidc',
    name: 'BIDC',
    app: 'BIDC Mobile Banking',
    code: 'BIDC',
    pkg: 'com.bidc.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/BIDV.png',
    guide: 'Cài đặt tài khoản → Kích hoạt thông báo push.'
  },
  {
    id: 'bvb',
    name: 'Bảo Việt Bank',
    app: 'Baoviet Smart',
    code: 'BVB',
    pkg: 'com.baoviet.smart',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/BVB.png',
    guide: 'Mở Baoviet Smart → Cài đặt → Nhận biến động số dư qua OTT.'
  },
  {
    id: 'abb',
    name: 'ABBank',
    app: 'AB Ditizen',
    code: 'ABB',
    pkg: 'com.abbank.ditizen',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/ABB.png',
    guide: 'Vào AB Ditizen → Cài đặt → Bật thông báo biến động số dư tức thời.'
  },
  {
    id: 'ivb',
    name: 'Indovina Bank',
    app: 'IVB Mobile Banking',
    code: 'IVB',
    pkg: 'com.ivb.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/IVB.png',
    guide: 'Cài đặt → Thông báo OTT tài khoản thanh toán.'
  },
  {
    id: 'gpb',
    name: 'GPBank',
    app: 'GPBank Mobile',
    code: 'GPB',
    pkg: 'com.gpbank.mobile',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/GPB.png',
    guide: 'Cài đặt → Bật thông báo giao dịch số dư.'
  },
  {
    id: 'vietbank',
    name: 'Vietbank',
    app: 'Vietbank Digital',
    code: 'VIETBANK',
    pkg: 'com.vietbank.digital',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/VIETBANK.png',
    guide: 'Cài đặt tài khoản → Bật thông báo OTT biến động số dư.'
  },
  {
    id: 'shbvn',
    name: 'Shinhan Bank',
    app: 'Shinhan SOL Vietnam',
    code: 'SHBVN',
    pkg: 'com.shinhan.sol.vn',
    category: BANK_CATEGORIES.COMMERCIAL,
    logo: 'https://cdn.vietqr.io/img/SHBVN.png',
    guide: 'Cài đặt → Thông báo tài khoản → Kích hoạt Push Notification.'
  },

  // --- NGÂN HÀNG SỐ & NEOBANK ---
  {
    id: 'cake',
    name: 'Cake by VPBank',
    app: 'Cake Bank',
    code: 'CAKE',
    pkg: 'xyz.be.cake',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/CAKE.png',
    guide: 'Mở Cake → Avatar cá nhân → Cài đặt thông báo → Bật Biến động số dư tài khoản.'
  },
  {
    id: 'lio',
    name: 'Lio Bank',
    app: 'Liobank by OCB',
    code: 'LIO',
    pkg: 'vn.liobank.app',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/OCB.png',
    guide: 'Mở Liobank → Cài đặt bảo mật & thông báo → Bật Push thông báo tiền vào.'
  },
  {
    id: 'tnex',
    name: 'TNEX',
    app: 'TNEX - Ngân hàng số thế hệ mới',
    code: 'TNEX',
    pkg: 'vn.tnex.consumer',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.haitrieu.com/wp-content/uploads/2022/10/Logo-TNEX.png',
    guide: 'Vào TNEX → Cài đặt → Thông báo giao dịch tài khoản Energy/CASA.'
  },
  {
    id: 'timo',
    name: 'Timo',
    app: 'Timo Digital Bank',
    code: 'TIMO',
    pkg: 'com.timo.digitalbank',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/TIMO.png',
    guide: 'Vào Timo → Cài đặt ứng dụng → Quản lý thông báo → Bật Thông báo chuyển tiền đến.'
  },
  {
    id: 'vikki',
    name: 'Vikki',
    app: 'Vikki Digital Bank',
    code: 'VIKKI',
    pkg: 'vn.vikki.bank',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/Vikki.png',
    guide: 'Mở Vikki → Cài đặt → Bật thông báo đẩy cho tất cả giao dịch nạp tiền.'
  },
  {
    id: 'vcbneo',
    name: 'VCBNeo',
    app: 'VCB Neo Digital',
    code: 'VCBNEO',
    pkg: 'com.vcb.neo',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/VCB.png',
    guide: 'Bật thông báo OTT thông báo số dư tức thời trong Cài đặt.'
  },
  {
    id: 'mbv',
    name: 'MBV Bank',
    app: 'MBV Digital Banking',
    code: 'MBV',
    pkg: 'com.mbv.digital',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/MBV.png',
    guide: 'Mở MBV Bank → Cài đặt → Bật thông báo số dư OTT.'
  },
  {
    id: 'mbveasy',
    name: 'MBV Easy',
    app: 'MBV Easy App',
    code: 'MBVEASY',
    pkg: 'com.mbv.easy',
    category: BANK_CATEGORIES.NEOBANK,
    logo: 'https://cdn.vietqr.io/img/MBV.png',
    guide: 'Cài đặt → Thông báo giao dịch số dư trực tuyến.'
  },

  // --- VÍ ĐIỆN TỬ ---
  {
    id: 'momo',
    name: 'MoMo',
    app: 'Ví MoMo',
    code: 'MOMO',
    pkg: 'com.mservice.momotransfer',
    category: BANK_CATEGORIES.EWALLET,
    logo: 'https://cdn.vietqr.io/img/momo.png',
    guide: 'Mở MoMo → Tôi → Cài đặt thông báo → Bật Nhận tiền chuyển đến & biến động tài khoản.'
  },
  {
    id: 'zalopay',
    name: 'ZaloPay',
    app: 'Ví ZaloPay',
    code: 'ZALOPAY',
    pkg: 'vn.com.vng.zalopay',
    category: BANK_CATEGORIES.EWALLET,
    logo: 'https://cdn.haitrieu.com/wp-content/uploads/2022/10/Logo-ZaloPay-Square.png',
    guide: 'Vào ZaloPay → Cá nhân → Cài đặt thông báo → Bật thông báo giao dịch thành công.'
  },
  {
    id: 'shopeepay',
    name: 'ShopeePay',
    app: 'Ví ShopeePay',
    code: 'SHOPEEPAY',
    pkg: 'com.airpay',
    category: BANK_CATEGORIES.EWALLET,
    logo: 'https://cdn.haitrieu.com/wp-content/uploads/2022/10/Logo-ShopeePay-V.png',
    guide: 'Mở ShopeePay → Cài đặt → Thông báo biến động số dư ví.'
  },
  {
    id: 'viettelmoney',
    name: 'Viettel Money',
    app: 'Viettel Money',
    code: 'VIETTELMONEY',
    pkg: 'com.bplus.vtpay',
    category: BANK_CATEGORIES.EWALLET,
    logo: 'https://cdn.vietqr.io/img/VIETTELMONEY.png',
    guide: 'Vào Viettel Money → Cá nhân → Cài đặt thông báo → Bật thông báo nhận tiền.'
  },
  {
    id: 'vnptmoney',
    name: 'VNPT Money',
    app: 'VNPT Money',
    code: 'VNPTMONEY',
    pkg: 'vn.com.vnpt.money',
    category: BANK_CATEGORIES.EWALLET,
    logo: 'https://cdn.vietqr.io/img/VNPTMONEY.png',
    guide: 'Mở VNPT Money → Cài đặt thông báo → Bật biến động số dư ví/Mobile Money.'
  },

  // --- ỨNG DỤNG DOANH NGHIỆP ---
  {
    id: 'vib_biz',
    name: 'VIB Business',
    app: 'VIB Business Mobile',
    code: 'VIB',
    pkg: 'com.vib.corporate',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/VIB.png',
    guide: 'Đăng nhập VIB Business → Cài đặt tài khoản công ty → Bật thông báo báo có tài khoản doanh nghiệp.'
  },
  {
    id: 'acb_biz',
    name: 'ACB One Biz',
    app: 'ACB One Biz',
    code: 'ACB',
    pkg: 'mobile.acb.com.vn.biz',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/ACB.png',
    guide: 'Vào ACB One Biz → Quản lý thông báo người duyệt/kế toán → Kích hoạt nhận thông báo push tức thì.'
  },
  {
    id: 'ab_ditizen_biz',
    name: 'AB Ditizen Biz',
    app: 'AB Ditizen Business',
    code: 'ABB',
    pkg: 'com.abbank.ditizen.biz',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/ABB.png',
    guide: 'Cài đặt → Thông báo biến động số dư tài khoản doanh nghiệp.'
  },
  {
    id: 'vcb_digibiz',
    name: 'VCB DigiBiz',
    app: 'VCB DigiBiz',
    code: 'VCB',
    pkg: 'com.VCB.DigiBiz',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/VCB.png',
    guide: 'Vào VCB DigiBiz → Cài đặt → Cài đặt thông báo → Bật Tin OTT báo có tiền vào.'
  },
  {
    id: 'bidv_ibank',
    name: 'BIDV iBank',
    app: 'BIDV iBank Mobile',
    code: 'BIDV',
    pkg: 'com.vnpay.bidvibms',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/BIDV.png',
    guide: 'Mở BIDV iBank → Cài đặt tiện ích → Bật thông báo tức thời cho giao dịch ghi có.'
  },
  {
    id: 'tcb_biz',
    name: 'Techcombank Business',
    app: 'Techcombank Business Mobile',
    code: 'TCB',
    pkg: 'vn.com.techcombank.business',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/TCB.png',
    guide: 'Mở TCB Business → Cài đặt người dùng → Kích hoạt thông báo tiền vào tài khoản công ty.'
  },
  {
    id: 'biz_mb',
    name: 'BIZ MBBank',
    app: 'BIZ MBBank Mobile',
    code: 'MB',
    pkg: 'com.mb.corporate',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/MB.png',
    guide: 'Vào BIZ MBBank → Quản lý thông báo → Bật thông báo OTT biến động số dư tài khoản doanh nghiệp.'
  },
  {
    id: 'lpb_biz',
    name: 'LPBank Biz',
    app: 'LPBank Biz Mobile',
    code: 'LPB',
    pkg: 'com.lienvietpostbank.biz',
    category: BANK_CATEGORIES.BUSINESS,
    logo: 'https://cdn.vietqr.io/img/LPB.png',
    guide: 'Vào LPBank Biz → Cài đặt bảo mật & thông báo → Bật thông báo giao dịch tiền đến.'
  }
];
