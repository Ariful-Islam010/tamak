# তামাকমুক্ত জীবন 🌿
### AI-Powered Quit Smoking App for Bangladesh

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![Play Store](https://img.shields.io/badge/Platform-Android-brightgreen?logo=android)](https://play.google.com)

---

## 📱 About

**তামাকমুক্ত জীবন** is a Bengali-language mobile app that helps users quit tobacco using:
- 🤖 AI-generated personalized quit plans (Groq LLaMA)
- 📊 Daily check-ins with mood & craving tracking
- 🏆 Gamification: streaks, badges, virtual grow-tree
- 💰 Money Saver: track savings from quitting
- 🆘 SOS Emergency: instant AI crisis support
- 💬 Peer Support: community chat for accountability

---

## 🗂️ Project Structure

```
Tobacco_Awareness/
├── tobacco_awareness/          ← Flutter App (Android/iOS)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/            ← Data models
│   │   ├── providers/         ← State management (Provider)
│   │   ├── screens/           ← UI screens
│   │   ├── services/          ← API, auth, notifications
│   │   └── theme/             ← App theme & colors
│   ├── android/               ← Android configuration
│   ├── ios/                   ← iOS configuration
│   ├── assets/images/         ← App images & icons
│   ├── docs/                  ← Documentation
│   └── app_publishing_pack/   ← Play Store assets
│
└── tobacco_awareness_backend/ ← Python FastAPI Backend
    ├── main.py                ← API endpoints
    ├── requirements.txt       ← Python dependencies
    └── .env.example           ← Environment template
```

---

## 🚀 Getting Started

### Flutter App
```bash
cd tobacco_awareness
flutter pub get
# Create .env from .env.example
flutter run
```

### Python Backend
```bash
cd tobacco_awareness_backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
# Create .env from .env.example
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🔧 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) |
| State Management | Provider |
| Backend | FastAPI (Python) |
| Database | Supabase (PostgreSQL) |
| AI | Groq API (LLaMA 3.1) |
| Image Storage | Cloudinary |
| Auth | Supabase Auth + Google Sign-In |
| Notifications | flutter_local_notifications |

---

## 📦 Play Store

- **App ID:** `com.tamakmukto.jibon`
- **Target SDK:** Android 14 (API 34)
- **Min SDK:** Android 5.0 (API 21)

---

## 🔒 Environment Variables

Never commit `.env` files. Use `.env.example` as a template.

| Variable | Description |
|----------|-------------|
| `GROQ_API_KEY` | Groq AI API key |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |

---

## 📄 License

Private — All rights reserved © 2026
