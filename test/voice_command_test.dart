import 'package:flutter_test/flutter_test.dart';
import 'package:sightassist/models/voice_command.dart';

void main() {
  group('VoiceCommand Multilingual Intent Parsing Tests', () {
    test('English commands map correctly', () {
      expect(VoiceCommand.parse('Describe surroundings').intent, CommandIntent.describeSurroundings);
      expect(VoiceCommand.parse('Please read this text').intent, CommandIntent.readText);
      expect(VoiceCommand.parse('Identify this medicine').intent, CommandIntent.identifyMedicine);
      expect(VoiceCommand.parse('Recognize currency').intent, CommandIntent.recognizeCurrency);
      expect(VoiceCommand.parse('Detect obstacles ahead').intent, CommandIntent.detectHazards);
      expect(VoiceCommand.parse('Stop speech').intent, CommandIntent.stopSpeech);
      expect(VoiceCommand.parse('Repeat again').intent, CommandIntent.repeatResult);
    });

    test('Hindi commands map correctly', () {
      expect(VoiceCommand.parse('आसपास क्या है बताओ').intent, CommandIntent.describeSurroundings);
      expect(VoiceCommand.parse('यह टेक्स्ट पढ़ो').intent, CommandIntent.readText);
      expect(VoiceCommand.parse('दवाई पहचानो').intent, CommandIntent.identifyMedicine);
      expect(VoiceCommand.parse('कितने पैसे हैं').intent, CommandIntent.recognizeCurrency);
      expect(VoiceCommand.parse('खतरा या बाधा ढूंढो').intent, CommandIntent.detectHazards);
    });

    test('Kannada commands map correctly', () {
      expect(VoiceCommand.parse('ಸುತ್ತಮುತ್ತ ಏನಿದೆ').intent, CommandIntent.describeSurroundings);
      expect(VoiceCommand.parse('ಪಠ್ಯವನ್ನು ಓದು').intent, CommandIntent.readText);
      expect(VoiceCommand.parse('ಔಷಧಿ ಗುರುತಿಸಿ').intent, CommandIntent.identifyMedicine);
      expect(VoiceCommand.parse('ಹಣ ಎಷ್ಟಿದೆ').intent, CommandIntent.recognizeCurrency);
      expect(VoiceCommand.parse('ಅಡೆತಡೆಗಳನ್ನು ಹುಡುಕಿ').intent, CommandIntent.detectHazards);
    });

    test('Telugu commands map correctly', () {
      expect(VoiceCommand.parse('పరిసరాలు ఎలా ఉన్నాయి').intent, CommandIntent.describeSurroundings);
      expect(VoiceCommand.parse('ఈ టెక్స్ట్ చదువు').intent, CommandIntent.readText);
      expect(VoiceCommand.parse('మందులను గుర్తించండి').intent, CommandIntent.identifyMedicine);
      expect(VoiceCommand.parse('కరెన్సీ ఎంత ఉంది').intent, CommandIntent.recognizeCurrency);
      expect(VoiceCommand.parse('అడ్డంకులను గుర్తించు').intent, CommandIntent.detectHazards);
    });
  });
}
