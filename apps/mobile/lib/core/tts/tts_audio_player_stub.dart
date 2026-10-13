class PlatformAudioPlayer {
  static Future<bool> playAudio(
    String url, {
    String? text,
    double? speechRate,
    double? volume,
    double? pitch,
    void Function()? onFinished,
  }) async {
    return false;
  }

  static void stop() {}
}
