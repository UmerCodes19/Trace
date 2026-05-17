# DOCUMENT 10 — API REFERENCE & DATABASE SCHEMA

## 1. Introduction
This document serves as the complete API reference for the Trace backend and the full database schema design stored in Supabase PostgreSQL. Every endpoint, its HTTP method, authentication requirement, request body, and response format is documented.

---

## 2. BASE URL
- **Production**: `https://trace-self.vercel.app/api`
- **Local Development**: `http://localhost:3000/api`

All endpoints are prefixed with `/api/`.

---

## 3. AUTHENTICATION
All protected endpoints require a Firebase ID Token in the Authorization header:
```
Authorization: Bearer <firebase_id_token>
```
The token is verified server-side using `firebase-admin.auth().verifyIdToken()`.

---

## 4. API ENDPOINTS

### 4.1 Posts API (`/api/posts`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/posts` | No | Fetch all posts with filtering and pagination |
| `GET` | `/api/posts/:id` | No | Fetch a single post by ID |
| `POST` | `/api/posts/sync` | Yes | Create a new post |
| `PATCH` | `/api/posts/:id` | Yes | Update post fields |
| `DELETE` | `/api/posts/:id` | Yes | Delete a post |
| `PATCH` | `/api/posts/:id/status` | Yes | Update post status with state machine validation |
| `POST` | `/api/posts/:id/like` | Yes | Toggle like on a post |
| `POST` | `/api/posts/:id/report` | Yes | Report/flag a post |
| `POST` | `/api/posts/:id/view` | No | Increment view counter |

**GET /api/posts Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `type` | string | Filter by "lost" or "found" |
| `status` | string | Filter by "open", "matched", "claimed", "resolved" |
| `building` | string | Filter by building name (partial match) |
| `search` | string | Full-text search across title and description |
| `recency` | string | "Today", "Last 3 Days", "This Week", "This Month" |
| `limit` | integer | Number of results to return (default: 20) |
| `offset` | integer | Pagination offset |

**POST /api/posts/sync Request Body:**
```json
{
  "userId": "firebase_uid_string",
  "type": "lost | found",
  "title": "Black Dell Laptop",
  "description": "15-inch Dell laptop with sticker on lid",
  "imageUrl": "https://cloudinary.com/...",
  "imageUrls": ["url1", "url2", "url3"],
  "buildingName": "Liaquat Block",
  "floor": 2,
  "location_room": "Software Engineering Lab",
  "location_lat": 24.892692,
  "location_lng": 67.088686,
  "aiTags": ["electronics", "laptop", "dell", "black"]
}
```

**Side Effects:**
- On creation, `MatchmakerService.runMatching(newPost)` is triggered asynchronously
- Cache key `posts` is invalidated to ensure fresh data on next fetch

---

### 4.2 Claims API (`/api/claims`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/claims/request` | Yes | Create a new claim request (Phase 2) |
| `GET` | `/api/claims/post/:postId` | Yes | Get all claims for a specific post |
| `GET` | `/api/claims/user` | Yes | Get all claims made by authenticated user |
| `PATCH` | `/api/claims/:id` | Yes | Update claim status (approve/reject) |
| `POST` | `/api/claims/handshake/verify` | Yes | QR handshake verification (Phase 3) |

**POST /api/claims/request Body:**
```json
{
  "postId": "uuid_of_post",
  "proofText": "It's my wallet, has my student ID inside",
  "proofImageUrl": "https://cloudinary.com/proof_image.jpg"
}
```

**Validations:**
- Post must exist and have `status === 'open'`
- Claimer cannot be the post owner (no self-claims)
- No duplicate claim for same user + post combination

**POST /api/claims/handshake/verify Body:**
```json
{
  "claimId": "uuid_of_claim"
}
```

**Side Effects on Handshake:**
- Claim status → `'resolved'`
- Post status → `'resolved'`
- Blockchain audit entry created via `BlockchainService.recordClaim()`
- Finder receives +50 Karma via `supabase.rpc('increment_karma')`
- Both users receive FCM notification

---

### 4.3 Chat API (`/api/chats`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/chats` | Yes | Get all chat conversations for user |
| `GET` | `/api/chats/:chatId/messages` | Yes | Get messages for a specific chat |
| `POST` | `/api/chats/:chatId/messages` | Yes | Send a message |
| `POST` | `/api/chats/create` | Yes | Create a new chat between two users |

---

### 4.4 Users API (`/api/users`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/users/:uid` | No | Get user profile |
| `POST` | `/api/users` | Yes | Create/update user profile |
| `PATCH` | `/api/users/:uid` | Yes | Update user fields |
| `GET` | `/api/users/:uid/posts` | No | Get all posts by user |
| `GET` | `/api/users/leaderboard` | No | Get top users by Karma |

---

### 4.5 Admin API (`/api/admin`)

| Method | Endpoint | Auth | Role | Description |
|---|---|---|---|---|
| `GET` | `/api/admin/stats` | Yes | admin | Get platform statistics |
| `GET` | `/api/admin/flagged-posts` | Yes | admin | Get all reported posts |
| `GET` | `/api/admin/users` | Yes | admin | Get all registered users |
| `POST` | `/api/admin/users/:uid/ban` | Yes | admin | Set user ban status |
| `POST` | `/api/admin/posts/:postId/moderation` | Yes | admin | Approve or reject a flagged post |
| `POST` | `/api/admin/users/:uid/role` | Yes | admin | Change user role |
| `GET` | `/api/admin/audit-logs` | Yes | admin | Get blockchain audit trail |

---

### 4.6 Notifications API (`/api/notifications`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/notifications` | Yes | Get user's notifications |
| `PATCH` | `/api/notifications/:id/read` | Yes | Mark notification as read |
| `POST` | `/api/notifications/register-token` | Yes | Register FCM device token |

---

### 4.7 Security API (`/api/security/2fa`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/security/2fa/setup` | Yes | Generate TOTP secret and QR code |
| `POST` | `/api/security/2fa/activate` | Yes | Verify code and enable 2FA |
| `POST` | `/api/security/2fa/check` | No | Validate a TOTP code during login |

---

### 4.8 Claim Logs API (`/api/claim-logs`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/claim-logs` | Yes | Get all blockchain audit logs |
| `GET` | `/api/claim-logs/validate` | Yes | Validate entire blockchain chain integrity |

---

## 5. DATABASE SCHEMA (Supabase PostgreSQL)

### 5.1 `users` Table
| Column | Type | Description |
|---|---|---|
| `uid` | text (PK) | Firebase UID |
| `email` | text | User email address |
| `name` | text | Display name |
| `photoUrl` | text | Profile photo URL |
| `role` | text | 'user', 'staff', or 'admin' |
| `isBanned` | boolean | Ban status flag |
| `fcm_token` | text | Firebase Cloud Messaging device token |
| `karma` | integer | Karma points (default: 0) |
| `avatar_config` | jsonb | Custom avatar configuration |
| `twoFactorSecret` | text | TOTP secret (encrypted) |
| `twoFactorEnabled` | boolean | Whether 2FA is active |
| `discordId` | text | Linked Discord user ID |
| `linkCode` | text | Temporary Discord linking code |
| `created_at` | timestamptz | Account creation timestamp |

### 5.2 `posts` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Auto-generated UUID |
| `userId` | text (FK) | Reference to users.uid |
| `type` | text | 'lost' or 'found' |
| `title` | text | Item title |
| `description` | text | Detailed description |
| `imageUrl` | text | Primary image/video URL |
| `imageUrls` | text[] | Array of additional image URLs |
| `buildingName` | text | Building where item was lost/found |
| `floor` | integer | Floor number |
| `location_room` | text | Room or specific location |
| `location_name` | text | Human-readable location string |
| `location_lat` | float | GPS latitude |
| `location_lng` | float | GPS longitude |
| `status` | text | 'open', 'matched', 'claimed', 'resolved' |
| `aiTags` | text[] | AI-generated tags for matching |
| `viewCount` | integer | Number of views |
| `likeCount` | integer | Number of likes |
| `reportCount` | integer | Number of reports/flags |
| `isReported` | boolean | Whether post is flagged for review |
| `isCMSVerified` | boolean | CMS verification status |
| `moderatorNote` | text | Admin moderation notes |
| `timestamp` | bigint | Creation timestamp (epoch ms) |

### 5.3 `claims` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Auto-generated UUID |
| `post_id` | uuid (FK) | Reference to posts.id |
| `claimer_id` | text (FK) | Reference to users.uid |
| `proof_text` | text | Claimer's ownership proof |
| `proof_image_url` | text | Optional proof image URL |
| `status` | text | 'pending', 'approved', 'rejected', 'resolved' |
| `created_at` | timestamptz | Claim creation timestamp |

### 5.4 `claim_logs` Table (Blockchain Audit)
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Auto-generated UUID |
| `claim_id` | text | Reference to claim or post ID |
| `prev_hash` | text | Previous block's hash (or 'GENESIS') |
| `current_hash` | text | SHA-256 hash of this block |
| `data` | jsonb | Event data payload |
| `timestamp` | bigint | Block creation timestamp (epoch ms) |

### 5.5 `notifications` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Auto-generated UUID |
| `userId` | text (FK) | Target user's UID |
| `title` | text | Notification title |
| `body` | text | Notification body text |
| `type` | text | 'match', 'claim', 'chat', 'moderation', 'general' |
| `data` | jsonb | Additional payload data |
| `isRead` | boolean | Read status |
| `timestamp` | bigint | Notification timestamp |

### 5.6 `comments` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Auto-generated UUID |
| `postId` | uuid (FK) | Reference to posts.id |
| `userId` | text (FK) | Reference to users.uid |
| `text` | text | Comment content |
| `timestamp` | bigint | Comment timestamp |

### 5.7 `chats` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Chat room UUID |
| `participants` | text[] | Array of user UIDs |
| `lastMessage` | text | Preview of last message |
| `lastTimestamp` | bigint | Timestamp of last message |

### 5.8 `messages` Table
| Column | Type | Description |
|---|---|---|
| `id` | uuid (PK) | Message UUID |
| `chatId` | uuid (FK) | Reference to chats.id |
| `senderId` | text (FK) | Sender's UID |
| `text` | text | Message content |
| `timestamp` | bigint | Message timestamp |

---

## 6. Supabase RPC Functions
| Function | Parameters | Description |
|---|---|---|
| `increment_karma` | `user_id`, `amount` | Atomically increment a user's karma points |
| `increment_view_count` | `post_id` | Atomically increment a post's view counter |

---

## 7. Caching Strategy
The backend implements a cache-aside pattern using NodeCache:

| Cache Key Pattern | TTL | Description |
|---|---|---|
| `posts` | 15 seconds | Main posts feed |
| `comments_*` | 30 seconds | Comments for individual posts |
| `post_*` | 60 seconds | Individual post details |

Cache is automatically invalidated when:
- A new post is created (`invalidate('posts')`)
- A post is updated or deleted
- A claim status changes

---
*Prepared for Project Trace — Cloud Computing Evaluation*
