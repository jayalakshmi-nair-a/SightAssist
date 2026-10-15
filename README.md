# SIGHTASSIST – AI EYES FOR THE VISUALLY IMPAIRED

**SightAssist** is an AI-powered smartphone accessibility application built in Flutter & Dart. It empowers visually impaired and low-vision individuals to understand their surroundings and navigate daily activities independently through real-time audio guidance, multimodal computer vision, on-device OCR, and natural-language voice interactions.

---

## 🌟 Key Highlights

- 🗣️ **Voice-First Navigation**: Interact completely hands-free via natural voice commands.
- 👁️ **Multimodal Scene Understanding**: Powered by Google Gemini 1.5 Flash Vision for contextual, spatial awareness ("There is a person standing in front of you. A chair is on your right.").
- 📖 **Instant OCR Text Reader**: Google ML Kit OCR extracts and vocalizes printed text from books, documents, signboards, notices, medicine labels, and bus numbers.
- 💊 **Medicine Assistance**: Analyzes pharmaceutical packaging for brand names, active salts, dosage, and expiry dates with strict human-verification safeguards.
- 💵 **Indian Currency Recognition**: Identifies Indian Rupee banknotes (₹10, ₹20, ₹50, ₹100, ₹200, ₹500, ₹2000) and coins. Guides user to flatten or reposition folded notes.
- ⚠️ **Directional Hazard & Obstacle Alerts**: Urgent audio alerts for stairs, curbs, approaching vehicles, and walking obstacles.
- 🌐 **Multilingual Indian Support**: Full voice input (STT) and spoken output (TTS) in **English**, **Hindi (हिन्दी)**, **Kannada (ಕನ್ನಡ)**, and **Telugu (తెలుగు)**.
- ♿ **High-Contrast WCAG AAA UI**: Massive touch targets (≥72dp), pitch black backgrounds, electric yellow/cyan accents, and full screen-reader (TalkBack) accessibility.
- 🔒 **Privacy-First Architecture**: Camera captures are processed in-memory and immediately purged from local storage.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                          # Application entry point & MultiProvider dependency injection
├── config/
│   ├── app_config.dart                # Audio, camera, and timeout platform constants
│   └── env_config.dart                # Safe environment variables manager (.env loader)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # WCAG AAA high-contrast accessibility color palette
│   │   ├── app_keys.dart              # SharedPreferences and route names
│   │   └── app_strings.dart           # App string constants & voice prompts
│   ├── localization/
│   │   ├── app_localizations.dart     # Multilingual dictionaries (EN, HI, KN, TE)
│   │   └── language_manager.dart      # Reactive language state manager
│   ├── theme/
│   │   └── accessible_theme.dart      # High-contrast dark theme & oversized typography
│   └── utils/
│       ├── haptic_feedback_helper.dart# Tactile vibration patterns for blind users
│       ├── image_preprocessor.dart    # Contrast normalization, resizing, & OCR filtering
│       ├── permission_helper.dart     # Camera, microphone & hardware permissions
│       └── sound_effects.dart         # Audio cues and feedback chimes
├── models/
│   ├── currency_info.dart             # Indian currency model with reposition flags
│   ├── hazard_info.dart               # Directional hazard assessment & urgency levels
│   ├── medicine_info.dart             # Pharmaceutical details with unverified warnings
│   ├── ocr_result.dart                # Extracted text blocks & document classification
│   ├── scene_description.dart         # Spatial entities & directional scene summary
│   ├── user_settings.dart             # Accessibility, speech rate, pitch & volume preferences
│   └── voice_command.dart             # Multilingual natural language intent classifier
├── services/
│   ├── camera_service.dart            # Camera controller lifecycle & torch/flash toggle
│   ├── currency_service.dart          # OCR pattern matching + Gemini Vision verification
│   ├── firebase_service.dart          # Preferences sync & zero-image-retention enforcement
│   ├── gemini_service.dart            # Multimodal Gemini Vision API integration
│   ├── hazard_service.dart            # Directional collision warning & safety assessment
│   ├── medicine_service.dart          # Prescription & strip analysis with regex dates
│   ├── ocr_service.dart               # ML Kit Latin text recognition & preprocessing
│   ├── speech_service.dart            # Multilingual Speech-to-Text (STT) engine
│   └── tts_service.dart               # Text-to-Speech (TTS) queue and voice modulation
├── controllers/
│   └── sight_controller.dart          # Central orchestrator coordinating voice, camera & AI
├── screens/
│   ├── splash_screen.dart             # Accessible welcome announcement & animated branding
│   ├── onboarding_screen.dart         # Tactile audio guide explaining the 5 core modules
│   ├── home_screen.dart               # High-contrast dashboard with pulsating microphone
│   ├── camera_screen.dart             # Accessible viewfinder with double-tap full screen capture
│   ├── result_screen.dart             # High-legibility text display with instant speech replay
│   └── settings_screen.dart           # Multilingual selector, speech sliders & Gemini API key
└── widgets/
    ├── accessible_button.dart         # 72dp touch targets with haptic impact on tap
    ├── accessible_header.dart         # High-contrast navigation bar with back action
    ├── hazard_alert_banner.dart       # Urgent visual/tactile obstacle banner
    ├── high_contrast_card.dart        # Oversized dashboard cards with distinct color accents
    └── voice_waveform.dart            # Pulsating animated circular microphone control
```

---

## 🎙️ Voice Command Reference

| Action | English | Hindi (हिन्दी) | Kannada (ಕನ್ನಡ) | Telugu (తెలుగు) |
|---|---|---|---|---|
| **Describe Surroundings** | "Describe surroundings" | "आसपास क्या है बताओ" | "ಸುತ್ತಮುತ್ತ ಏನಿದೆ" | "పరిసరాలను వివరించండి" |
| **Read Text / Signboards** | "Read text" | "टेक्स्ट पढ़ो" | "ಪಠ್ಯವನ್ನು ಓದು" | "టెక్స్ట్ చదవండి" |
| **Identify Medicine** | "Identify medicine" | "दवाई पहचानो" | "ಔಷಧಿ ತಿಳಿಸಿ" | "మందులను గుర్తించండి" |
| **Recognize Currency** | "Recognize currency" | "पैसे पहचानो" | "ಹಣ ಗುರುತಿಸಿ" | "కరెన్సీ గుర్తించండి" |
| **Detect Obstacles** | "Detect obstacles" | "बाधाएं खोजो" | "ಅಡೆತಡೆಗಳನ್ನು ಹುಡುಕಿ" | "అడ్డంకులను గుర్తించు" |
| **Stop Speech** | "Stop" / "Quiet" | "रुको" / "शांत" | "ನಿಲ್ಲಿಸು" | "ఆగు" / "నిలుపు" |
| **Replay Result** | "Repeat" / "Replay" | "दोबारा बोलो" | "ಮತ್ತೊಮ್ಮೆ" | "మళ్ళీ చెప్పు" |

---

## 🚀 Getting Started

### 1. Environment Configuration
Create a `.env` file in the project root (or copy from `.env.example`):
```env
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash
APP_ENVIRONMENT=development
ENABLE_DEBUG_SPEECH=true
```
*Note: The Gemini API key can also be configured directly inside the app under **Settings > Google Gemini API Key**.*

### 2. Dependency Resolution
```bash
flutter pub get
```

### 3. Run Unit & Intent Tests
```bash
flutter test
```

### 4. Run on Device / Emulator
```bash
flutter run
```

---

## 🛡️ Privacy & Safety Directives

1. **No Image Storage**: Camera captures are strictly ephemeral. They are buffered in memory or temporary cache during inference and purged immediately upon analysis completion.
2. **Medical Safety Safeguards**: The medicine module strictly refuses to invent brand names or expiry dates. If lighting, reflections, or folds obscure information, it vocalizes: *"Expiry date or dosage details are partially unclear. Please verify with a trusted person before consumption."*
3. **Currency Repositioning**: If a banknote is folded or confidence is below 75%, SightAssist instructs: *"Could not clearly recognize the currency note. Please flatten the note and hold steady under good lighting."*
