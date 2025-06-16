# API Security Configuration Guide

## 🔐 APIs Currently Used in Digital Doppelgänger

### 1. **Google AI (Gemini) API** ⭐ REQUIRED
- **Purpose**: AI chat responses, fact processing, conversation generation
- **Security Level**: HIGH - Contains sensitive AI capabilities
- **Environment Variable**: `GOOGLE_AI_API_KEY` (or `GEMINI_API_KEY`)
- **Where to get**: [Google AI Studio](https://makersuite.google.com/app/apikey)

### 2. **Google TTS API** ⚡ OPTIONAL
- **Purpose**: Premium text-to-speech synthesis (fallback to device TTS available)
- **Security Level**: MEDIUM - Voice synthesis capabilities
- **Environment Variable**: `GOOGLE_TTS_API_KEY`
- **Where to get**: [Google Cloud Console](https://console.cloud.google.com/apis/library/texttospeech.googleapis.com)

### 3. **Weather API** 🌤️ OPTIONAL
- **Purpose**: Location-based weather updates in greetings
- **Security Level**: LOW - Public weather data
- **Environment Variable**: `WEATHER_API_KEY`
- **Where to get**: [WeatherAPI.com](https://www.weatherapi.com/signup.aspx) (Free tier: 1M calls/month)

### 4. **Firebase API** 📊 CONFIGURED
- **Purpose**: Analytics and potential future cloud features
- **Security Level**: PUBLIC - Web API keys are meant to be public
- **Location**: `web/index.html` (standard for Firebase web apps)

---

## 🛡️ Security Fixes Applied

### ✅ **Fixed Security Issues:**

1. **Removed Hardcoded Weather API Key**
   - **Before**: Weather API key was hardcoded in `main.dart`
   - **After**: Moved to `.env` file with proper error handling

2. **Standardized Environment Variables**
   - **Before**: Inconsistent naming (`GEMINI_API_KEY` vs `GOOGLE_AI_API_KEY`)
   - **After**: Support both names for backward compatibility

3. **Added Proper Error Handling**
   - **Before**: App would crash if API keys missing
   - **After**: Graceful degradation with user-friendly messages

4. **Secured .env File Structure**
   - **Before**: Only Gemini key, no documentation
   - **After**: Complete template with all required keys and comments

---

## 🔧 Setup Instructions

### Step 1: Copy the Template
Your `.env` file should look like this:
```env
# Google AI API Key (for Gemini chat functionality) - REQUIRED
GOOGLE_AI_API_KEY=your_google_ai_api_key_here
GEMINI_API_KEY=your_google_ai_api_key_here

# Google TTS API Key (for premium voice synthesis) - OPTIONAL
GOOGLE_TTS_API_KEY=your_google_tts_api_key_here

# Weather API Key (for location-based weather integration) - OPTIONAL
WEATHER_API_KEY=your_weather_api_key_here
```

### Step 2: Get Your API Keys

#### 🤖 Google AI (Gemini) API - REQUIRED
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Copy the key and replace `your_google_ai_api_key_here`
4. **Cost**: Free tier with generous limits

#### 🎤 Google TTS API - OPTIONAL
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Text-to-Speech API"
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy the key and replace `your_google_tts_api_key_here`
6. **Cost**: Free $300 credit, then pay-per-use

#### 🌤️ Weather API - OPTIONAL
1. Go to [WeatherAPI.com](https://www.weatherapi.com/signup.aspx)
2. Sign up for free account
3. Copy your API key from dashboard
4. Replace `your_weather_api_key_here`
5. **Cost**: Free for 1M requests/month

### Step 3: Verify Setup
```bash
flutter run
```

Check the console for any "API key not found" errors.

---

## 🚨 Security Best Practices

### ✅ **DO:**
- Keep `.env` file in `.gitignore` (already configured)
- Use different API keys for development/production
- Regularly rotate API keys
- Monitor API usage in respective dashboards
- Use Firebase Security Rules for any cloud features

### ❌ **DON'T:**
- Commit API keys to version control
- Share API keys in messages/emails
- Use production keys in development
- Ignore API usage monitoring

---

## 🔒 Production Deployment Security

### For App Store/Play Store:
1. **Environment Variables**: Use platform-specific secure storage
2. **API Key Rotation**: Implement key rotation strategy
3. **Usage Monitoring**: Set up alerts for unusual API usage
4. **Rate Limiting**: Implement client-side rate limiting

### For Web Deployment:
1. **Firebase**: API keys in `index.html` are normal and secure via Firebase Rules
2. **Other APIs**: Consider using a backend proxy for sensitive APIs
3. **Domain Restrictions**: Restrict API keys to your domain only

---

## 📊 API Usage & Costs

| API | Free Tier | Paid Tier | Current Usage |
|-----|-----------|-----------|---------------|
| Google AI (Gemini) | 15 RPM | $0.35/$1K tokens | Chat responses |
| Google TTS | $300 credit | $4-16/1M chars | Voice output |
| Weather API | 1M calls/month | $4/1M calls | Weather greetings |
| Firebase | Generous free | Pay-per-use | Analytics only |

---

## 🔧 Fallback Behavior

The app gracefully degrades when APIs are unavailable:

- **No Google AI API**: ❌ Chat features disabled, shows error message
- **No Google TTS API**: ✅ Falls back to device TTS
- **No Weather API**: ✅ Shows generic greeting without weather
- **No Firebase**: ✅ App works normally, no analytics

---

## 📱 Testing API Security

### Test Cases:
1. **Missing API Keys**: Remove keys from `.env` and verify graceful failure
2. **Invalid API Keys**: Use fake keys and check error handling
3. **Network Issues**: Test offline behavior
4. **Rate Limiting**: Test rapid API calls

### Commands:
```bash
# Test with no .env file
mv .env .env.backup
flutter run

# Test with invalid keys
echo "GOOGLE_AI_API_KEY=invalid" > .env
flutter run

# Restore
mv .env.backup .env
```

The app is now properly secured with all API keys moved to environment variables and proper error handling implemented! 🛡️
