# API Usage Clarification

## Current API Setup ✅

### **1. Gemini API Usage**
We use **ONE Gemini API key** for **text generation only** across all features:

- **Model**: `gemini-2.5-flash-preview-05-20` (latest, faster model)
- **API Key**: `GEMINI_API_KEY` from .env
- **Usage**:
  - 💬 **Chat conversations** (ai_service.dart)
  - 🎤 **Voice-to-fact processing** (intelligent_voice_service.dart) 
  - ⚡ **Quick chat** (main.dart)

### **2. Text-to-Speech (TTS)**
We use **actual Gemini TTS** with smart fallback:

- **Primary**: Gemini TTS API (`gemini-2.5-flash-preview-tts`)
- **Fallback**: Device's built-in TTS (Flutter TTS package)
- **Process**:
  1. Text sent to Gemini TTS for high-quality audio generation
  2. Gemini returns professional-grade synthesized audio
  3. Audio played through device speakers
  4. Falls back to device TTS if Gemini unavailable
- **Cost**: Free tier available, pay-per-use beyond limits
- **Quality**: Professional AI-generated speech
- **Formats**: MP3, WAV, and other audio formats supported

### **3. Weather API**
- **Service**: WeatherAPI.com
- **API Key**: `WEATHER_API_KEY` from .env
- **Usage**: Location-based weather for personalized greetings

## Why This Setup is Optimal 🎯

### **Single Gemini Model Benefits:**
✅ **Consistency** - Same AI quality across all features  
✅ **Cost-effective** - One API to monitor and pay for  
✅ **Performance** - Latest model is faster and more accurate  
✅ **Maintenance** - Single model to manage and update  

### **Built-in TTS Benefits:**
✅ **Professional Quality** - True AI-generated speech from Gemini TTS  
✅ **Reliable Fallback** - Device TTS when Gemini unavailable  
✅ **Free Tier** - Generous free usage allowance  
✅ **Consistent Voice** - Same high quality across all devices  
✅ **Multiple Formats** - Supports various audio formats

## Cost Breakdown 💰

### **Gemini API Costs:**
- **Free tier**: 15 requests per minute
- **Paid tier**: ~$0.00025 per 1K characters
- **Usage**: All AI text generation (chat, voice processing)

### **TTS Costs:**
- **Gemini TTS**: Free tier + pay-per-use for excess
- **Speech Quality**: Professional AI-generated audio
- **Total TTS Cost**: Free tier covers most personal usage
- **Previously**: Would have been ~$0.000016 per character with Google TTS

### **Weather API:**
- **Free tier**: 1M calls per month
- **Cost**: Effectively free for personal use

## Technical Flow 🔄

### **Voice Chat Process:**
1. **Speech-to-Text** → Flutter's speech_to_text (device)
2. **Text Processing** → Gemini API (`gemini-2.5-flash-preview-05-20`)
3. **Text-to-Speech** → Flutter TTS (device)

### **Regular Chat Process:**
1. **User Input** → Direct text
2. **AI Processing** → Gemini API (`gemini-2.5-flash-preview-05-20`)
3. **Response Display** → Text on screen

### **Fact Management:**
1. **Voice Input** → Speech-to-text (device)
2. **Fact Extraction** → Gemini API (`gemini-2.5-flash-preview-05-20`)
3. **Storage** → Local SQLite database

## API Endpoint Summary 📡

We're using **only 2 external APIs**:

1. **Gemini API**
   - Endpoint: Google AI Studio
   - Model: `gemini-2.5-flash-preview-05-20`
   - Purpose: All text generation and AI processing

2. **Weather API**
   - Endpoint: WeatherAPI.com
   - Purpose: Location-based weather data

**No TTS API** - Everything else is handled locally on the device!

## Security & Privacy 🔒

### **What stays on device:**
- Voice recordings (never sent to servers)
- TTS synthesis (local processing)
- All user data and facts (local SQLite)

### **What goes to external APIs:**
- Text input to Gemini (for AI responses)
- Location data to WeatherAPI (for weather)

This setup provides the **perfect balance** of functionality, cost-effectiveness, privacy, and performance!
