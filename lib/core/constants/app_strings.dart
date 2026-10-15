class AppStrings {
  static const String appName = 'SightAssist';
  static const String appTagline = 'AI Eyes for the Visually Impaired';

  // Core Module Titles
  static const String describeSurroundings = 'Describe Surroundings';
  static const String readText = 'Read Text';
  static const String identifyMedicine = 'Identify Medicine';
  static const String recognizeCurrency = 'Recognize Currency';
  static const String detectHazards = 'Detect Obstacles';

  // Subtitles & Descriptions
  static const String describeSurroundingsDesc = 'Understand objects, people & scene context';
  static const String readTextDesc = 'Books, signs, notices, bus numbers & labels';
  static const String identifyMedicineDesc = 'Medicine name, dosage & expiry date';
  static const String recognizeCurrencyDesc = 'Indian Rupee notes & coin denominations';
  static const String detectHazardsDesc = 'Directional alerts for stairs, curbs & vehicles';

  // Voice Interaction Prompts
  static const String tapToSpeak = 'Tap microphone or speak command';
  static const String listening = 'Listening to your command...';
  static const String analyzing = 'Analyzing visual input, please hold steady...';
  static const String cameraReady = 'Camera ready. Double tap screen to capture.';
  static const String imageCaptured = 'Image captured. Processing with AI.';

  // Error Messages
  static const String cameraError = 'Unable to access camera. Please enable camera permission in Settings.';
  static const String micError = 'Microphone permission denied. Tap buttons to operate.';
  static const String networkError = 'Internet connection unavailable. Please check your mobile data or Wi-Fi.';
  static const String noTextDetected = 'No clear text was detected. Try holding the camera closer and ensure adequate lighting.';
  static const String lowConfidenceCurrency = 'Could not clearly recognize the currency note. Please flatten the note and hold steady.';
  static const String medicineWarning = 'Warning: Expiry date or dosage details are partially unclear. Please verify with a trusted person before consumption.';
}
