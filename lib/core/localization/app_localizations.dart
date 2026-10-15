enum AppLanguage {
  english('en', 'English', 'en-IN', 'en-US'),
  hindi('hi', 'हिन्दी (Hindi)', 'hi-IN', 'hi-IN'),
  kannada('kn', 'ಕನ್ನಡ (Kannada)', 'kn-IN', 'kn-IN'),
  telugu('te', 'తెలుగు (Telugu)', 'te-IN', 'te-IN');

  final String code;
  final String displayName;
  final String ttsLocale;
  final String sttLocale;

  const AppLanguage(this.code, this.displayName, this.ttsLocale, this.sttLocale);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'SightAssist',
      'appTagline': 'AI Eyes for the Visually Impaired',
      'welcomeVoice': 'Welcome to SightAssist. Speak a command or tap the screen.',
      'btnSurroundings': 'Describe Surroundings',
      'btnReadText': 'Read Text',
      'btnMedicine': 'Identify Medicine',
      'btnCurrency': 'Recognize Currency',
      'btnHazards': 'Detect Obstacles',
      'tapToSpeak': 'Tap to Speak Command',
      'listening': 'Listening... Speak your command now.',
      'analyzing': 'Analyzing visual information. Please hold still.',
      'cameraReady': 'Camera ready. Double tap anywhere to capture.',
      'imageCaptured': 'Image captured. Processing...',
      'resultTitle': 'Analysis Result',
      'replayAudio': 'Replay Speech',
      'retake': 'Take Another Picture',
      'backToHome': 'Back to Home',
      'settingsTitle': 'Settings & Accessibility',
      'languageSetting': 'Preferred Language',
      'speechRate': 'Speech Speed',
      'speechPitch': 'Speech Pitch',
      'apiKeySetting': 'Gemini Vision API Key',
      'saveSettings': 'Save Settings',
      'repositionCamera': 'Image is not clear. Please hold the phone steadily and try again.',
      'noTextFound': 'No readable text was detected in the frame.',
      'medicineNotice': 'Medicine detection active. Never consume medications without human verification if unsure.',
      'currencyPrompt': 'Hold the Indian currency note flat in front of the lens.',
      'obstacleSafe': 'Path appears clear directly ahead.',
    },
    'hi': {
      'appName': 'साइटअसिस्ट (SightAssist)',
      'appTagline': 'दृष्टिबाधितों के लिए एआई आंखें',
      'welcomeVoice': 'साइटअसिस्ट में आपका स्वागत है। कोई भी कमांड बोलें या स्क्रीन छुएं।',
      'btnSurroundings': 'आसपास क्या है बताएं',
      'btnReadText': 'टेक्स्ट पढ़ें',
      'btnMedicine': 'दवाई पहचानें',
      'btnCurrency': 'रुपये / नोट पहचानें',
      'btnHazards': 'रुकावटें या खतरे खोजें',
      'tapToSpeak': 'बोलने के लिए माइक दबाएं',
      'listening': 'सुन रहे हैं... अब अपनी कमांड बोलें।',
      'analyzing': 'चित्र का विश्लेषण हो रहा है। कृपया स्थिर रहें।',
      'cameraReady': 'कैमरा तैयार है। फोटो खींचने के लिए दो बार टैप करें।',
      'imageCaptured': 'फोटो ले ली गई है। प्रक्रिया जारी है...',
      'resultTitle': 'विश्लेषण का परिणाम',
      'replayAudio': 'दोबारा सुनें',
      'retake': 'दोबारा फोटो लें',
      'backToHome': 'होम पर वापस जाएं',
      'settingsTitle': 'सेटिंग्स और सुलभता',
      'languageSetting': 'पसंदीदा भाषा',
      'speechRate': 'बोलने की गति',
      'speechPitch': 'आवाज की पिच',
      'apiKeySetting': 'जेमिनी विजन एपीआई कुंजी',
      'saveSettings': 'सेटिंग्स सहेजें',
      'repositionCamera': 'फोटो साफ नहीं है। कृपया फोन को स्थिर रखें और दोबारा प्रयास करें।',
      'noTextFound': 'कैमरे के सामने कोई पठनीय टेक्स्ट नहीं मिला।',
      'medicineNotice': 'दवा की जानकारी जांची जा रही है। पुष्टि किए बिना कोई भी दवा न लें।',
      'currencyPrompt': 'कृपया भारतीय नोट को कैमरे के सामने सीधा रखें।',
      'obstacleSafe': 'सामने का रास्ता साफ प्रतीत होता है।',
    },
    'kn': {
      'appName': 'ಸೈಟ್‌ಅಸಿಸ್ಟ್ (SightAssist)',
      'appTagline': 'ದೃಷ್ಟಿಹೀನರಿಗೆ ಎಐ ಕಣ್ಣುಗಳು',
      'welcomeVoice': 'ಸೈಟ್‌ಅಸಿಸ್ಟ್‌ಗೆ ಸುಸ್ವಾಗತ. ಯಾವುದೇ ಆದೇಶವನ್ನು ಮಾತನಾಡಿ ಅಥವಾ ಪರದೆಯನ್ನು ಮುಟ್ಟಿ.',
      'btnSurroundings': 'ಸುತ್ತಮುತ್ತಲಿನ ವಿವರಣೆ',
      'btnReadText': 'ಪಠ್ಯವನ್ನು ಓದಿ',
      'btnMedicine': 'ಔಷಧಿ ಗುರುತಿಸಿ',
      'btnCurrency': 'ಹಣ / ನೋಟು ಗುರುತಿಸಿ',
      'btnHazards': 'ಅಡೆತಡೆಗಳನ್ನು ಪತ್ತೆಹಚ್ಚಿ',
      'tapToSpeak': 'ಆಜ್ಞೆ ನೀಡಲು ಮೈಕ್ ಒತ್ತಿ',
      'listening': 'ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇವೆ... ಈಗ ಮಾತನಾಡಿ.',
      'analyzing': 'ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ. ದಯವಿಟ್ಟು ನಿಶ್ಚಲವಾಗಿ ಹಿಡಿದುಕೊಳ್ಳಿ.',
      'cameraReady': 'ಕ್ಯಾಮರಾ ಸಿದ್ಧವಾಗಿದೆ. ಫೋಟೋ ತೆಗೆಯಲು ಎರಡು ಬಾರಿ ಸ್ಪರ್ಶಿಸಿ.',
      'imageCaptured': 'ಚಿತ್ರ ಸೆರೆಹಿಡಿಯಲಾಗಿದೆ. ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲಾಗುತ್ತಿದೆ...',
      'resultTitle': 'ಫಲಿತಾಂಶ',
      'replayAudio': 'ಪುನಃ ಆಲಿಸಿ',
      'retake': 'ಮತ್ತೊಮ್ಮೆ ಚಿತ್ರ ತೆಗೆದುಕೊಳ್ಳಿ',
      'backToHome': 'ಮುಖಪುಟಕ್ಕೆ ಹಿಂತಿರುಗಿ',
      'settingsTitle': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಮತ್ತು ಪ್ರವೇಶಿಸುವಿಕೆ',
      'languageSetting': 'ಆದ್ಯತೆಯ ಭಾಷೆ',
      'speechRate': 'ಮಾತಿನ ವೇಗ',
      'speechPitch': 'ಧ್ವನಿಯ ತೀವ್ರತೆ',
      'apiKeySetting': 'ಜೆಮಿನಿ ಎಪಿಐ ಕೀಲಿ',
      'saveSettings': 'ಉಳಿಸಿ',
      'repositionCamera': 'ಚಿತ್ರ ಸ್ಪಷ್ಟವಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಫೋನ್ ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಪುನಃ ಪ್ರಯತ್ನಿಸಿ.',
      'noTextFound': 'ಯಾವುದೇ ಸ್ಪಷ್ಟ ಪಠ್ಯ ಕಂಡುಬಂದಿಲ್ಲ.',
      'medicineNotice': 'ಔಷಧಿಯ ವಿವರ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ. ಖಚಿತಪಡಿಸಿಕೊಳ್ಳದೆ ಸೇವಿಸಬೇಡಿ.',
      'currencyPrompt': 'ಭಾರತೀಯ ನೋಟನ್ನು ನೇರವಾಗಿ ಕ್ಯಾಮೆರಾ ಮುಂದೆ ಹಿಡಿಯಿರಿ.',
      'obstacleSafe': 'ಮುಂದೆ ಯಾವುದೇ ಅಡೆತಡೆಗಳು ಕಾಣಿಸುತ್ತಿಲ್ಲ.',
    },
    'te': {
      'appName': 'సైట్‌అసిస్ట్ (SightAssist)',
      'appTagline': 'దృష్టి లోపం ఉన్నవారి కోసం కృత్రిమ మేధ నేత్రాలు',
      'welcomeVoice': 'సైట్‌అసిస్ట్‌కు స్వాగతం. ఏదైనా ఆదేశం ఇవ్వండి లేదా స్క్రీన్‌పై తాకండి.',
      'btnSurroundings': 'పరిసరాలను వివరించండి',
      'btnReadText': 'టెక్స్ట్ చదవండి',
      'btnMedicine': 'మందులను గుర్తించండి',
      'btnCurrency': 'కరెన్సీ నోట్లను గుర్తించండి',
      'btnHazards': 'అడ్డంకులను గుర్తించండి',
      'tapToSpeak': 'మాట్లాడటానికి మైక్ నొక్కండి',
      'listening': 'వింటున్నాము... మీ ఆదేశాన్ని చెప్పండి.',
      'analyzing': 'విశ్లేషిస్తున్నాము. దయచేసి ఫోన్‌ను కదపకుండా పట్టుకోండి.',
      'cameraReady': 'కెమెరా సిద్ధంగా ఉంది. ఫోటో తీయడానికి రెండుసార్లు నొక్కండి.',
      'imageCaptured': 'ఫోటో తీయబడింది. ప్రాసెస్ అవుతోంది...',
      'resultTitle': 'విశ్లేషణ ఫలితం',
      'replayAudio': 'మళ్ళీ వినండి',
      'retake': 'మరొక ఫోటో తీయండి',
      'backToHome': 'హోమ్‌కు తిరిగి వెళ్ళండి',
      'settingsTitle': 'సెట్టింగ్స్ మరియు ప్రాప్యత',
      'languageSetting': 'ప్రాధాన్య భాష',
      'speechRate': 'మాటల వేగం',
      'speechPitch': 'వాయిస్ పిచ్',
      'apiKeySetting': 'జెమిని ఏపీఐ కీ',
      'saveSettings': 'సేవ్ చేయండి',
      'repositionCamera': 'చిత్రం స్పష్టంగా లేదు. దయచేసి కెమెరాను సరిగ్గా ఉంచి మళ్ళీ ప్రయత్నించండి.',
      'noTextFound': 'ఎటువంటి స్పష్టమైన టెక్స్ట్ కనిపించలేదు.',
      'medicineNotice': 'మందుల వివరాలను ధృవీకరించుకోకుండా తీసుకోవద్దు.',
      'currencyPrompt': 'భారతీయ కరెన్సీ నోటును కెమెరా ముందు సూటిగా ఉంచండి.',
      'obstacleSafe': 'ముందు ఎటువంటి అడ్డంకులు లేవు.',
    },
  };

  String translate(String key) {
    final langCode = language.code;
    return _localizedValues[langCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
