# DOCUMENT 6 — CLOUD COMPUTING CONCEPTS & IMPLEMENTATION IN TRACE

## 1. Cloud Computing Paradigm
Trace is a cloud-native application built entirely on managed cloud services. No physical servers are provisioned, maintained, or managed by the development team. Every tier of the application — from authentication to database to AI — runs on cloud infrastructure provided by industry-leading platforms. This document maps each cloud computing concept to its exact implementation within the Trace ecosystem.

---

## 2. Cloud Service Models Used

### 2.1 Software-as-a-Service (SaaS)
Trace consumes the following SaaS offerings:
- **Firebase Authentication**: Fully managed identity service handling user registration, login, OAuth flows (Google, GitHub), and JWT token issuance. The Trace team writes zero authentication infrastructure code — Firebase handles password hashing, token rotation, session management, and OAuth handshakes entirely.
- **Firebase Cloud Messaging (FCM)**: A fully managed push notification delivery service. Trace sends a JSON payload to FCM's REST API, and Firebase handles device routing, queuing, retry logic, and delivery confirmation across Android, iOS, and Web platforms simultaneously.
- **Cloudinary**: A SaaS media management platform. Trace uploads item images via Cloudinary's REST API, and Cloudinary handles storage, CDN distribution, image transformations (resizing, compression, format conversion), and global delivery — all without any storage infrastructure on Trace's side.

### 2.2 Platform-as-a-Service (PaaS)
- **Supabase**: Acts as a fully managed PostgreSQL database platform. Supabase provides the database engine, connection pooling, Row Level Security (RLS), real-time subscriptions, auto-generated REST APIs, and edge functions. Trace connects via the Supabase JavaScript client SDK and performs all CRUD operations through Supabase's API layer — no database server provisioning, patching, or backup management is required.
- **Vercel**: The backend API (Node.js + Express) is deployed as Vercel Serverless Functions. Vercel provides the runtime environment, auto-scaling, SSL termination, domain management, and global edge network distribution. The team simply pushes code to GitHub, and Vercel automatically builds and deploys the functions.

### 2.3 Infrastructure-as-a-Service (IaaS)
- **Docker Containerization**: The backend includes a Dockerfile that packages the Express server into a portable container image. This container can be deployed to any IaaS provider (AWS EC2, Google Compute Engine, Azure VMs) or container orchestration platform (Kubernetes, AWS ECS). Docker abstracts the underlying OS and dependencies, ensuring consistent behavior across development, staging, and production environments.

### 2.4 AI-as-a-Service (AIaaS)
- **Google Gemini API**: Trace uses Gemini's generative AI models for three critical functions:
  1. **Image Analysis**: When a user uploads a photo of a lost/found item, Gemini analyzes the image and returns a structured JSON with title, description, and tags — enabling automatic metadata generation.
  2. **Item Matching**: The Matchmaker Service sends structured prompts to Gemini containing a new post and potential candidates, and Gemini returns match scores with reasoning.
  3. **Voice Transcript Parsing**: Voice reports are transcribed and sent to Gemini, which extracts structured fields (title, type, building, floor, room) from natural language.

---

## 3. Cloud Deployment Architecture

### 3.1 Serverless Functions (Function-as-a-Service)
The entire backend API is deployed as **Vercel Serverless Functions**. Each API route (posts, claims, chats, admin, notifications, auth_security) runs as an independent serverless function that:
- **Scales to zero** when not in use (no idle server costs)
- **Auto-scales horizontally** under load (each request gets its own isolated instance)
- **Cold starts** are minimized through Vercel's edge network pre-warming
- **No server management**: No OS patching, no capacity planning, no load balancer configuration

The `vercel.json` configuration file maps URL paths to serverless function handlers:
```json
{
  "rewrites": [
    { "source": "/api/(.*)", "destination": "/server/index.js" }
  ]
}
```

### 3.2 Edge Network & CDN
Vercel distributes the web dashboard and API responses across its global **Edge Network** (powered by Cloudflare). This means:
- Users in Karachi hit the nearest edge node for static assets
- API responses are served with minimal latency through geographic routing
- SSL/TLS termination happens at the edge, reducing backend compute overhead

Cloudinary provides a separate CDN layer specifically for media assets (item images), ensuring photos load instantly regardless of user location.

### 3.3 Multi-Region Database
Supabase's PostgreSQL instance runs on AWS infrastructure with automated backups, point-in-time recovery, and connection pooling via PgBouncer. The database handles concurrent connections from:
- Flutter mobile app users
- Next.js web dashboard
- Discord bot
- Backend serverless functions

---

## 4. Cloud Security Implementation

### 4.1 Identity & Access Management (IAM)
- **Firebase Auth** manages user identities with industry-standard OAuth 2.0 / OpenID Connect protocols
- **JWT (JSON Web Tokens)** are issued by Firebase and verified server-side using `firebase-admin` SDK
- **Role-Based Access Control (RBAC)**: Users are assigned roles (`user`, `staff`, `admin`) stored in Supabase. The `checkRole()` middleware enforces role-based API access at the cloud function level.

### 4.2 Multi-Factor Authentication (MFA/2FA)
Trace implements **TOTP (Time-based One-Time Password)** using the `otplib` library:
1. Server generates a high-entropy Base32 secret via `authenticator.generateSecret()`
2. Secret is encoded into an `otpauth://` URI and rendered as a QR code
3. User scans QR with Google Authenticator or Authy
4. 6-digit codes rotate every 30 seconds based on HMAC-SHA1
5. Secret is stored encrypted in Supabase's `users` table (`twoFactorSecret` column)

### 4.3 API Security Layers
- **Rate Limiting**: `express-rate-limit` middleware limits API requests to 300 per 15 minutes (global) and 15 per hour (authentication endpoints) — protecting against DDoS and brute-force attacks
- **CORS Policy**: Strict Cross-Origin Resource Sharing headers prevent unauthorized domains from accessing the API
- **Helmet.js**: Sets secure HTTP headers (X-Frame-Options, Content-Security-Policy, X-XSS-Protection) to prevent common web vulnerabilities
- **GZIP Compression**: `compression` middleware reduces API response payload sizes by up to 70%, optimizing bandwidth usage

### 4.4 Data Integrity — Blockchain-Inspired Audit Trail
Every item handover is recorded in an immutable hash-chain stored in Supabase's `claim_logs` table:
- Each log entry contains a `prev_hash` (previous block's hash), `current_hash` (SHA-256 of current data + previous hash), and `data` (claim details)
- The genesis block starts with hash `"GENESIS"`
- Chain integrity is validated by recomputing all hashes sequentially — if any block has been tampered with, the hash mismatch is immediately detected
- This provides a tamper-proof, auditable record of every item recovery on the platform

---

## 5. Cloud Communication & Messaging

### 5.1 Firebase Cloud Messaging (FCM)
Push notifications flow through FCM's cloud infrastructure:
1. Mobile app registers for FCM and receives a unique device token
2. Token is synced to Supabase's `users` table (`fcm_token` column)
3. When an event occurs (match found, claim received, message sent), the backend calls `admin.messaging().send()` with the target token
4. FCM routes the notification through Google's infrastructure to the exact device
5. Notifications are delivered in foreground (in-app banner) and background (system tray) modes

### 5.2 Real-time Data Streams
- Supabase provides real-time WebSocket subscriptions for live data updates
- Chat messages are delivered with near-zero latency through persistent connections
- Notification counts update in real-time across all connected clients

---

## 6. Cloud Storage & Media Pipeline

### Media Upload Flow:
```
[User Camera] → [Flutter App] → [Cloudinary REST API] → [Cloudinary CDN]
                                         ↓
                               [Returns CDN URL]
                                         ↓
                         [URL stored in Supabase PostgreSQL]
                                         ↓
                    [Any client fetches image via CDN URL → Instant global delivery]
```

This architecture separates media storage (Cloudinary) from metadata storage (Supabase), following cloud best practices for:
- **Cost efficiency**: Blob storage is cheaper on dedicated CDNs than in PostgreSQL
- **Performance**: Images are served from edge nodes closest to the user
- **Scalability**: Cloudinary handles unlimited concurrent image requests without affecting database performance

---

## 7. Continuous Integration & Continuous Deployment (CI/CD)

### GitHub Actions Pipeline:
```yaml
on: push to main/master

Job 1: Flutter CI
  → Checkout code → Setup Java 17 → Setup Flutter SDK
  → Run `flutter pub get` → Run `flutter analyze`

Job 2: Backend CD (depends on Job 1 passing)
  → Checkout code → Setup Node.js 18 → Run `npm install`
  → Verify Vercel serverless configuration
```

### Vercel Auto-Deploy:
- Every `git push` to the main branch triggers an automatic deployment on Vercel
- Vercel builds the Next.js web dashboard and deploys serverless functions
- Preview deployments are created for pull requests, enabling review before merge
- Zero-downtime deployments ensure the API is never offline during updates

---

## 8. Offline-First Cloud Sync Pattern
Trace implements the **Offline-First** cloud architecture pattern:
1. When the user has no internet, posts are queued locally using `SharedPreferences` encrypted storage
2. `SyncManager` listens for connectivity changes via `connectivity_plus`
3. When connection is restored, the sync queue is processed:
   - Local images are uploaded to Cloudinary first
   - Post data (with Cloudinary URLs) is sent to the backend API
   - Successfully synced posts are removed from the queue
   - Failed posts remain in queue for retry
4. This ensures zero data loss even in areas with intermittent connectivity

---

## 9. Cloud Cost Optimization Strategies
Trace is designed to operate entirely within **free tiers** of cloud services:

| Service | Free Tier Limit | Trace Usage |
|---|---|---|
| Supabase | 500 MB database, 1 GB storage | Well within limits for university-scale deployment |
| Firebase Auth | 50,000 monthly active users | More than sufficient for campus deployment |
| Firebase FCM | Unlimited notifications | Zero cost for push notifications |
| Vercel | 100 GB bandwidth, 100 hours compute | Serverless functions stay well within limits |
| Cloudinary | 25 GB storage, 25 GB bandwidth | Optimized image compression keeps usage low |
| Google Gemini | 60 requests/minute free tier | Multi-key rotation pool multiplies available quota |
| GitHub Actions | 2,000 minutes/month free | CI/CD pipeline runs are lightweight and fast |

### API Key Rotation for Cost Optimization
Trace implements a multi-key rotation pool for Gemini API calls:
- 5 API keys are loaded from environment variables
- Keys are rotated round-robin on each request
- If a key hits its rate limit (HTTP 429), the system immediately switches to the next key
- If a model fails, the system falls back to cheaper/faster models in a defined hierarchy
- This effectively multiplies the free tier quota by 5x without any additional cost

---

## 10. Summary: Cloud Concepts Map

| # | Cloud Concept | Implementation |
|---|---|---|
| 1 | Database-as-a-Service | Supabase PostgreSQL |
| 2 | Identity-as-a-Service | Firebase Authentication |
| 3 | Serverless Computing (FaaS) | Vercel Serverless Functions |
| 4 | AI-as-a-Service | Google Gemini API |
| 5 | Push Notification Service | Firebase Cloud Messaging |
| 6 | CDN & Media Storage | Cloudinary |
| 7 | Containerization | Docker |
| 8 | CI/CD Pipeline | GitHub Actions + Vercel Auto-Deploy |
| 9 | Edge Network | Vercel Edge Network |
| 10 | In-Memory Caching | NodeCache (server-side response cache) |
| 11 | Rate Limiting | express-rate-limit middleware |
| 12 | Multi-Factor Auth (MFA) | TOTP via otplib |
| 13 | Blockchain Audit Trail | SHA-256 hash-chain in Supabase |
| 14 | Offline-First Sync | SyncManager + local encrypted queue |
| 15 | OAuth 2.0 / OpenID Connect | Google Sign-In federation |
| 16 | RBAC | Role-based middleware (user/staff/admin) |
| 17 | API Gateway | Vercel rewrites + Express routing |
| 18 | Payload Compression | GZIP compression middleware |

---
*Prepared for Project Trace — Cloud Computing Evaluation*
