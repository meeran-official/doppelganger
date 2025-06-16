# API Security Guide - Digital Doppelgänger (Simplified)

## APIs Used ✅

We've simplified the app to use only **essential APIs** for maximum security and performance:

### 1. **Gemini AI API** (Google)
- **Purpose**: AI chat responses, intelligent fact processing, voice-to-fact conversion
- **Environment Variable**: `GEMINI_API_KEY`
- **Security Level**: 🔒 **SECURE** - Properly hidden in .env
- **Usage**: All AI functionality throughout the app

### 2. **WeatherAPI** (WeatherAPI.com)
- **Purpose**: Location-based weather information for personalized greetings
- **Environment Variable**: `WEATHER_API_KEY` 
- **Security Level**: 🔒 **SECURE** - Properly hidden in .env
- **Usage**: Main page weather greeting

### 3. **Firebase Web API** (Optional)
- **Purpose**: Future web deployment features
- **Security Level**: ⚠️ **PUBLIC** - Web API keys are typically public
- **Note**: Security comes from Firebase Rules, not API key secrecy

## Simplified .env Configuration ✅

```bash
# Gemini AI API Key (for chat functionality and intelligent features)
GEMINI_API_KEY=your_gemini_api_key_here

# Weather API Key (for location-based weather integration)
WEATHER_API_KEY=your_weather_api_key_here

# Optional: Other API keys for future features
# OPENAI_API_KEY=your_openai_api_key_here
# FIREBASE_API_KEY=your_firebase_web_api_key_here
```

## Removed Dependencies ✅

We've **removed** these APIs to simplify security:
- ❌ **Google TTS API** - Replaced with built-in Flutter TTS
- ❌ **Separate Google AI API key** - Consolidated into Gemini API
- ❌ **AudioPlayer dependencies** - Simplified to Flutter TTS only

## Security Setup Instructions

### Step 1: Get Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key and replace `your_gemini_api_key_here` in .env

### Step 2: Get Weather API Key
1. Go to [WeatherAPI.com](https://www.weatherapi.com/)
2. Sign up for a free account
3. Go to your dashboard and copy the API key
4. Replace `your_weather_api_key_here` in .env

### Step 3: Secure Your .env File

Add to your `.gitignore`:
```bash
# API Keys
.env
.env.local
.env.production
```

**Never commit .env files to version control!**

## Security Best Practices ✅

### 1. **Environment Variables**
✅ All API keys stored in .env files  
✅ .env files excluded from version control  
✅ No hardcoded API keys in source code  

### 2. **API Key Rotation**
- Change API keys regularly
- Monitor usage in API consoles
- Set up usage alerts

### 3. **Access Control**
- Use least-privilege API permissions
- Monitor API usage for anomalies
- Set up billing alerts

### 4. **Development vs Production**
- Use different API keys for dev/prod
- Consider API key restrictions by domain/IP

## Cost Management 💰

### Gemini API Pricing
- **Free tier**: 15 requests per minute
- **Paid tier**: $0.00025 per 1K characters
- **Recommendation**: Monitor usage in Google Cloud Console

### WeatherAPI Pricing  
- **Free tier**: 1M calls per month
- **Paid tier**: Starting at $4/month for 10M calls
- **Recommendation**: More than sufficient for personal use

## Security Monitoring 📊

### Monthly Security Checklist:
- [ ] Review API usage in Google Cloud Console
- [ ] Check WeatherAPI usage dashboard
- [ ] Rotate API keys if needed
- [ ] Verify .env files are not in version control
- [ ] Monitor app behavior for anomalies

## Troubleshooting 🔧

### Common Issues:

**"Gemini API Key not found"**
- Check .env file exists in project root
- Verify variable name is exactly `GEMINI_API_KEY`
- Restart Flutter app after .env changes

**"Weather API not working"**
- Verify WeatherAPI key is valid
- Check internet connection
- Ensure location permissions are granted

**"TTS not working"**
- This now uses built-in Flutter TTS (no API needed)
- Check device audio settings
- Verify TTS language is supported

## Migration Notes 📝

If upgrading from previous version:
1. Update .env file to new format (remove Google TTS API key)
2. The app now uses built-in TTS instead of Google TTS
3. Consolidated to single `GEMINI_API_KEY` (remove `GOOGLE_AI_API_KEY`)

This simplified setup is **more secure, cost-effective, and easier to maintain**!
