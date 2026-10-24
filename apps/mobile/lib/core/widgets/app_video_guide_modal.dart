import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppVideoGuideModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final String videoUrl;
  final String? badgeText;
  final Color badgeColor;
  final String? prefKey; // Key lưu không hiển thị lại
  final bool showNeverShowAgainCheckbox;
  final String dismissButtonText;

  const AppVideoGuideModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    this.badgeText,
    this.badgeColor = const Color(0xFF0284C7),
    this.prefKey,
    this.showNeverShowAgainCheckbox = false,
    this.dismissButtonText = 'ĐÃ HIỂU & ĐÓNG',
  });

  /// Hiển thị trực tiếp Dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String videoUrl,
    String? badgeText,
    Color badgeColor = const Color(0xFF0284C7),
    String? prefKey,
    bool showNeverShowAgainCheckbox = false,
    String dismissButtonText = 'ĐÃ HIỂU & ĐÓNG',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppVideoGuideModal(
        title: title,
        subtitle: subtitle,
        videoUrl: videoUrl,
        badgeText: badgeText,
        badgeColor: badgeColor,
        prefKey: prefKey,
        showNeverShowAgainCheckbox: showNeverShowAgainCheckbox,
        dismissButtonText: dismissButtonText,
      ),
    );
  }

  /// Alias tiện lợi để gọi nhanh khi bấm nút icon video trên AppBar/Giao diện
  static Future<void> showDirect(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String videoUrl,
    String? badgeText,
    Color badgeColor = const Color(0xFF0284C7),
    String dismissButtonText = 'Đóng',
  }) {
    return show(
      context,
      title: title,
      subtitle: subtitle,
      videoUrl: videoUrl,
      badgeText: badgeText,
      badgeColor: badgeColor,
      showNeverShowAgainCheckbox: false,
      dismissButtonText: dismissButtonText,
    );
  }

  /// Tự động kiểm tra nếu người dùng chưa chọn "Không hiển thị lại" thì mới mở
  static Future<void> showIfNeeded(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String videoUrl,
    required String prefKey,
    String? badgeText,
    Color badgeColor = const Color(0xFF0284C7),
    bool showNeverShowAgainCheckbox = true,
    String dismissButtonText = 'Đóng',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(prefKey) ?? false;
      if (hasSeen) return;
      if (!context.mounted) return;
      await show(
        context,
        title: title,
        subtitle: subtitle,
        videoUrl: videoUrl,
        badgeText: badgeText,
        badgeColor: badgeColor,
        prefKey: prefKey,
        showNeverShowAgainCheckbox: showNeverShowAgainCheckbox,
        dismissButtonText: dismissButtonText,
      );
    } catch (_) {}
  }

  @override
  State<AppVideoGuideModal> createState() => _AppVideoGuideModalState();
}

class _AppVideoGuideModalState extends State<AppVideoGuideModal> {
  bool _dontShowAgain = false;
  WebViewController? _webViewController;

  /// Trích xuất YouTube Video ID từ mọi dạng link YouTube
  String extractYoutubeId(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return 'kYJqD9bZ_fQ';

    // 1. Dạng youtu.be/ID
    final regShort = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})');
    final matchShort = regShort.firstMatch(clean);
    if (matchShort != null) return matchShort.group(1)!;

    // 2. Dạng youtube.com/watch?v=ID
    final regWatch = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})');
    final matchWatch = regWatch.firstMatch(clean);
    if (matchWatch != null) return matchWatch.group(1)!;

    // 3. Dạng youtube.com/embed/ID hoặc /shorts/ID
    final regEmbed = RegExp(r'(?:embed|shorts)\/([a-zA-Z0-9_-]{11})');
    final matchEmbed = regEmbed.firstMatch(clean);
    if (matchEmbed != null) return matchEmbed.group(1)!;

    // Nếu người dùng chỉ nhập ID 11 ký tự
    if (clean.length == 11 && !clean.contains('/')) return clean;

    return 'kYJqD9bZ_fQ';
  }

  @override
  void initState() {
    super.initState();
    final videoId = extractYoutubeId(widget.videoUrl);

    if (!kIsWeb) {
      // Khởi tạo WebView nhúng YouTube mượt mà trên Android/iOS
      try {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {},
            ),
          )
          ..loadHtmlString(_buildYoutubeEmbedHtml(videoId));
        _webViewController = controller;
      } catch (e) {
        debugPrint('[AppVideoGuideModal] WebView init error: $e');
      }
    }
  }

  String _buildYoutubeEmbedHtml(String videoId) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { width: 100%; height: 100%; background-color: #000; overflow: hidden; display: flex; align-items: center; justify-content: center; }
            iframe { width: 100%; height: 100%; border: none; }
          </style>
        </head>
        <body>
          <iframe 
            src="https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
            allowfullscreen>
          </iframe>
        </body>
      </html>
    ''';
  }

  void _handleOpenInYoutubeApp(String videoId) async {
    final youtubeUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _handleClose() async {
    if (widget.prefKey != null && _dontShowAgain) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(widget.prefKey!, true);
      } catch (_) {}
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeId(widget.videoUrl);
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.play_circle_fill_rounded, color: widget.badgeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: widget.badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.badgeText!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: widget.badgeColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                      onPressed: _handleClose,
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 2. VIDEO PLAYER VIEW (HIỂN THỊ TRỰC TIẾP TRONG APP)
              Container(
                color: Colors.black,
                constraints: const BoxConstraints(maxHeight: 240),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Player (WebView trên Android/iOS)
                      if (!kIsWeb && _webViewController != null)
                        WebViewWidget(controller: _webViewController!)
                      else
                        // Web fallback với Thumbnail & Nút Play
                        GestureDetector(
                          onTap: () => _handleOpenInYoutubeApp(videoId),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: const Color(0xFF0F172A),
                                  child: const Center(
                                    child: Icon(Icons.ondemand_video_rounded, color: Colors.white54, size: 48),
                                  ),
                                ),
                              ),
                              Container(color: Colors.black.withValues(alpha: 0.35)),
                              Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.95),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // NÚT MỞ RA YOUTUBE APP GÓC TRÊN BÊN PHẢI PLAYER
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => _handleOpenInYoutubeApp(videoId),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Mở YouTube',
                                  style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. FOOTER & ACTIONS
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  children: [
                    // Checkbox Không hiển thị lại nữa (nếu có prefKey hoặc showNeverShowAgainCheckbox)
                    if (widget.prefKey != null || widget.showNeverShowAgainCheckbox) ...[
                      InkWell(
                        onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _dontShowAgain,
                                  onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
                                  activeColor: const Color(0xFF0284C7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Không hiển thị lại hướng dẫn này nữa',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // NÚT ĐÓNG TO RÕ DƯỚI PHẦN THÔNG BÁO
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleClose,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.dismissButtonText.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
