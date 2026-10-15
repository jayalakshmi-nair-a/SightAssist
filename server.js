const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

// 1. Safe Environment Variable Loader (.env)
function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valParts] = trimmed.split('=');
        if (key && valParts.length > 0) {
          process.env[key.trim()] = valParts.join('=').trim().replace(/^["']|["']$/g, '');
        }
      }
    });
  }
}

loadEnv();

const PORT = process.env.PORT || 5000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const DEFAULT_MODEL = process.env.GEMINI_MODEL || 'gemini-flash-lite-latest';

// Candidate models for automatic fallback resilience
const FALLBACK_MODELS = [
  DEFAULT_MODEL,
  'gemini-flash-lite-latest',
  'gemini-flash-latest',
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
  'gemini-3.1-flash-lite'
].filter((m, i, arr) => arr.indexOf(m) === i); // unique

function getLocalIpAddress() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

const LOCAL_LAN_IP = getLocalIpAddress();

console.log(`[SightAssist Server] Initializing SightAssist Mobile & Desktop Accessibility System...`);
console.log(`[SightAssist Server] API Key configured: ${GEMINI_API_KEY ? 'YES (Secured Externally)' : 'NO (Missing in .env)'}`);
console.log(`[SightAssist Server] Primary Vision Model: ${DEFAULT_MODEL}`);

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Helper: Detect image MIME type from Data URL or binary buffer
function detectMimeType(imageBase64) {
  if (imageBase64.startsWith('data:image/')) {
    const match = imageBase64.match(/^data:(image\/[a-zA-Z0-9\+\-\.]+);base64,/);
    if (match) return match[1];
  }

  // Inspect first bytes of Base64
  const clean = imageBase64.replace(/^data:image\/\w+;base64,/, '');
  const prefix = clean.substring(0, 16);
  if (prefix.startsWith('/9j/')) return 'image/jpeg';
  if (prefix.startsWith('iVBORw0KGgo')) return 'image/png';
  if (prefix.startsWith('UklGR')) return 'image/webp';
  if (prefix.startsWith('R0lGOD')) return 'image/gif';
  if (prefix.startsWith('Qk0')) return 'image/bmp';

  return 'image/jpeg';
}

// Helper: Single Gemini API request with timeout
function makeSingleGeminiRequest(model, apiKey, prompt, imageBase64, mimeType) {
  return new Promise((resolve, reject) => {
    const parts = [{ text: prompt }];
    if (imageBase64) {
      const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '').trim();
      parts.push({
        inline_data: {
          mime_type: mimeType || 'image/jpeg',
          data: cleanBase64
        }
      });
    }

    const postData = JSON.stringify({
      contents: [{ parts }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 600
      }
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      port: 443,
      path: `/v1beta/models/${model}:generateContent?key=${apiKey}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 25000
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            const text = json.candidates?.[0]?.content?.parts?.[0]?.text || '';
            resolve({ success: true, text: text.trim(), model });
          } else {
            const errInfo = json.error || {};
            const code = res.statusCode;
            const message = errInfo.message || `API error (${code})`;
            resolve({
              success: false,
              statusCode: code,
              errorCode: errInfo.code || code,
              message,
              model
            });
          }
        } catch (err) {
          resolve({
            success: false,
            statusCode: 500,
            message: `JSON parse error: ${err.message}`,
            model
          });
        }
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, statusCode: 504, message: 'Request timeout to Gemini API (25s)', model });
    });

    req.on('error', (err) => {
      resolve({ success: false, statusCode: 502, message: `Network error: ${err.message}`, model });
    });

    req.write(postData);
    req.end();
  });
}

// Master Gemini caller with multi-model fallback and backoff retry
async function callGeminiVision(prompt, imageBase64) {
  const apiKey = process.env.GEMINI_API_KEY || GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured in .env. Please set your Google AI Studio API key.");
  }

  const mimeType = imageBase64 ? detectMimeType(imageBase64) : 'image/jpeg';
  let lastError = null;

  for (const model of FALLBACK_MODELS) {
    for (let attempt = 1; attempt <= 2; attempt++) {
      console.log(`[SightAssist Vision] Calling model '${model}' (attempt ${attempt})...`);
      const result = await makeSingleGeminiRequest(model, apiKey, prompt, imageBase64, mimeType);

      if (result.success && result.text) {
        return {
          text: result.text,
          modelUsed: model
        };
      }

      lastError = result;

      // Handle unrecoverable authorization errors immediately
      if (result.statusCode === 400 || result.statusCode === 403) {
        if (result.message.toLowerCase().includes('api_key_invalid') || result.message.toLowerCase().includes('api key not valid')) {
          throw new Error("Invalid or revoked Gemini API key. Please generate a new key from Google AI Studio.");
        }
      }

      // If temporary demand spike (503) or rate limit (429), pause briefly before retry
      if (result.statusCode === 503 || result.statusCode === 429) {
        console.warn(`[SightAssist Vision] Model '${model}' returned ${result.statusCode}: ${result.message}. Retrying...`);
        await new Promise(r => setTimeout(r, 1000 * attempt));
        continue;
      }

      // If 404 (model not found / deprecated), immediately break to next model
      if (result.statusCode === 404) {
        console.warn(`[SightAssist Vision] Model '${model}' is unavailable (404). Falling back to next model...`);
        break;
      }
    }
  }

  const finalMsg = lastError ? `${lastError.message} (${lastError.statusCode})` : 'All candidate vision models failed.';
  throw new Error(`SightAssist AI Error: ${finalMsg}`);
}

// Prompts tailored for the visually impaired with rigorous safety directives
function buildSystemPrompt(mode, language) {
  const lang = language || 'English';

  if (mode === 'objects') {
    return `
You are SightAssist, an AI visual guide for visually impaired users.
Analyze this image and identify the clearly visible objects and people.
Format your response in ${lang}:
1. Start with a direct 1-sentence overview of what is in front of the user.
2. List key visible objects with their relative positions (e.g., center, left, right, foreground, background) based only on what is clearly visible. Do NOT claim exact distance in meters from a single photograph.
3. Highlight any potential obstacles or safe clear paths.
Keep the description natural, clear, and easy to understand when read aloud. Do not use markdown symbols like asterisks or hashtags.
`.trim();
  }

  if (mode === 'ocr' || mode === 'text') {
    return `
You are SightAssist, an optical character recognition reader for a visually impaired user.
Carefully examine this image and read all visible printed or handwritten text verbatim in ${lang}.
If this is a book, sign, signboard, bus number, document, or label, read the text in logical reading order.
If no readable text is found, state clearly: "No readable text was detected in the frame."
Never guess or extrapolate text that is not visible. Do not use markdown symbols or bullets.
`.trim();
  }

  if (mode === 'medicine') {
    return `
You are SightAssist, an accessibility assistant helping a blind person inspect pharmaceutical packaging.
Analyze this image and report in ${lang}:
1. Brand name and active salt if clearly visible.
2. Expiry date (e.g. Exp, Best Before) if visible. If not clearly visible, explicitly state that the expiry date cannot be confirmed.
3. Dosage or strength (e.g. 500mg) if visible.
4. Any critical warning on the packaging.
CRITICAL SAFETY DIRECTIVE: Never invent or guess medicine names, active salts, or expiry dates. If text or packaging is blurry or uncertain, explicitly state: "Medicine label is unclear. Please verify with a trusted person before taking any medication." Do not use markdown symbols.
`.trim();
  }

  if (mode === 'currency') {
    return `
You are SightAssist, an accessibility assistant helping a visually impaired user recognize currency (especially Indian Rupees or coins).
Analyze this image and report in ${lang}:
1. Denomination of the banknote or coin (e.g. 10, 20, 50, 100, 200, 500, 2000 Rupees).
2. Condition of note (e.g. clearly visible, folded, partially cropped, blurry).
3. If note is folded or cut off, guide the user on how to reposition it.
SAFETY DIRECTIVE: If note is folded, torn, or unclear, state: "Currency note is partially obscured. Please flatten the note and hold it steady." Never guess denominations if uncertain. Do not use markdown symbols.
`.trim();
  }

  if (mode === 'hazards' || mode === 'obstacles') {
    return `
You are SightAssist, obstacle and hazard detection system for a visually impaired user walking forward.
Analyze this camera viewpoint for immediate hazards:
- Stairs (ascending or descending), steps, curbs
- Approaching vehicles, bicycles, carts
- Walking obstacles, wet floors, low hanging branches, cables
State the most urgent hazard first and its relative direction (directly ahead, to your left, to your right).
If the path is clear, state: "The path directly ahead appears clear."
CRITICAL SAFETY DIRECTIVE: SightAssist provides audio guidance only and does NOT guarantee collision avoidance or replace a white cane or guide dog. State relative positions only. Never claim exact distances in meters. Announce uncertainty clearly if visual clarity is limited. Do not use markdown symbols.
`.trim();
  }

  // Default: Scene Understanding
  return `
You are SightAssist, an AI visual assistant for a visually impaired user.
Carefully inspect this image and provide a concise, natural spoken description in ${lang}.
Describe:
- What the surroundings are (room, street, desk, nature, etc.)
- People and key objects directly in view
- Relative positioning (in front of you, to your left, to your right) only when supported by the image
Keep your response to 2 to 3 clear, natural spoken sentences without any markdown formatting like asterisks or bullet points.
`.trim();
}

// Embedded High-Contrast Accessible SightAssist Web UI (Optimized for Android Mobile & Desktop)
function getAccessibleWebHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover">
  <meta name="theme-color" content="#08090C">
  <meta name="description" content="SightAssist: Hands-free voice-first AI visual assistant for visually impaired users.">
  <link rel="manifest" href="/manifest.json">
  <link rel="icon" type="image/png" href="/icons/Icon-192.png">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="SightAssist">

  <title>SightAssist – Hands-Free Voice Visual Assistant</title>
  <style>
    :root {
      --bg: #08090C;
      --surface: #121620;
      --surface-elevated: #1B202D;
      --border: #2E364A;
      --yellow: #FFD600;
      --cyan: #00E5FF;
      --green: #00E676;
      --orange: #FF9100;
      --red: #FF1744;
      --purple: #D500F9;
      --text: #FFFFFF;
      --text-muted: #94A3B8;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.5;
      padding: 12px;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      overflow-x: hidden;
    }

    /* Accessibility Focus Outline */
    *:focus-visible {
      outline: 4px solid var(--yellow);
      outline-offset: 4px;
    }

    .container {
      width: 100%;
      max-width: 860px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }


    /* Top Brand Header */
    header {
      background: var(--surface);
      border: 2px solid var(--border);
      border-radius: 14px;
      padding: 14px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .logo-badge {
      background: var(--yellow);
      color: #000;
      font-size: 26px;
      font-weight: 900;
      width: 46px;
      height: 46px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    h1 {
      font-size: 22px;
      font-weight: 900;
      color: #FFFFFF;
      letter-spacing: -0.5px;
    }

    .tagline {
      font-size: 13px;
      color: var(--yellow);
      font-weight: 700;
    }

    .header-controls {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }

    /* Live Voice Status Stage Banner */
    .status-stage {
      background: var(--surface);
      border: 3px solid var(--green);
      border-radius: 16px;
      padding: 16px 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      box-shadow: 0 0 20px rgba(0, 230, 118, 0.2);
      transition: all 0.3s;
    }

    .status-stage.state-listening {
      border-color: var(--green);
      box-shadow: 0 0 24px rgba(0, 230, 118, 0.35);
    }

    .status-stage.state-capturing {
      border-color: var(--yellow);
      box-shadow: 0 0 24px rgba(255, 214, 0, 0.35);
    }

    .status-stage.state-processing {
      border-color: var(--cyan);
      box-shadow: 0 0 24px rgba(0, 229, 255, 0.35);
    }

    .status-stage.state-speaking {
      border-color: var(--purple);
      box-shadow: 0 0 24px rgba(213, 0, 249, 0.35);
    }

    .status-stage.state-error {
      border-color: var(--red);
      box-shadow: 0 0 24px rgba(255, 23, 68, 0.35);
    }

    .status-stage.state-welcome {
      border-color: var(--yellow);
      box-shadow: 0 0 24px rgba(255, 214, 0, 0.35);
    }

    .state-info {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .state-icon {
      font-size: 32px;
      line-height: 1;
      flex-shrink: 0;
    }

    .state-title {
      font-size: 20px;
      font-weight: 900;
      color: #FFFFFF;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .state-sub {
      font-size: 14px;
      font-weight: 700;
      color: var(--text-muted);
    }

    .voice-pulse {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: var(--green);
      box-shadow: 0 0 14px var(--green);
      animation: pulseDot 1s infinite alternate;
      display: inline-block;
    }

    @keyframes pulseDot {
      from { transform: scale(0.85); opacity: 0.6; }
      to { transform: scale(1.3); opacity: 1; }
    }

    /* Live Voice Transcript Banner */
    .heard-banner {
      background: var(--surface-elevated);
      border: 2px solid var(--border);
      border-radius: 12px;
      padding: 12px 18px;
      font-size: 17px;
      font-weight: 700;
      color: var(--cyan);
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }

    .heard-label {
      color: var(--text-muted);
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    /* Camera Viewfinder (Automated In-Memory Capture) */
    .viewfinder-card {
      background: var(--surface);
      border: 2px solid var(--border);
      border-radius: 16px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .section-title {
      font-size: 18px;
      font-weight: 800;
      color: var(--cyan);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .media-box {
      background: #000;
      border: 2px solid var(--border);
      border-radius: 12px;
      min-height: 200px;
      max-height: 360px;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      position: relative;
    }

    video {
      width: 100%;
      height: 100%;
      max-height: 360px;
      object-fit: cover;
      display: block;
    }

    .preview-img {
      max-width: 100%;
      max-height: 360px;
      object-fit: contain;
      display: block;
    }

    .cam-overlay-indicator {
      position: absolute;
      top: 12px;
      left: 12px;
      background: rgba(0, 0, 0, 0.78);
      border: 1px solid var(--green);
      color: var(--green);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 800;
      display: flex;
      align-items: center;
      gap: 6px;
      z-index: 5;
    }

    .cam-fallback-msg {
      padding: 24px;
      text-align: center;
      font-size: 15px;
      font-weight: 700;
      color: var(--text-muted);
      display: none;
    }

    /* Result Stage & Voice Reader */
    .result-card {
      background: var(--surface);
      border: 2px solid var(--border);
      border-radius: 16px;
      padding: 18px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .result-text-box {
      font-size: 19px;
      font-weight: 600;
      color: #FFFFFF;
      background: var(--surface-elevated);
      border-left: 6px solid var(--yellow);
      padding: 18px;
      border-radius: 8px;
      white-space: pre-wrap;
      line-height: 1.6;
      max-height: 320px;
      overflow-y: auto;
    }

    .voice-control-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .btn-voice {
      padding: 10px 16px;
      font-size: 15px;
      font-weight: 800;
      border-radius: 10px;
      border: 2px solid var(--border);
      background: var(--surface-elevated);
      color: #FFFFFF;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      min-height: 48px;
      transition: all 0.15s;
    }

    .btn-voice:hover {
      border-color: var(--yellow);
      color: var(--yellow);
    }

    /* Accessible Touch Actions (Fallback for non-voice / sighted users) */
    .manual-actions {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 10px;
    }

    .touch-btn {
      min-height: 64px;
      padding: 12px 14px;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 800;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      gap: 8px;
      border: 2px solid transparent;
      background: var(--surface-elevated);
      color: #FFFFFF;
      transition: all 0.15s;
    }

    .touch-btn:hover {
      transform: translateY(-2px);
    }

    .btn-y { border-color: var(--yellow); color: var(--yellow); }
    .btn-c { border-color: var(--cyan); color: var(--cyan); }
    .btn-g { border-color: var(--green); color: var(--green); }
    .btn-o { border-color: var(--orange); color: var(--orange); }

    /* Voice Commands Reference Box */
    .guide-card {
      background: var(--surface);
      border: 2px solid var(--border);
      border-radius: 16px;
      padding: 18px 20px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .guide-title {
      font-size: 17px;
      font-weight: 800;
      color: var(--yellow);
    }

    .guide-list {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 8px;
      font-size: 14px;
      font-weight: 700;
      color: var(--text-muted);
    }

    .guide-item span {
      color: #FFFFFF;
    }


    /* Error Banner */
    .error-banner {
      display: none;
      background: #2a080d;
      border: 2px solid var(--red);
      color: #ffb4be;
      padding: 14px 18px;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 700;
    }


    footer {
      font-size: 12px;
      color: var(--text-muted);
      text-align: center;
      margin-top: 10px;
      padding-bottom: 24px;
    }

    /* Mobile Responsive Rules for Android Portrait */
    @media (max-width: 600px) {
      body {
        padding: 8px;
      }
      .container {
        gap: 10px;
      }
      header {
        padding: 10px 14px;
      }
      .brand h1 {
        font-size: 19px;
      }
      .logo-badge {
        width: 40px;
        height: 40px;
        font-size: 22px;
      }
      .status-stage {
        padding: 12px 14px;
      }
      .state-title {
        font-size: 17px;
      }
      .state-sub {
        font-size: 13px;
      }
      .media-box {
        min-height: 180px;
        max-height: 38vh;
      }
      video, .preview-img {
        max-height: 38vh;
      }
      .result-text-box {
        font-size: 17px;
        padding: 14px;
      }
      .manual-actions {
        grid-template-columns: 1fr 1fr;
      }
      .touch-btn {
        min-height: 60px;
        font-size: 14px;
      }
    }
  </style>
</head>
<body>


  <div class="container" role="main">

    <!-- Top Header -->
    <header>
      <div class="brand">
        <div class="logo-badge" aria-hidden="true">👁️</div>
        <div>
          <h1>SightAssist</h1>
          <div class="tagline">Voice-First AI Eyes for Visually Impaired</div>
        </div>
      </div>
      <div class="header-controls">
        <label for="languageSelect" style="font-size: 13px; font-weight: 700; color: var(--text-muted); display: flex; align-items: center; gap: 6px;">
          🌐
          <select id="languageSelect" onchange="handleLanguageChange(this.value)" style="background: var(--surface-elevated); color: #fff; border: 2px solid var(--border); padding: 6px 10px; border-radius: 8px; font-weight: 700; font-size: 14px;">
            <option value="English">English</option>
            <option value="Hindi">हिन्दी (Hindi)</option>
            <option value="Kannada">ಕನ್ನಡ (Kannada)</option>
            <option value="Telugu">తెలుగు (Telugu)</option>
          </select>
        </label>
      </div>
    </header>

    <!-- Master Voice State Stage Banner -->
    <section class="status-stage state-welcome" id="statusStage" aria-live="assertive" aria-atomic="true">
      <div class="state-info">
        <div class="state-icon" id="stateIcon">🔊</div>
        <div>
          <div class="state-title" id="stateTitle">
            <span id="stateTitleText">Initializing Voice Assistant...</span>
            <div class="voice-pulse" id="voicePulse" style="display: none;"></div>
          </div>
          <div class="state-sub" id="stateSub">Preparing speech engine and camera...</div>
        </div>
      </div>
      <div style="display: flex; gap: 8px;">
        <button id="btnToggleListening" class="btn-voice" onclick="toggleContinuousListening()" aria-label="Toggle continuous listening">
          🎙️ Listening Active
        </button>
      </div>
    </section>

    <!-- Live Heard Voice Command Transcript -->
    <div class="heard-banner" id="heardBanner" aria-live="polite">
      <span class="heard-label">Last Heard:</span>
      <span id="heardText" style="color: #fff;">Waiting for your command...</span>
    </div>

    <!-- Error Box -->
    <div class="error-banner" id="errorBanner" role="alert">
      <div id="errorText">Error message here.</div>
      <button class="btn-voice" style="margin-top: 10px; border-color: var(--red);" onclick="retryLastAction()">
        🔄 Retry Command
      </button>
    </div>

    <!-- Live Viewfinder & Hands-Free Capture Stage -->
    <section class="viewfinder-card" aria-label="Live Camera Feed">
      <div class="section-title">
        <span>📷 Camera Feed (<span id="cameraModeLabel">Auto-Detecting</span>)</span>
        <button class="btn-voice" style="padding: 6px 12px; font-size: 13px;" onclick="switchCamera()">
          🔄 Switch Camera
        </button>
      </div>

      <div class="media-box" id="mediaBox">
        <video id="webcamVideo" autoplay playsinline muted></video>
        <img id="capturedPreview" class="preview-img" alt="Captured snapshot preview" style="display: none;">
        <div class="cam-overlay-indicator" id="camIndicator">
          <div style="width: 8px; height: 8px; border-radius: 50%; background: var(--green);"></div>
          <span id="camIndicatorText">Camera Active</span>
        </div>
        <div class="cam-fallback-msg" id="camFallbackMsg">
          Camera unavailable. Please check camera permissions in your browser.
        </div>
      </div>
    </section>

    <!-- Spoken Result Display -->
    <section class="result-card" id="resultCard" aria-label="Spoken Result">
      <div class="section-title">
        <span id="resultModeTitle">📢 Spoken Result</span>
        <div class="voice-control-row">
          <button class="btn-voice" onclick="speakCurrentResult()">
            🔊 Read Aloud
          </button>
          <button class="btn-voice" onclick="stopSpeech()">
            ⏹️ Stop
          </button>
          <button class="btn-voice" onclick="repeatResult()">
            🔁 Repeat
          </button>
        </div>
      </div>
      <div class="result-text-box" id="resultTextBox">
        Say "Describe my surroundings" or "Identify objects" to begin.
      </div>
    </section>

    <!-- Manual Touch Action Fallback (WCAG AAA Target: >= 64px) -->
    <section class="viewfinder-card" aria-label="Manual Feature Touch Fallback">
      <div class="section-title">
        <span>✋ Manual Touch Fallback</span>
      </div>
      <div class="manual-actions">
        <button class="touch-btn btn-y" onclick="handleIntent('surroundings')">
          👁️ Describe Surroundings
        </button>
        <button class="touch-btn btn-c" onclick="handleIntent('objects')">
          🔍 Identify Objects
        </button>
        <button class="touch-btn btn-y" onclick="handleIntent('ocr')">
          📖 Read Text (OCR)
        </button>
        <button class="touch-btn btn-g" onclick="handleIntent('medicine')">
          💊 Read Medicine Label
        </button>
        <button class="touch-btn btn-o" onclick="handleIntent('currency')">
          💵 Recognise Currency
        </button>
        <button class="touch-btn btn-c" onclick="handleIntent('hazards')">
          ⚠️ Check Obstacles
        </button>
      </div>
    </section>


    <!-- Voice Command Reference Guide -->
    <section class="guide-card" aria-label="Spoken Commands Reference">
      <div class="guide-title">🎙️ What You Can Say Hands-Free:</div>
      <div class="guide-list">
        <div class="guide-item">👁️ <span>"Describe my surroundings"</span></div>
        <div class="guide-item">🔍 <span>"Identify the objects around me"</span></div>
        <div class="guide-item">📖 <span>"Read the text"</span></div>
        <div class="guide-item">💊 <span>"Read this medicine label"</span></div>
        <div class="guide-item">💵 <span>"Recognise this currency"</span></div>
        <div class="guide-item">⚠️ <span>"Check for obstacles"</span></div>
        <div class="guide-item">🔁 <span>"Repeat the result"</span></div>
        <div class="guide-item">⏹️ <span>"Stop speaking"</span></div>
        <div class="guide-item">🐢 <span>"Speak more slowly"</span></div>
        <div class="guide-item">🌐 <span>"Change language to Hindi / Kannada / Telugu"</span></div>
        <div class="guide-item">🔄 <span>"Switch camera"</span></div>
        <div class="guide-item">❓ <span>"Help me"</span></div>
      </div>
    </section>

    <footer>
      SightAssist Accessibility System • Progressive Web App Ready • Powered by Google Gemini
    </footer>

  </div>

  <script>
    // --- State Machine & Configuration ---
    let currentState = 'WELCOME';
    let continuousListening = true;
    let currentLanguage = localStorage.getItem('sa_language') || 'English';
    let speechRate = parseFloat(localStorage.getItem('sa_speech_rate') || '1.0');
    let voiceResponsesEnabled = true;

    // Mobile device detection: on mobile, prefer environment (rear) camera; on desktop, prefer user (webcam)
    const isMobileDevice = /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    let cameraFacingMode = isMobileDevice ? 'environment' : 'user';

    let currentStream = null;
    let recognition = null;
    let isRecognitionActive = false;
    let lastRecognizedPhrase = '';
    let lastCommandTimestamp = 0;
    let lastSpokenText = '';
    let lastAction = 'surroundings';

    // OCR Long Text Pagination
    let ocrSections = [];
    let currentOcrIndex = 0;

    // Elements
    const statusStage = document.getElementById('statusStage');
    const stateIcon = document.getElementById('stateIcon');
    const stateTitleText = document.getElementById('stateTitleText');
    const stateSub = document.getElementById('stateSub');
    const voicePulse = document.getElementById('voicePulse');
    const heardText = document.getElementById('heardText');
    const videoEl = document.getElementById('webcamVideo');
    const previewEl = document.getElementById('capturedPreview');
    const camIndicator = document.getElementById('camIndicator');
    const camIndicatorText = document.getElementById('camIndicatorText');
    const cameraModeLabel = document.getElementById('cameraModeLabel');
    const camFallbackMsg = document.getElementById('camFallbackMsg');
    const resultCard = document.getElementById('resultCard');
    const resultTextBox = document.getElementById('resultTextBox');
    const resultModeTitle = document.getElementById('resultModeTitle');
    const errorBanner = document.getElementById('errorBanner');
    const errorText = document.getElementById('errorText');
    const btnToggleListening = document.getElementById('btnToggleListening');
    const languageSelect = document.getElementById('languageSelect');

    languageSelect.value = currentLanguage;
    updateCameraLabel();

    function updateCameraLabel() {
      cameraModeLabel.textContent = cameraFacingMode === 'environment' ? 'Rear Camera (Mobile)' : 'Front Camera / Webcam';
    }

    // --- Web Audio Synthesizer (Earcons / Audio Cues) ---
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

    function playTone(freq, type, duration, delay = 0) {
      try {
        if (audioCtx.state === 'suspended') {
          audioCtx.resume();
        }
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, audioCtx.currentTime + delay);
        gain.gain.setValueAtTime(0.08, audioCtx.currentTime + delay);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + delay + duration);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(audioCtx.currentTime + delay);
        osc.stop(audioCtx.currentTime + delay + duration);
      } catch (_) {}
    }

    function cueListening() {
      playTone(440, 'sine', 0.12, 0);
      playTone(880, 'sine', 0.16, 0.12);
    }

    function cueCapture() {
      playTone(523.25, 'triangle', 0.08, 0);
      playTone(659.25, 'triangle', 0.12, 0.08);
    }

    function cueSuccess() {
      playTone(587.33, 'sine', 0.12, 0);
      playTone(880, 'sine', 0.2, 0.12);
    }

    function cueError() {
      playTone(300, 'sawtooth', 0.18, 0);
      playTone(220, 'sawtooth', 0.24, 0.18);
    }

    // --- UI State Management ---
    function setState(newState, subText = '') {
      currentState = newState;
      statusStage.className = 'status-stage state-' + newState.toLowerCase();

      switch (newState) {
        case 'WELCOME':
          stateIcon.textContent = '🔊';
          stateTitleText.textContent = 'Welcome to SightAssist';
          stateSub.textContent = subText || 'Ready to assist you...';
          voicePulse.style.display = 'none';
          break;
        case 'LISTENING':
          stateIcon.textContent = '🎙️';
          stateTitleText.textContent = 'Listening to your command...';
          stateSub.textContent = subText || 'Speak naturally. Say "Describe surroundings", "Read text", or "Help".';
          voicePulse.style.display = 'inline-block';
          break;
        case 'CAPTURING':
          stateIcon.textContent = '📸';
          stateTitleText.textContent = 'Capturing image...';
          stateSub.textContent = subText || 'Holding camera steady...';
          voicePulse.style.display = 'none';
          break;
        case 'PROCESSING':
          stateIcon.textContent = '⏳';
          stateTitleText.textContent = 'Analysing with Gemini AI...';
          stateSub.textContent = subText || 'Processing visual features...';
          voicePulse.style.display = 'none';
          break;
        case 'SPEAKING':
          stateIcon.textContent = '🔊';
          stateTitleText.textContent = 'Speaking result aloud...';
          stateSub.textContent = subText || 'Tap anywhere or say "Stop" to interrupt.';
          voicePulse.style.display = 'none';
          break;
        case 'ERROR':
          stateIcon.textContent = '⚠️';
          stateTitleText.textContent = 'Error Encountered';
          stateSub.textContent = subText || 'Say "Repeat" or tap to retry.';
          voicePulse.style.display = 'none';
          break;
      }
    }

    // --- Speech Synthesis (Text to Speech) with Deadlock Prevention ---
    let activeUtterance = null;
    let ttsFailsafeTimer = null;

    function speak(text, onComplete = null, interrupt = true) {
      if (ttsFailsafeTimer) {
        clearTimeout(ttsFailsafeTimer);
        ttsFailsafeTimer = null;
      }

      if (!('speechSynthesis' in window)) {
        if (onComplete) onComplete();
        return;
      }

      if (interrupt) {
        try { window.speechSynthesis.cancel(); } catch (_) {}
      }

      if (!voiceResponsesEnabled) {
        if (onComplete) onComplete();
        return;
      }

      setState('SPEAKING');

      // Temporarily pause speech recognition while speaking to prevent self-echo
      if (window.VoiceManager) {
        VoiceManager.pauseRecognition();
      }

      const utterance = new SpeechSynthesisUtterance(text);
      activeUtterance = utterance; // Prevent garbage collection bug in Chrome
      utterance.rate = speechRate;
      utterance.pitch = 1.0;

      const langMap = {
        'English': 'en-IN',
        'Hindi': 'hi-IN',
        'Kannada': 'kn-IN',
        'Telugu': 'te-IN'
      };
      utterance.lang = langMap[currentLanguage] || 'en-US';

      // Pick matching voice if available
      try {
        const voices = window.speechSynthesis.getVoices();
        const targetLang = utterance.lang.toLowerCase();
        const matchedVoice = voices.find(v => v.lang.toLowerCase().startsWith(targetLang) || v.lang.toLowerCase().includes(currentLanguage.toLowerCase().substring(0, 2)));
        if (matchedVoice) {
          utterance.voice = matchedVoice;
        }
      } catch (_) {}

      let hasFinished = false;
      const finishSpeech = () => {
        if (hasFinished) return;
        hasFinished = true;
        if (ttsFailsafeTimer) {
          clearTimeout(ttsFailsafeTimer);
          ttsFailsafeTimer = null;
        }
        activeUtterance = null;
        lastSpokenText = text;
        if (onComplete) {
          onComplete();
        } else {
          if (window.VoiceManager) {
            VoiceManager.resumeListening();
          }
        }
      };

      utterance.onend = finishSpeech;
      utterance.onerror = (e) => {
        console.warn('TTS utterance error:', e);
        finishSpeech();
      };

      // Failsafe timer: Chrome and Android WebView can freeze onend if audio is un-focused or long.
      // Expected duration based on ~13 characters per second, bounded between 3.5s and 25s
      const expectedDurationMs = Math.max(3500, Math.min(25000, Math.round((text.length / 13) * 1000 * (1 / speechRate) + 2000)));
      ttsFailsafeTimer = setTimeout(() => {
        if (!hasFinished) {
          console.warn('[SightAssist] TTS onend failsafe triggered after ' + expectedDurationMs + 'ms');
          finishSpeech();
        }
      }, expectedDurationMs);

      try {
        window.speechSynthesis.speak(utterance);
      } catch (err) {
        console.warn('TTS speak error:', err);
        finishSpeech();
      }
    }

    function stopSpeech() {
      if (ttsFailsafeTimer) {
        clearTimeout(ttsFailsafeTimer);
        ttsFailsafeTimer = null;
      }
      if ('speechSynthesis' in window) {
        try { window.speechSynthesis.cancel(); } catch (_) {}
      }
      activeUtterance = null;
      setState('LISTENING', 'Speech stopped. I am listening.');
      cueListening();
      if (window.VoiceManager) {
        VoiceManager.startRecognition();
      }
    }

    function repeatResult() {
      if (lastSpokenText) {
        speak(lastSpokenText);
      } else {
        speak('There is no previous result to repeat. Tell me what you need.');
      }
    }

    function speakCurrentResult() {
      const text = resultTextBox.textContent;
      if (text && text.trim().length > 0) {
        speak(text);
      }
    }

    // --- Centralized Camera Manager with Concurrency Lock and Stream Lifecycle Management ---
    const CameraManager = {
      stream: null,
      isInitializing: false,
      initPromise: null,
      facingMode: /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ? 'environment' : 'user',

      isSupported() {
        return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
      },

      isReady() {
        if (!this.stream) return false;
        const tracks = this.stream.getVideoTracks();
        if (!tracks || tracks.length === 0) return false;
        return tracks[0].readyState === 'live' && videoEl.videoWidth > 0;
      },

      async getStream(forceSwitch = false) {
        if (!forceSwitch && this.isReady()) {
          return this.stream;
        }

        // Concurrency Lock: Reuse in-flight acquisition promise if already initializing
        if (this.isInitializing && this.initPromise) {
          return this.initPromise;
        }

        this.isInitializing = true;
        this.initPromise = (async () => {
          try {
            this.release();

            // Micro-pause allowing Windows Media Foundation / DirectShow to release hardware lock
            await new Promise(r => setTimeout(r, 120));

            if (!this.isSupported()) {
              throw new Error('Camera API (getUserMedia) not supported or requires a secure context (HTTPS/localhost).');
            }

            let newStream = null;
            // Attempt 1: Facing mode with ideal 720p dimensions
            try {
              newStream = await navigator.mediaDevices.getUserMedia({
                video: {
                  facingMode: this.facingMode ? { ideal: this.facingMode } : undefined,
                  width: { ideal: 1280 },
                  height: { ideal: 720 }
                },
                audio: false
              });
            } catch (err1) {
              console.warn('Constrained camera request failed, attempting fallback {video: true}...', err1);
              // Attempt 2: Universal unconstrained fallback
              newStream = await navigator.mediaDevices.getUserMedia({
                video: true,
                audio: false
              });
            }

            this.stream = newStream;
            videoEl.srcObject = newStream;
            videoEl.style.display = 'block';
            previewEl.style.display = 'none';
            camIndicator.style.display = 'flex';
            camFallbackMsg.style.display = 'none';
            updateCameraLabel();

            // Wait for video element to receive frames & metadata
            await new Promise((resolve) => {
              if (videoEl.videoWidth > 0) return resolve();
              const onMeta = () => {
                videoEl.removeEventListener('loadedmetadata', onMeta);
                resolve();
              };
              videoEl.addEventListener('loadedmetadata', onMeta);
              setTimeout(resolve, 800);
            });

            try {
              await videoEl.play();
            } catch (_) {}

            return newStream;
          } catch (err) {
            console.error('Camera acquisition error:', err);
            camIndicator.style.display = 'none';
            camFallbackMsg.style.display = 'block';
            this.stream = null;

            if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
              showError('Camera access blocked. Click the lock/camera icon in your address bar to allow camera access.');
              speak('Camera permission was blocked. Please allow camera access in your browser address bar.');
            } else if (err.name === 'NotReadableError' || err.name === 'TrackStartError') {
              showError('Camera is busy. Please close other camera apps (Zoom, Teams, Camera) and retry.');
              speak('Camera is currently busy. Please close other camera applications and try again.');
            } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
              showError('No camera found on this device.');
              speak('No camera was detected on this device.');
            } else {
              showError('Camera error: ' + err.message);
            }
            throw err;
          } finally {
            this.isInitializing = false;
            this.initPromise = null;
          }
        })();

        return this.initPromise;
      },

      async switchCamera() {
        this.facingMode = this.facingMode === 'user' ? 'environment' : 'user';
        updateCameraLabel();
        speak('Switching camera.');
        try {
          await this.getStream(true);
          speak('Camera switched. I am listening.');
        } catch (_) {}
      },

      release() {
        if (this.stream) {
          try {
            this.stream.getTracks().forEach(track => {
              track.stop();
              this.stream.removeTrack(track);
            });
          } catch (_) {}
          this.stream = null;
        }
        if (videoEl.srcObject) {
          videoEl.srcObject = null;
        }
      },

      captureFrame() {
        if (!videoEl.videoWidth || !videoEl.videoHeight) {
          return null;
        }

        const maxDimension = 1280;
        let width = videoEl.videoWidth;
        let height = videoEl.videoHeight;

        if (width > maxDimension || height > maxDimension) {
          if (width > height) {
            height = Math.round((height * maxDimension) / width);
            width = maxDimension;
          } else {
            width = Math.round((width * maxDimension) / height);
            height = maxDimension;
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(videoEl, 0, 0, width, height);

        const base64Data = canvas.toDataURL('image/jpeg', 0.85);
        previewEl.src = base64Data;
        previewEl.style.display = 'block';
        videoEl.style.display = 'none';

        cueCapture();
        return base64Data;
      }
    };

    function initCamera() {
      return CameraManager.getStream();
    }

     // Lifecycle: Release camera resources when phone is locked or backgrounded
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        if (window.VoiceManager) {
          VoiceManager.pauseRecognition();
        }
        CameraManager.release();
      } else {
        CameraManager.getStream().then(() => {
          if (continuousListening && currentState === 'LISTENING' && window.VoiceManager) {
            VoiceManager.startRecognition();
          }
        }).catch(() => {});
      }
    });

    // --- Centralized Voice Assistant Controller (VoiceManager) ---
    const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;

    const VoiceManager = {
      recognition: null,
      isActive: false,
      isStarting: false,
      hasPermissionDenied: false,
      restartTimer: null,
      lastCommandTimestamp: 0,
      lastRecognizedPhrase: '',

      init() {
        if (!SpeechRec) {
          console.warn('[SightAssist] Web Speech Recognition is not supported in this browser.');
          setState('ERROR', 'Voice recognition not supported. Please use Google Chrome or Microsoft Edge.');
          return false;
        }

        if (this.recognition) return true;

        try {
          this.recognition = new SpeechRec();
          this.recognition.continuous = true;
          this.recognition.interimResults = false;
          this.recognition.maxAlternatives = 1;

          const langMap = {
            'English': 'en-IN',
            'Hindi': 'hi-IN',
            'Kannada': 'kn-IN',
            'Telugu': 'te-IN'
          };
          this.recognition.lang = langMap[currentLanguage] || 'en-US';

          this.recognition.onstart = () => {
            this.isActive = true;
            this.isStarting = false;
            if (currentState === 'WELCOME' || currentState === 'ERROR') {
              setState('LISTENING');
            }
          };

          this.recognition.onresult = (event) => {
            if (currentState === 'SPEAKING' || currentState === 'PROCESSING' || currentState === 'CAPTURING') {
              return; // Echo prevention: ignore speech captured while system is speaking or processing
            }

            const lastResult = event.results[event.results.length - 1];
            if (!lastResult || !lastResult[0]) return;

            const transcript = lastResult[0].transcript.trim();
            const now = Date.now();

            // Self-echo suppression: prevent re-triggering on remnants of spoken responses
            if (lastSpokenText && (
              transcript.toLowerCase().includes('welcome to sightassist') ||
              (lastSpokenText.toLowerCase().includes(transcript.toLowerCase()) && (now - this.lastCommandTimestamp) < 3000)
            )) {
              return;
            }

            // Debounce duplicate utterances within 1200ms
            if (transcript === this.lastRecognizedPhrase && (now - this.lastCommandTimestamp) < 1200) {
              return;
            }

            this.lastRecognizedPhrase = transcript;
            this.lastCommandTimestamp = now;

            heardText.textContent = '"' + transcript + '"';
            console.log('[SightAssist Voice Command]:', transcript);

            processVoiceCommand(transcript);
          };

          this.recognition.onerror = (event) => {
            this.isStarting = false;
            console.warn('[SightAssist Recognition Event]:', event.error);

            if (event.error === 'not-allowed' || event.error === 'service-not-allowed') {
              this.hasPermissionDenied = true;
              this.isActive = false;
              setState('ERROR', 'Microphone blocked. Please tap the lock icon in your address bar to allow microphone.');
              speak('Microphone access is blocked. Please allow microphone access in your browser address bar.');
            } else if (event.error === 'no-speech') {
              // Normal speech timeout; onend will automatically restart if continuous
            } else if (event.error === 'aborted') {
              this.isActive = false;
            } else {
              // Network or audio capture glitch: schedule controlled restart
              if (continuousListening && !this.hasPermissionDenied && currentState === 'LISTENING') {
                if (this.restartTimer) clearTimeout(this.restartTimer);
                this.restartTimer = setTimeout(() => {
                  this.startRecognition();
                }, 800);
              }
            }
          };

          this.recognition.onend = () => {
            this.isActive = false;
            this.isStarting = false;

            // Controlled automatic restart to maintain hands-free listening
            if (continuousListening && !this.hasPermissionDenied && (currentState === 'LISTENING' || currentState === 'WELCOME')) {
              if (this.restartTimer) clearTimeout(this.restartTimer);
              this.restartTimer = setTimeout(() => {
                if (continuousListening && !this.hasPermissionDenied && currentState === 'LISTENING') {
                  this.startRecognition();
                }
              }, 300);
            }
          };

          return true;
        } catch (err) {
          console.error('[SightAssist] Recognition setup failure:', err);
          return false;
        }
      },

      startRecognition() {
        if (!this.recognition) {
          if (!this.init()) return;
        }

        if (this.hasPermissionDenied || this.isActive || this.isStarting) return;
        if (currentState === 'SPEAKING' || currentState === 'PROCESSING' || currentState === 'CAPTURING') return;

        this.isStarting = true;
        try {
          this.recognition.start();
        } catch (err) {
          this.isStarting = false;
          // InvalidStateError occurs if already starting, harmless
        }
      },

      pauseRecognition() {
        if (this.restartTimer) {
          clearTimeout(this.restartTimer);
          this.restartTimer = null;
        }
        if (this.recognition && this.isActive) {
          try {
            this.recognition.abort();
          } catch (_) {}
        }
        this.isActive = false;
        this.isStarting = false;
      },

      resumeListening() {
        if (this.restartTimer) {
          clearTimeout(this.restartTimer);
          this.restartTimer = null;
        }
        if (!continuousListening || this.hasPermissionDenied) return;
        setState('LISTENING');
        cueListening();
        this.restartTimer = setTimeout(() => {
          this.startRecognition();
        }, 350);
      },

      updateLanguage(lang) {
        if (!this.recognition) return;
        const langMap = {
          'English': 'en-IN',
          'Hindi': 'hi-IN',
          'Kannada': 'kn-IN',
          'Telugu': 'te-IN'
        };
        this.recognition.lang = langMap[lang] || 'en-US';
        if (this.isActive) {
          this.pauseRecognition();
          setTimeout(() => {
            this.startRecognition();
          }, 300);
        }
      }
    };

    window.VoiceManager = VoiceManager;

    function toggleContinuousListening() {
      continuousListening = !continuousListening;
      localStorage.setItem('sa_continuous_listening', continuousListening);

      if (continuousListening) {
        btnToggleListening.textContent = '🎙️ Listening Active';
        btnToggleListening.style.borderColor = 'var(--green)';
        speak('Continuous listening enabled. I am listening.');
        VoiceManager.startRecognition();
      } else {
        btnToggleListening.textContent = '🔇 Listening Paused';
        btnToggleListening.style.borderColor = 'var(--red)';
        VoiceManager.pauseRecognition();
        speak('Continuous listening paused.');
        setState('WELCOME', 'Listening paused.');
      }
    }

    // --- Natural Language Intent Router ---
    function processVoiceCommand(rawText) {
      const text = rawText.toLowerCase().trim();

      // 1. Stop / Be quiet (Highest priority interrupt)
      if (matchKeywords(text, ['stop', 'be quiet', 'shut up', 'pause speech', 'रुको', 'शांत रहो', 'ನಿಲ್ಲಿಸು', 'ఆగు'])) {
        stopSpeech();
        return;
      }

      // 2. Repeat Result
      if (matchKeywords(text, ['repeat', 'say again', 'say that again', 'repeat result', 'दोबारा बोलो', 'फिर से बोलो', 'ಮತ್ತೊಮ್ಮೆ', 'మళ్ళీ చెప్పు'])) {
        repeatResult();
        return;
      }

      // 3. Speech Rate Adjustments
      if (matchKeywords(text, ['speak more slowly', 'speak slowly', 'slower', 'slow down', 'धीमे बोलो', 'ನಿಧಾನವಾಗಿ ಮಾತನಾಡು'])) {
        speechRate = 0.8;
        localStorage.setItem('sa_speech_rate', '0.8');
        speak('Speaking more slowly. I am listening.');
        return;
      }
      if (matchKeywords(text, ['speak at normal speed', 'normal speed', 'normal rate', 'सामान्य गति', 'ಸಾಮಾನ್ಯ ವೇಗ'])) {
        speechRate = 1.0;
        localStorage.setItem('sa_speech_rate', '1.0');
        speak('Speaking at normal speed. I am listening.');
        return;
      }
      if (matchKeywords(text, ['speak faster', 'faster', 'तेज बोलो', 'ವೇಗವಾಗಿ ಮಾತನಾಡು'])) {
        speechRate = 1.2;
        localStorage.setItem('sa_speech_rate', '1.2');
        speak('Speaking faster. I am listening.');
        return;
      }

      // 4. Language Settings Commands
      if (matchKeywords(text, ['change language to english', 'switch to english', 'english language'])) {
        setLanguage('English');
        return;
      }
      if (matchKeywords(text, ['change language to hindi', 'switch to hindi', 'hindi language', 'हिन्दी भाषा', 'हिन्दी करो'])) {
        setLanguage('Hindi');
        return;
      }
      if (matchKeywords(text, ['change language to kannada', 'switch to kannada', 'kannada language', 'ಕನ್ನಡ ಭಾಷೆ'])) {
        setLanguage('Kannada');
        return;
      }
      if (matchKeywords(text, ['change language to telugu', 'switch to telugu', 'telugu language', 'తెలుగు భాష'])) {
        setLanguage('Telugu');
        return;
      }

      // 5. Help / Instructions
      if (matchKeywords(text, ['help', 'help me', 'commands', 'what can i say', 'मदद', 'सहायता', 'ಸಹಾಯ', 'ಸಹಾಯ ಮಾಡು', 'సహాయం'])) {
        speak('You can ask me to describe your surroundings, identify objects, read text, read a medicine label, recognise Indian currency, or check for visible hazards. You can also say repeat result, speak more slowly, or change language.');
        return;
      }

      // 6. Camera Controls
      if (matchKeywords(text, ['switch camera', 'flip camera', 'change camera', 'front camera', 'back camera'])) {
        switchCamera();
        return;
      }
      if (matchKeywords(text, ['start camera', 'open camera', 'turn on camera', 'enable camera', 'restart camera', 'camera on'])) {
        speak('Starting camera.');
        CameraManager.getStream(true).then(stream => {
          if (stream) speak('Camera is now active. I am listening.');
        });
        return;
      }

      // 7. Voice Output Toggle
      if (matchKeywords(text, ['turn off voice responses', 'disable voice', 'mute voice'])) {
        voiceResponsesEnabled = false;
        speak('Voice responses turned off.');
        return;
      }
      if (matchKeywords(text, ['turn on voice responses', 'enable voice', 'unmute voice'])) {
        voiceResponsesEnabled = true;
        speak('Voice responses enabled. I am listening.');
        return;
      }

      // 8. Continuous Listening Toggle
      if (matchKeywords(text, ['disable continuous listening', 'stop continuous listening'])) {
        toggleContinuousListening();
        return;
      }
      if (matchKeywords(text, ['enable continuous listening', 'start continuous listening'])) {
        if (!continuousListening) toggleContinuousListening();
        return;
      }

      // 9. OCR Pagination Commands
      if (matchKeywords(text, ['read next section', 'next section'])) {
        if (ocrSections.length > 0 && currentOcrIndex < ocrSections.length - 1) {
          currentOcrIndex++;
          speak('Section ' + (currentOcrIndex + 1) + ' of ' + ocrSections.length + ': ' + ocrSections[currentOcrIndex]);
        } else {
          speak('No further text sections available.');
        }
        return;
      }
      if (matchKeywords(text, ['read all text', 'read everything'])) {
        if (ocrSections.length > 0) {
          speak(ocrSections.join(' '));
        } else {
          speakCurrentResult();
        }
        return;
      }
      if (matchKeywords(text, ['repeat previous section', 'previous section'])) {
        if (ocrSections.length > 0 && currentOcrIndex > 0) {
          currentOcrIndex--;
          speak('Section ' + (currentOcrIndex + 1) + ' of ' + ocrSections.length + ': ' + ocrSections[currentOcrIndex]);
        } else {
          speak('Already at the first section.');
        }
        return;
      }

      // 10. Capture Image Only
      if (matchKeywords(text, ['capture an image', 'capture image', 'take a picture', 'take picture', 'snap photo', 'फोटो खींचो', 'ಚಿತ್ರ ತೆಗೆ'])) {
        const frame = CameraManager.captureFrame();
        if (frame) {
          speak('Image captured. Tell me what to do: describe surroundings, identify objects, read text, or recognise currency.');
        } else {
          speak('Unable to capture camera frame. Camera is initializing, please try again.');
        }
        return;
      }

      // 11. Core Vision Actions (Automated Hands-Free Flow)
      // Describe Surroundings
      if (matchKeywords(text, [
        'describe', 'surround', 'scene', 'look around', 'where am i', 'in front of me', 'what do you see',
        'what is around', 'tell me what you see', 'environment', 'scenery', 'view',
        'आसपास', 'सराउंडिंग्स', 'चारों तरफ', 'दृश्य', 'देखो',
        'ಸುತ್ತಮುತ್ತ', 'ಮುಂದೆ', 'ನೋಡು', 'ದೃಶ್ಯ',
        'పరిసరాలు', 'ముందు', 'చుట్టూ', 'చూడు'
      ])) {
        handleIntent('surroundings');
        return;
      }

      // Identify Objects
      if (matchKeywords(text, [
        'object', 'item', 'identify', 'what is this', 'what is that', 'what are these', 'what are those',
        'things', 'detect', 'वस्तु', 'चीज', 'सामान', 'पहचान', 'यह क्या है',
        'ವಸ್ತು', 'ಗುರುತಿಸು', 'ಇದೇನು',
        'వస్తువు', 'ఇది ఏమిటి'
      ])) {
        handleIntent('objects');
        return;
      }

      // Read Text (OCR)
      if (matchKeywords(text, [
        'read', 'text', 'ocr', 'written', 'words', 'sign', 'board', 'document', 'page', 'book', 'paper', 'letter',
        'what does it say', 'पढ़', 'पढ़', 'लिखा', 'किताब', 'बोर्ड',
        'ಓದು', 'ಪಠ್ಯ', 'ಪುಸ್ತಕ',
        'చదువు', 'టెక్స్ట్', 'పుస్తకం'
      ])) {
        handleIntent('ocr');
        return;
      }

      // Read Medicine Label
      if (matchKeywords(text, [
        'medicine', 'tablet', 'pill', 'capsule', 'syrup', 'dosage', 'expiry', 'prescription', 'drug', 'med', 'meds',
        'दवा', 'दवाई', 'गोली', 'औषध',
        'ಔಷಧಿ', 'ಮಾತ್ರೆ',
        'మందు', 'మాత్ర'
      ])) {
        handleIntent('medicine');
        return;
      }

      // Recognise Currency
      if (matchKeywords(text, [
        'currency', 'money', 'rupee', 'rupees', 'cash', 'note', 'notes', 'coin', 'coins', 'price', 'amount', 'dollar',
        'पैसा', 'पैसे', 'रुपया', 'रुपये', 'सिक्का', 'नोट',
        'ಹಣ', 'ರೂಪಾಯಿ', 'ನಾಣ್ಯ',
        'డబ్బు', 'రూపాయలు', 'కరెన్సీ'
      ])) {
        handleIntent('currency');
        return;
      }

      // Check for Obstacles / Hazards
      if (matchKeywords(text, [
        'hazard', 'obstacle', 'danger', 'block', 'barrier', 'clear', 'safe', 'warning', 'stairs', 'step',
        'खतरा', 'बाधा', 'रुकावट', 'साफ', 'अड़चन',
        'ಅಪಾಯ', 'ಅಡೆತಡೆ',
        'ప్రమాదం', 'అడ్డంకి'
      ])) {
        handleIntent('hazards');
        return;
      }

      // Unrecognized Command: Spoken Clarification
      speak('I could not understand that command. Please say help for available commands.');
    }

    function matchKeywords(text, list) {
      return list.some(k => text.includes(k.toLowerCase()));
    }

    // --- Automated Vision Execution Workflow with Concurrency Lock ---
    let isProcessingIntent = false;

    async function handleIntent(mode) {
      if (isProcessingIntent) {
        console.log('[SightAssist] Intent already processing, ignoring duplicate trigger.');
        return;
      }
      isProcessingIntent = true;
      lastAction = mode;
      errorBanner.style.display = 'none';

      // 1. Confirm verbally and visually: "Capturing an image."
      setState('CAPTURING');
      cueCapture();

      speak('Capturing an image.', async () => {
        try {
          // 2. Automatically capture fresh frame from camera
          let imageBase64 = CameraManager.captureFrame();

          if (!imageBase64) {
            console.log('[SightAssist] Video frame not yet populated, requesting camera stream...');
            const camReady = await CameraManager.getStream();
            if (camReady) {
              await new Promise(r => setTimeout(r, 600));
              imageBase64 = CameraManager.captureFrame();
            }
          }

          if (!imageBase64) {
            setState('ERROR', 'No camera feed available.');
            speak('Camera access is currently unavailable. Please check camera permissions in your browser.');
            isProcessingIntent = false;
            return;
          }

          // 3. Confirm processing state
          setState('PROCESSING');
          const modeTitles = {
            'surroundings': '👁️ Surroundings Description',
            'objects': '🔍 Identified Objects',
            'ocr': '📖 Extracted Text (OCR)',
            'medicine': '💊 Medicine Details',
            'currency': '💵 Currency Recognition',
            'hazards': '⚠️ Obstacle & Hazard Alert'
          };

          resultModeTitle.textContent = modeTitles[mode] || '📢 Analysis Result';

          // 4. Send to Backend Gemini Vision Proxy
          const res = await fetch('/api/describe-scene', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              image: imageBase64,
              language: currentLanguage,
              mode: mode
            })
          });

          const data = await res.json();

          if (data.success && data.spokenSummary) {
            cueSuccess();
            const summary = data.spokenSummary.trim();
            resultTextBox.textContent = summary;
            resultCard.style.display = 'flex';

            if (mode === 'ocr') {
              ocrSections = summary.split('\\n\\n').filter(s => s.trim().length > 0);
              currentOcrIndex = 0;
            } else {
              ocrSections = [];
            }

            // 5. Speak result aloud and smoothly return to listening
            speak(summary, () => {
              isProcessingIntent = false;
              VoiceManager.resumeListening();
            });

          } else {
            cueError();
            const err = data.error || 'Unable to analyze image.';
            showError(err);
            speak('Error: ' + err + '. Say repeat or try again.', () => {
              isProcessingIntent = false;
              VoiceManager.resumeListening();
            });
          }
        } catch (netErr) {
          cueError();
          showError('Network error: ' + netErr.message);
          speak('Network connection failure. Please check your internet connection.', () => {
            isProcessingIntent = false;
            VoiceManager.resumeListening();
          });
        }
      });
    }

    function retryLastAction() {
      handleIntent(lastAction);
    }

    function setLanguage(lang) {
      currentLanguage = lang;
      localStorage.setItem('sa_language', lang);
      languageSelect.value = lang;

      if (window.VoiceManager) {
        VoiceManager.updateLanguage(lang);
      }

      const langConfirmations = {
        'English': 'Language changed to English. I am listening.',
        'Hindi': 'भाषा बदलकर हिन्दी कर दी गई है। मैं सुन रहा हूँ।',
        'Kannada': 'ಭಾಷೆಯನ್ನು ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗಿದೆ. ನಾನು ಕೇಳುತ್ತಿದ್ದೇನೆ.',
        'Telugu': 'భాష తెలుగులోకి మార్చబడింది. నేను వింటున్నాను.'
      };

      speak(langConfirmations[lang] || 'Language updated.');
    }

    function handleLanguageChange(val) {
      setLanguage(val);
    }

    function showError(msg) {
      errorBanner.style.display = 'block';
      errorText.textContent = msg;
    }

    // --- Master Hands-Free Direct Startup ---
    let hasLaunched = false;

    function startSightAssistDirect() {
      if (hasLaunched) return;
      hasLaunched = true;

      // Resume Web Audio Context if suspended
      try {
        if (audioCtx && audioCtx.state === 'suspended') {
          audioCtx.resume();
        }
      } catch (_) {}

      // Unblock speech synthesis
      if ('speechSynthesis' in window) {
        try {
          window.speechSynthesis.cancel();
          window.speechSynthesis.resume();
        } catch (_) {}
      }

      cueSuccess();

      // Initialize speech recognition engine
      VoiceManager.init();

      // Welcome announcement
      const welcomeText = 'Welcome to SightAssist, your personal visual assistant. You can ask me to describe your surroundings, identify objects, read text, read a medicine label, recognise Indian currency, or check for visible hazards. Tell me what you need, and I will help you.';

      speak(welcomeText, () => {
        setState('LISTENING');
        cueListening();
        VoiceManager.startRecognition();
      });

      // Start camera feed concurrently so preview is active immediately
      CameraManager.getStream().catch(err => {
        console.warn('[SightAssist] Initial camera stream startup note:', err.message);
      });
    }

    // Direct startup on page load
    window.addEventListener('DOMContentLoaded', () => {
      startSightAssistDirect();

      // Keyboard shortcuts
      window.addEventListener('keydown', (e) => {
        if (e.code === 'Space') {
          if (currentState === 'SPEAKING') {
            stopSpeech();
            e.preventDefault();
            return;
          }
        }
        if (e.code === 'Escape') {
          stopSpeech();
          e.preventDefault();
        }
      });

      // Browser Autoplay Policy Fallback: Tap anywhere unlocks audio if browser blocked initial autoplay speech
      const onFirstInteract = () => {
        if (audioCtx && audioCtx.state === 'suspended') {
          audioCtx.resume();
        }
        if ('speechSynthesis' in window && !window.speechSynthesis.speaking) {
          try { window.speechSynthesis.resume(); } catch (_) {}
        }
        if (!hasLaunched) {
          startSightAssistDirect();
        } else if (currentState === 'LISTENING' && !VoiceManager.isActive) {
          VoiceManager.startRecognition();
        }
      };
      window.addEventListener('click', onFirstInteract, { once: true });
      window.addEventListener('touchstart', onFirstInteract, { once: true });
    });
  </script>
</body>
</html>`;
}

// HTTP Server
const server = http.createServer((req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 1. Health check endpoint
  if (req.method === 'GET' && (req.url === '/health' || req.url === '/api/health')) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'SightAssist Mobile & Desktop Real-Time AI Service',
      apiKeyConfigured: !!(process.env.GEMINI_API_KEY || GEMINI_API_KEY),
      model: DEFAULT_MODEL,
      fallbackModels: FALLBACK_MODELS,
      localLanIp: LOCAL_LAN_IP,
      serverTime: new Date().toISOString()
    }));
    return;
  }

  // 2. Network info endpoint for mobile testing
  if (req.method === 'GET' && req.url === '/api/network-info') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      localIp: LOCAL_LAN_IP,
      port: PORT,
      mobileUrl: `http://${LOCAL_LAN_IP}:${PORT}/`,
      localhostUrl: `http://localhost:${PORT}/`
    }));
    return;
  }

  // 3. Web App Manifest for PWA Home Screen
  if (req.method === 'GET' && req.url === '/manifest.json') {
    const manifestPath = path.join(__dirname, 'build', 'web', 'manifest.json');
    if (fs.existsSync(manifestPath)) {
      res.writeHead(200, { 'Content-Type': 'application/manifest+json; charset=utf-8' });
      fs.createReadStream(manifestPath).pipe(res);
      return;
    }
  }

  // 4. Icons for PWA
  if (req.method === 'GET' && req.url.startsWith('/icons/')) {
    const iconPath = path.join(__dirname, 'build', 'web', req.url);
    if (fs.existsSync(iconPath) && fs.statSync(iconPath).isFile()) {
      res.writeHead(200, { 'Content-Type': 'image/png' });
      fs.createReadStream(iconPath).pipe(res);
      return;
    }
  }

  // 5. Vision Analysis Endpoints:
  // POST /api/describe-scene, POST /api/vision, POST /api/identify-objects, POST /api/ocr, POST /api/medicine, POST /api/currency, POST /api/hazards
  if (req.method === 'POST' && (
    req.url === '/api/describe-scene' ||
    req.url === '/api/vision' ||
    req.url === '/api/identify-objects' ||
    req.url === '/api/ocr' ||
    req.url === '/api/medicine' ||
    req.url === '/api/currency' ||
    req.url === '/api/hazards'
  )) {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');
        const language = payload.language || 'English';
        const imageBase64 = payload.image || payload.imageBase64;
        let mode = payload.mode || 'surroundings';

        if (req.url === '/api/identify-objects') mode = 'objects';
        if (req.url === '/api/ocr') mode = 'ocr';
        if (req.url === '/api/medicine') mode = 'medicine';
        if (req.url === '/api/currency') mode = 'currency';
        if (req.url === '/api/hazards') mode = 'hazards';

        if (!imageBase64) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: false,
            error: 'No image provided in request payload.'
          }));
          return;
        }

        const prompt = payload.prompt || buildSystemPrompt(mode, language);
        console.log(`[SightAssist Vision] Processing request (mode: ${mode}, language: ${language})...`);

        const visionResult = await callGeminiVision(prompt, imageBase64);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          mode: mode,
          spokenSummary: visionResult.text,
          modelUsed: visionResult.modelUsed,
          safetyAssessment: 'Active',
          source: 'GeminiVisionAPI'
        }));
      } catch (err) {
        console.error('[SightAssist Vision Error]', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: err.message,
          spokenSummary: `SightAssist Error: ${err.message}`
        }));
      }
    });
    return;
  }

  // 6. POST /api/ask-question
  if (req.method === 'POST' && req.url === '/api/ask-question') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');
        const question = payload.question || 'What is in front of me?';
        const language = payload.language || 'English';
        const imageBase64 = payload.image;

        const prompt = `You are SightAssist, visual guide for a visually impaired user. Answer in ${language}. Question: "${question}". Provide 1 to 2 clear, helpful sentences based strictly on the image.`;

        console.log(`[SightAssist Proxy] Answering visual question: "${question}"`);
        const visionResult = await callGeminiVision(prompt, imageBase64);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          answer: visionResult.text,
          modelUsed: visionResult.modelUsed,
          source: 'GeminiVisionAPI'
        }));
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
    return;
  }

  // 7. GET / -> Serve Voice-First Accessible Web UI
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html' || req.url === '/vision')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(getAccessibleWebHtml());
    return;
  }

  // 8. GET /flutter -> Serve Flutter Canvas Web App
  if (req.method === 'GET' && req.url.startsWith('/flutter')) {
    const flutterIndex = path.join(__dirname, 'build', 'web', 'index.html');
    if (fs.existsSync(flutterIndex)) {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      fs.createReadStream(flutterIndex).pipe(res);
      return;
    }
  }

  // 9. Serve static files from build/web for Flutter assets
  if (req.method === 'GET') {
    const webDir = path.join(__dirname, 'build', 'web');
    let safeUrl = req.url.split('?')[0];
    if (safeUrl.startsWith('/flutter/')) {
      safeUrl = safeUrl.replace('/flutter', '');
    }

    let filePath = path.join(webDir, safeUrl);

    if (filePath.startsWith(webDir) && fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      const mimeTypes = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.wasm': 'application/wasm',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        '.ttf': 'font/ttf',
        '.otf': 'font/otf',
        '.woff': 'font/woff',
        '.woff2': 'font/woff2'
      };
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
      fs.createReadStream(filePath).pipe(res);
      return;
    }
  }

  // 404 Fallback
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint or asset not found' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(`[SightAssist Server] Running on Port ${PORT}`);
  console.log(`💻 Laptop Local Access:   http://localhost:${PORT}/`);
  console.log(`📱 Android Phone Wi-Fi:   http://${LOCAL_LAN_IP}:${PORT}/`);
  console.log(`🏥 Health Endpoint:       http://localhost:${PORT}/health`);
  console.log(`📱 Manifest (PWA):        http://localhost:${PORT}/manifest.json`);
  console.log(`====================================================`);
});
