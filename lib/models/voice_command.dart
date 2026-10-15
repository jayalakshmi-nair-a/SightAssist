enum CommandIntent {
  describeSurroundings,
  readText,
  identifyMedicine,
  recognizeCurrency,
  detectHazards,
  stopSpeech,
  repeatResult,
  openSettings,
  help,
  unknown
}

class VoiceCommand {
  final CommandIntent intent;
  final String rawText;
  final double confidence;
  final String? matchedKeyword;

  VoiceCommand({
    required this.intent,
    required this.rawText,
    this.confidence = 1.0,
    this.matchedKeyword,
  });

  /// Natural Language Intent Parser supporting English, Hindi, Kannada, and Telugu
  static VoiceCommand parse(String input) {
    final text = input.trim().toLowerCase();

    // 1. Describe Surroundings
    if (_matches(text, [
      'describe', 'surrounding', 'around', 'what is in front', 'look', 'scene', 'view',
      'आसपास', 'क्या है', 'सामने', 'चारों तरफ', 'माहौल', 'दृश्य',
      'ಸುತ್ತಮುತ್ತ', 'ಏನಿದೆ', 'ನೋಡು', 'ಮುಂದೆ',
      'పరిసరాలు', 'ఏముంది', 'చుట్టూ', 'ముందు'
    ])) {
      return VoiceCommand(intent: CommandIntent.describeSurroundings, rawText: input);
    }

    // 2. Read Text / OCR
    if (_matches(text, [
      'read', 'text', 'book', 'paper', 'board', 'sign', 'letter', 'document', 'bus number',
      'पढ़ो', 'पढ़िए', 'टेक्स्ट', 'अक्षर', 'किताब', 'बोर्ड', 'कागज',
      'ಓದು', 'ಪಠ್ಯ', 'ಪುಸ್ತಕ', 'ಬೋರ್ಡ್',
      'చదువు', 'టెక్స్ట్', 'పుస్తకం', 'బోర్డు', 'కాగితం'
    ])) {
      return VoiceCommand(intent: CommandIntent.readText, rawText: input);
    }

    // 3. Identify Medicine
    if (_matches(text, [
      'medicine', 'tablet', 'pill', 'capsule', 'syrup', 'expiry', 'dose', 'dosage', 'prescription',
      'दवा', 'दवाई', 'गोली', 'एक्सपायरी', 'खुराक',
      'ಔಷಧಿ', 'ಮಾತ್ರೆ', 'ಗುಳಿಗೆ', 'ಟ್ಯಾಬ್ಲೆಟ್',
      'మందు', 'మందులు', 'మాత్ర', 'టాబ్లెట్'
    ])) {
      return VoiceCommand(intent: CommandIntent.identifyMedicine, rawText: input);
    }

    // 4. Recognize Currency
    if (_matches(text, [
      'currency', 'money', 'rupee', 'cash', 'note', 'coin', 'paisa', 'how much money',
      'पैसे', 'रुपये', 'नोट', 'कैश', 'सिक्का', 'कितने पैसे',
      'ಹಣ', 'ರೂಪಾಯಿ', 'ನೋಟು', 'ನಾಣ್ಯ', 'ಎಷ್ಟು ಹಣ',
      'డబ్బు', 'రూపాయలు', 'నోటు', 'కరెన్సీ', 'ఎంత డబ్బు'
    ])) {
      return VoiceCommand(intent: CommandIntent.recognizeCurrency, rawText: input);
    }

    // 5. Detect Hazards / Obstacles
    if (_matches(text, [
      'obstacle', 'hazard', 'danger', 'stairs', 'curb', 'step', 'vehicle', 'wall', 'clear', 'safe',
      'बाधा', 'खतरा', 'रुकावट', 'सीढ़ियां', 'गाड़ी', 'दीवार',
      'ಅಡೆತಡೆ', 'ಅಪಾಯ', 'ಮೆಟ್ಟಿಲು', 'ವಾಹನ',
      'అడ్డంకి', 'అడ్డంకులు', 'అడ్డంకులను', 'ప్రమాదం', 'మెట్లు', 'వాహనం'
    ])) {
      return VoiceCommand(intent: CommandIntent.detectHazards, rawText: input);
    }

    // 6. Stop / Pause Speech
    if (_matches(text, ['stop', 'quiet', 'silence', 'pause', 'रुक', 'रुको', 'शांति', 'ನಿಲ್ಲಿಸು', 'ఆగు', 'నిలుపు'])) {
      return VoiceCommand(intent: CommandIntent.stopSpeech, rawText: input);
    }

    // 7. Repeat / Replay
    if (_matches(text, ['repeat', 'again', 'replay', 'दोबारा', 'फिर से', 'ಮತ್ತೊಮ್ಮೆ', 'మళ్ళీ'])) {
      return VoiceCommand(intent: CommandIntent.repeatResult, rawText: input);
    }

    // 8. Settings
    if (_matches(text, ['settings', 'config', 'option', 'भाषा', 'सेटिंग', 'ಭಾಷೆ', 'సెట్టింగ్స్'])) {
      return VoiceCommand(intent: CommandIntent.openSettings, rawText: input);
    }

    // 9. Help
    if (_matches(text, ['help', 'what can you do', 'guide', 'मदद', 'सहायता', 'ಸಹಾಯ', 'సహాయం'])) {
      return VoiceCommand(intent: CommandIntent.help, rawText: input);
    }

    return VoiceCommand(intent: CommandIntent.unknown, rawText: input);
  }

  static bool _matches(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw.toLowerCase())) return true;
    }
    return false;
  }
}
