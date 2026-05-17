# DOCUMENT 9 — SECURITY ARCHITECTURE & TRUST MODEL

## 1. Introduction
Security is not an afterthought in Trace — it is embedded into every layer of the platform. From user authentication to data transmission to item handover verification, every interaction is protected by multiple security mechanisms. This document details the complete security architecture of the Trace ecosystem.

---

## 2. Authentication Security

### 2.1 Firebase Authentication (Cloud Identity Provider)
Trace delegates all identity management to Firebase Authentication, a Google-managed Identity-as-a-Service platform:

- **Supported Auth Methods:**
  - Email/Password with email verification
  - Google Sign-In (OAuth 2.0)
  - GitHub OAuth (for developer accounts)

- **Why Firebase Auth instead of custom auth:**
  - Password hashing uses bcrypt/scrypt — handled entirely by Firebase
  - Token rotation and session management are automatic
  - Brute-force protection and suspicious activity detection are built-in
  - Compliant with industry standards (OAuth 2.0, OpenID Connect)

### 2.2 JWT Token Verification
Every API request from the mobile app includes a Firebase ID Token (JWT) in the `Authorization: Bearer <token>` header.

**Server-side verification flow:**
```
1. Extract token from Authorization header
2. Call firebase-admin.auth().verifyIdToken(token)
   → Firebase validates: signature, expiry, issuer, audience
3. Decode user identity: { uid, email, ... }
4. Query Supabase for user's role and ban status
5. If user isBanned === true → Return HTTP 403
6. Attach user context to req.user → Pass to route handler
```

### 2.3 Role-Based Access Control (RBAC)
Three roles are defined in the system:

| Role | Permissions |
|---|---|
| `user` | Create posts, submit claims, chat, view feed |
| `staff` | All user permissions + view flagged posts |
| `admin` | All permissions + ban users, moderate posts, change roles, view audit logs |

The `checkRole(['admin'])` middleware enforces role-based restrictions at the API level. The admin web dashboard additionally checks a super-admin email whitelist for the highest-privilege operations.

---

## 3. Two-Factor Authentication (2FA / MFA)

### 3.1 TOTP Implementation
Trace implements TOTP (Time-based One-Time Password) per RFC 6238:

- **Library**: `otplib` (Node.js implementation of HOTP/TOTP)
- **Algorithm**: HMAC-SHA1
- **Code Length**: 6 digits
- **Time Step**: 30 seconds
- **Window**: ±1 (accepts codes from previous and next time steps)

### 3.2 Setup Flow
```
[User] → GET /api/security/2fa/setup → [Server generates secret]
                                              ↓
                                    [QR code rendered as DataURL]
                                              ↓
[User scans QR with Google Authenticator] → [App generates 6-digit codes]
                                              ↓
[User enters code] → POST /api/security/2fa/activate
                                              ↓
                     [Server verifies code against proposed secret]
                                              ↓
                     [Secret stored in Supabase users.twoFactorSecret]
                     [users.twoFactorEnabled = true]
```

### 3.3 Verification on Login
```
[User logs in] → POST /api/security/2fa/check { userId, token }
                                              ↓
               [Server fetches twoFactorSecret from Supabase]
                                              ↓
               [authenticator.verify({ token, secret, window: 1 })]
                                              ↓
               [Returns { valid: true/false, enforced: true/false }]
```

If 2FA is not enabled for the user, the check returns `{ valid: true, enforced: false }` — allowing bypass for users who haven't opted in.

---

## 4. API Security Layers

### 4.1 Rate Limiting
```javascript
// Global rate limiter: 300 requests per 15 minutes per IP
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 300
});

// Auth rate limiter: 15 requests per hour per IP
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,  // 1 hour
  max: 15
});
```

**Protection against:**
- DDoS attacks (distributed denial of service)
- Brute-force login attempts
- API abuse and scraping

### 4.2 CORS (Cross-Origin Resource Sharing)
The backend only accepts requests from whitelisted origins:
- The Flutter mobile app (same-origin via API client)
- The Next.js web dashboard domain
- The Discord bot server

Requests from unauthorized origins are rejected at the middleware level.

### 4.3 Helmet.js Security Headers
Helmet sets secure HTTP response headers:
- `X-Frame-Options: DENY` — Prevents clickjacking
- `X-Content-Type-Options: nosniff` — Prevents MIME type sniffing
- `X-XSS-Protection: 1; mode=block` — Enables XSS filter
- `Strict-Transport-Security` — Forces HTTPS connections
- `Content-Security-Policy` — Controls resource loading

### 4.4 Input Validation
- All API inputs are validated before processing
- SQL injection is prevented by Supabase's parameterized query builder (no raw SQL strings)
- File uploads are validated for MIME type and size before Cloudinary upload

---

## 5. Data Security

### 5.1 Environment Variable Protection
All sensitive credentials are stored in `.env` files:
- `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`
- `FIREBASE_SERVICE_ACCOUNT` (base64 encoded JSON)
- `GEMINI_API_KEY_1` through `GEMINI_API_KEY_5`
- `DISCORD_BOT_TOKEN`, `DISCORD_CLIENT_ID`
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`

These files are:
- Listed in `.gitignore` — never committed to version control
- Injected via Vercel's encrypted environment variable system for production
- Accessible only server-side — never exposed to client bundles

### 5.2 Database Security (Supabase)
- **Row Level Security (RLS)**: Supabase supports PostgreSQL RLS policies that restrict data access at the row level
- **Service Key vs Anon Key**: The backend uses the `SUPABASE_SERVICE_KEY` (full access) while the client uses the `SUPABASE_ANON_KEY` (restricted access)
- **Connection Encryption**: All connections to Supabase use TLS/SSL encryption

### 5.3 Offline Data Encryption
The `OfflineCacheService` stores pending posts locally using encrypted `SharedPreferences`:
- Data is serialized to JSON and stored with encryption
- Queue data includes post content, image paths, and user IDs
- Data is cleared after successful cloud sync

---

## 6. Item Handover Security (QR Verification)

### 6.1 The Problem
When two strangers meet to exchange a lost item, how do you ensure:
- The person receiving the item is actually the verified claimer?
- The handover is recorded and cannot be disputed later?
- Neither party can falsely claim the exchange didn't happen?

### 6.2 The Solution: QR Handshake Protocol
```
[Finder generates QR] → Contains: { claimId, postId, finderId, timestamp }
         ↓
[Claimer scans QR] → App extracts claim data from QR
         ↓
[App calls POST /api/claims/handshake/verify { claimId }]
         ↓
[Backend validates]:
  1. Claim exists and status === 'approved'
  2. Scanner is the approved claimer
  3. QR generator is the post owner
         ↓
[If valid]:
  - Claim status → 'resolved'
  - Post status → 'resolved'
  - BlockchainService.recordClaim() → Immutable audit entry
  - Finder receives +50 Karma points
  - Both users get success notification
```

### 6.3 Security Properties
- **Mutual verification**: Both parties must be physically present (QR requires camera proximity)
- **Non-repudiation**: Blockchain record cannot be denied or altered
- **Single-use**: Once scanned and verified, the QR/claim cannot be reused
- **Identity binding**: QR is tied to specific claimId → only the approved claimer can complete the handshake

---

## 7. Anti-Abuse Systems

### 7.1 Self-Claim Prevention
The API explicitly rejects claims where `claimer_id === post.userId`:
```javascript
if (post.userId === userId) {
  return res.status(400).json({ error: 'You cannot claim your own item' });
}
```

### 7.2 Duplicate Claim Prevention
Before creating a claim, the system checks for existing claims:
```javascript
const { data: existing } = await supabase
  .from('claims')
  .select('*')
  .eq('post_id', postId)
  .eq('claimer_id', userId)
  .single();

if (existing) return res.status(400).json({ error: 'Already claimed' });
```

### 7.3 Post Status State Machine
Posts follow a strict state machine preventing invalid transitions:
```
Valid transitions:
  open    → [matched, claimed, resolved]
  matched → [claimed, resolved]
  claimed → [resolved]
  resolved → [] (terminal state — no further changes)
```

Any attempt to transition to an invalid state is rejected by the API.

### 7.4 User Banning System
When an admin bans a user:
1. `isBanned` flag is set to `true` in Supabase
2. Every subsequent API call from that user is intercepted by `verifyToken` middleware
3. Middleware checks `isBanned` and returns HTTP 403 before any business logic executes
4. The banned user cannot create posts, submit claims, chat, or access any feature

### 7.5 Content Reporting & Moderation
- Any user can report a post by flagging it
- Flagged posts have `isReported: true` in Supabase
- Admins see flagged posts in the web dashboard
- Admins can approve (make visible) or reject (hide + notify user) the post
- Threshold-based auto-quarantine can be implemented for posts with multiple reports

---

## 8. Network Security

### 8.1 HTTPS Enforcement
- All client-server communication uses HTTPS (TLS 1.3)
- Vercel provides free, auto-renewing SSL certificates
- HSTS headers ensure browsers never downgrade to HTTP

### 8.2 GZIP Compression
All API responses are compressed using the `compression` middleware:
- Reduces payload sizes by 60-70%
- Minimizes bandwidth usage and data costs
- Faster response times for mobile users on cellular networks

### 8.3 Dio Interceptors (Client-Side)
The Flutter `ApiService` uses Dio interceptors that:
- Automatically attach Firebase JWT to every request
- Log request/response cycles for debugging
- Handle token refresh on 401 responses
- Filter noisy background polling from logs

---
*Prepared for Project Trace — Cloud Computing Evaluation*
