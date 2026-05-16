# TRACE — Cloud-Based Lost & Found System
> A smart lost and found platform built for Bahria University Karachi Campus.

## About
TRACE is a cloud-based lost and found system that helps students and staff report, find, and recover lost items using AI image analysis, intelligent matching, QR code handover, and blockchain-secured claim logging.
## Features
- 📸 Report lost/found items with AI image analysis
- 🔍 Intelligent item matching engine
- 📱 QR code-based item handover
- 🔔 Real-time push notifications
- ⛓️ Blockchain-secured claim logging
- 🛡️ Admin dashboard with full control
- 🤖 Discord bot integration
- 🗺️ Campus map with location tagging

## Tech Stack
- **Mobile:** Flutter (Dart)
- **Backend:** Node.js + Express
- **Website:** Next.js (React)
- **Database:** Supabase (PostgreSQL)
- **Auth:** Firebase Auth
- **Storage:** Cloudinary
- **AI:** Google Gemini
- **Notifications:** Firebase Cloud Messaging
- **Deployment:** Vercel, GitHub Actions (CI/CD)

## Architecture
```
Flutter App → Firebase Auth → Node.js Backend → Supabase (PostgreSQL)
                                     ↓
                    Cloudinary (Images) + Gemini AI (Analysis)
                                     ↓
                         Vercel (Deployment) + FCM (Notifications)
```
## Setup Instructions

### Backend
1. `cd backend`
2. `npm install`
3. Copy `.env.example` to `.env` and fill in the values
4. `node index.js`
5. Server runs at `http://localhost:3000`
### Flutter App
1. `flutter pub get`
2. Create `.env` file with required API keys
3. `flutter run`

### Website
1. `cd website`
2. `npm install`
3. Create `.env.local` with required keys
4. `npm run dev`
5. Opens at `http://localhost:3000`

## Team
- **Umer Qureshi** — Lead Developer
- **Maria Khan** — Design Lead
-**Muhammad Umer** - backend