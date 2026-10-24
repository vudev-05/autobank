import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/notification_listener/presentation/notification_service.dart';
import 'youtube_player_stub.dart'
    if (dart.library.html) 'youtube_player_web.dart';

class YouTubePlayerDialog extends StatelessWidget {
  final String videoUrl;
  final String title;

  const YouTubePlayerDialog({
    super.key,
    required this.videoUrl,
    this.title = 'Video Hướng Dẫn Sử Dụng AutoBank',
  });

  static void show(BuildContext context, {required String videoUrl, String? title}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => YouTubePlayerDialog(
        videoUrl: videoUrl,
        title: title ?? 'Video Hướng Dẫn Sử Dụng AutoBank',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF334155)),

            // Video Player Body
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: kIsWeb
                    ? buildYouTubeIFrame(videoUrl)
                    : InkWell(
                        onTap: () {
                          NotificationService.openUrl(videoUrl);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: Icon(Icons.smart_display_rounded, color: Colors.white24, size: 80),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Bấm để phát video trên YouTube',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Mở trực tiếp trên ứng dụng YouTube hoặc trình duyệt',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF38BDF8)),
                    label: const Text('Sao chép link video', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: videoUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép link video YouTube vào bộ nhớ tạm!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
