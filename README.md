<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)
![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

<br />

<h1>TRACE</h1>
<p><strong>Cloud-Based Lost & Found System</strong></p>
<p>A smart, AI-powered lost and found platform built exclusively for Bahria University Karachi Campus.</p>

<a href="https://trace-self.vercel.app">🌐 Live Website</a> •
<a href="https://trace-app-chi.vercel.app">📱 Web App</a> •
<a href="#setup-instructions">🚀 Get Started</a>

<br /><br />

![TRACE Banner](assets/images/trace_banner.png)

</div>

---

## 📌 Overview

**TRACE** solves a real problem on university campuses — lost belongings with no centralized way to recover them. Students waste time posting on social media groups, walking between departments, and still lose their items permanently.

TRACE is a **full-stack, AI-powered** platform that lets students and staff:
- Report lost or found items in seconds
- Match items intelligently using AI image analysis
- Recover belongings securely via QR code handover
- Trust the system through blockchain-logged claim records

> Built as a university final year project at **Bahria University Karachi** — Computer Science Department.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📸 **AI Image Analysis** | Gemini AI identifies and categorizes items from photos |
| 🔍 **Smart Matching** | Intelligent engine matches lost and found posts |
| 📱 **QR Code Handover** | Secure, contactless item exchange with QR verification |
| 🔔 **Push Notifications** | Firebase FCM alerts when a match is found |
| ⛓️ **Blockchain Logging** | SHA-256 chained audit trail for every claim |
| 🗺️ **Campus Maps** | Pin exact floor & room location inside Bahria buildings |
| 🛡️ **Admin Dashboard** | Full platform control — stats, audit logs, moderation |
| 🤖 **Discord Bot** | Report items via `/lost`, `/found`, `/claim` commands |
| 💬 **In-App Chat** | Secure messaging between finder and owner |
| 🏆 **Karma System** | Reward honest users with points and leaderboard ranking |

---

## 🏗️ Architecture

```
Flutter App (Mobile + Web)
        │
        ▼
Firebase Auth ──────────────────────────────────┐
        │                                        │
        ▼                                        ▼
Node.js + Express (Backend API)         Supabase (PostgreSQL)
        │                                        │
        ├── Cloudinary (Image Storage)           │
        ├── Gemini AI (Image Analysis)           │
        ├── FCM (Push Notifications)             │
        └── Blockchain Logger ───────────────────┘
                │
                ▼
        Vercel (Deployment) + GitHub Actions (CI/CD)
```

---

## 🛠️ Tech Stack

### Mobile App
- **Flutter** (Dart) — Cross-platform mobile & web
- **Riverpod** — State management
- **Go Router** — Navigation
- **Firebase Auth** — Authentication
- **Google Sign-In** — OAuth

### Backend
- **Node.js + Express** — REST API server
- **Supabase** (PostgreSQL) — Database
- **Cloudinary** — Image storage & optimization
- **Google Gemini AI** — Image analysis & matching
- **Firebase Admin** — Push notification delivery

### Website
- **Next.js 14** (React) — Admin dashboard & landing
- **Tailwind CSS** — Styling
- **GSAP** — Animations

### Infrastructure
- **Vercel** — Website & web app deployment
- **GitHub Actions** — CI/CD pipeline
- **Firebase Cloud Messaging** — Real-time notifications

---

## 📁 Project Structure

```
Trace/
├── 📱 lib/                    # Flutter mobile app
│   ├── core/                  # Constants, themes, utils
│   ├── presentation/          # Screens & widgets
│   └── services/              # API, auth, blockchain
│
├── 🚀 backend/                # Node.js REST API
│   ├── routes/                # API endpoints
│   ├── middleware/             # Auth, validation
│   ├── services/              # Business logic
│   └── utils/                 # Blockchain, helpers
│
├── 🌐 website/                # Next.js admin dashboard
│   └── src/app/
│       ├── admin/             # Admin pages
│       ├── products/          # Product landing pages
│       └── components/        # Shared components
│
├── 🤖 discord_bot/            # Discord integration
├── 📄 backend/postman_collection.json  # API docs
└── 📝 README.md
```

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.41+
- Node.js 18+
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/UmerCodes19/Trace.git
cd Trace
```

### 2. Flutter App
```bash
flutter pub get
# Create .env file with required keys (see .env.example)
flutter run
```

### 3. Backend
```bash
cd backend
npm install
cp .env.example .env
# Fill in your environment variables
node index.js
# Server runs at http://localhost:5000
```

### 4. Website
```bash
cd website
npm install
# Create .env.local with required keys
npm run dev
# Opens at http://localhost:3000
```

---

## 🔑 Environment Variables

| File | Location | Purpose |
|---|---|---|
| `.env` | Root | Gemini API keys, Supabase, Cloudinary |
| `backend/.env` | Backend | Supabase, Firebase Admin, Cloudinary |
| `website/.env.local` | Website | Supabase public keys, Firebase config |

> ⚠️ Never commit `.env` files. Use `.env.example` as reference.

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/posts` | Get all lost/found posts |
| POST | `/api/posts` | Create new post |
| GET | `/api/posts/:id` | Get single post |
| PUT | `/api/posts/:id` | Update post |
| DELETE | `/api/posts/:id` | Delete post |
| GET | `/api/users/leaderboard` | Karma leaderboard |
| POST | `/api/claims/request` | Submit claim |
| GET | `/api/claim-logs` | Blockchain audit log |
| GET | `/api/claim-logs/verify` | Verify chain integrity |
| GET | `/api/admin/stats` | Platform statistics |

Full collection: [`backend/postman_collection.json`](backend/postman_collection.json)

---

## 👥 Team

| Name | Role |
|---|---|
| **Umer Qureshi** | Lead Developer — Full Stack & Architecture |
| **Maria Khan** | Design Lead — UI/UX, Website, Documentation |
| **Muhammad Umer** | Backend Developer — API & Database |

---

## 📄 License

This project was developed as a **Final Year Project** at Bahria University Karachi, Computer Science Department.

All contributions are managed via GitHub branches and pull requests.

---

<div align="center">
  <p>Made with ❤️ at Bahria University Karachi</p>
  <p><strong>TRACE</strong> — Never lose anything again.</p>
</div>