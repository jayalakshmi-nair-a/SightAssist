import 'package:flutter/services.dart';

class SoundEffects {
  static Future<void> playClick() async {
    SystemSound.play(SystemSoundType.click);
  }

  static Future<void> playAlert() async {
    SystemSound.play(SystemSoundType.alert);
  }
}
